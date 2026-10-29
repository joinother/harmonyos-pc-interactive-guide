import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { SectionHeader, LogView, nowStr, errText } from '../common/Kit';

/** 通知中心：授权 + 五种通知类型真实发布 */
@Component
export struct NotifyCenter {
  @State logs: string[] = [];
  @State authState: string = '未查询';
  private nid: number = 100;

  private log(msg: string): void {
    const arr = this.logs.slice(0, 40);
    arr.unshift(`[${nowStr()}] ${msg}`);
    this.logs = arr;
  }

  private getCtx(): common.UIAbilityContext | undefined {
    return AppStorage.get('uiAbilityContext') as common.UIAbilityContext | undefined;
  }

  private async checkEnabled(): Promise<void> {
    try {
      const en = await notificationManager.isNotificationEnabled();
      this.authState = en ? '已授权' : '未授权';
      this.log(`isNotificationEnabled = ${en}`);
    } catch (e) {
      this.log(`查询通知授权失败 ${errText(e)}`);
    }
  }

  private async requestAuth(): Promise<void> {
    const ctx = this.getCtx();
    if (!ctx) {
      this.log('context 未就绪');
      return;
    }
    try {
      await notificationManager.requestEnableNotification(ctx);
      this.log('requestEnableNotification 已弹窗/已授权');
    } catch (e) {
      this.log(`requestEnableNotification 失败 ${errText(e)}`);
    }
    await this.checkEnabled();
  }

  private async publish(kind: string, req: notificationManager.NotificationRequest): Promise<void> {
    try {
      await notificationManager.publish(req);
      this.log(`发布[${kind}]成功 id=${req.id}`);
    } catch (e) {
      this.log(`发布[${kind}]失败 ${errText(e)}（未授权时 code=1600009）`);
    }
  }

  private pubBasic(): void {
    this.nid++;
    const req: notificationManager.NotificationRequest = {
      id: this.nid,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: { title: '基础通知', text: '这是一条 BASIC_TEXT 通知', additionalText: 'PcShowcase' }
      }
    };
    this.publish('基础', req);
  }

  private pubLong(): void {
    this.nid++;
    const longBody = '长文本通知正文。'.repeat(6) + '展开后可见完整内容，用于验证 LONG_TEXT 在 PC 通知中心的折叠/展开表现。';
    const req: notificationManager.NotificationRequest = {
      id: this.nid,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_LONG_TEXT,
        longText: {
          title: '长文本通知',
          text: '折叠态摘要：这是一条 LONG_TEXT 通知',
          expandedTitle: '长文本通知（展开）',
          longText: longBody,
          briefText: '概要：LONG_TEXT'
        }
      }
    };
    this.publish('长文本', req);
  }

  private pubMulti(): void {
    this.nid++;
    const req: notificationManager.NotificationRequest = {
      id: this.nid,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_MULTILINE,
        multiLine: {
          title: '多行通知',
          text: '共三行内容',
          briefText: '概要：MULTILINE',
          longTitle: '多行通知（展开）',
          lines: ['第一行：窗口沙盘 API 演示完成', '第二行：通知中心 5 种类型', '第三行：子窗口 5 种形态']
        }
      }
    };
    this.publish('多行', req);
  }

  private pubPicture(): void {
    this.nid++;
    const w = 96;
    const h = 96;
    const buf = new ArrayBuffer(w * h * 4);
    const view = new Uint8Array(buf);
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const i = (y * w + x) * 4;
        view[i] = Math.floor(255 * x / w);        // B
        view[i + 1] = Math.floor(255 * y / h);    // G
        view[i + 2] = 200;                        // R
        view[i + 3] = 255;                        // A
      }
    }
    const opts: image.InitializationOptions = {
      size: { width: w, height: h },
      pixelFormat: image.PixelMapFormat.BGRA_8888,
      editable: true
    };
    image.createPixelMap(buf, opts).then((pm: image.PixelMap) => {
      const req: notificationManager.NotificationRequest = {
        id: this.nid,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_PICTURE,
          picture: {
            title: '大图通知',
            text: '附带一张程序生成的渐变图',
            briefText: '概要：PICTURE',
            expandedTitle: '大图通知（展开）',
            picture: pm
          }
        }
      };
      this.publish('大图', req);
    }).catch((e: Object) => {
      this.log(`生成 PixelMap 失败 ${errText(e)}`);
    });
  }

  private pubProgress(): void {
    this.nid++;
    const req: notificationManager.NotificationRequest = {
      id: this.nid,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: { title: '下载任务', text: '进度条通知（downloadTemplate）' }
      },
      template: {
        name: 'downloadTemplate',
        data: { 'progressValue': 45, 'progressMax': 100, 'isProgressIndeterminate': false }
      }
    };
    this.publish('进度条', req);
  }

  private cancelAll(): void {
    try {
      notificationManager.cancelAll();
      this.log('cancelAll 已调用');
    } catch (e) {
      this.log(`cancelAll 失败 ${errText(e)}`);
    }
  }

  @Builder
  nBtn(label: string, api: string, action: () => void) {
    Column() {
      Button(label)
        .fontSize(13)
        .width('100%')
        .onClick(action)
      Text(api)
        .fontSize(10)
        .fontColor('#636366')
        .margin({ top: 2 })
    }
    .width('31%')
    .margin({ bottom: 10 })
  }

  build() {
    Scroll() {
      Column() {
        SectionHeader({ title: '通知中心', note: `通知授权状态: ${this.authState}` })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          this.nBtn('查询授权', 'isNotificationEnabled()', () => {
            this.checkEnabled();
          })
          this.nBtn('请求授权', 'requestEnableNotification(ctx)', () => {
            this.requestAuth();
          })
          this.nBtn('取消全部', 'cancelAll()', () => {
            this.cancelAll();
          })
          this.nBtn('发·基础通知', 'publish BASIC_TEXT', () => {
            this.pubBasic();
          })
          this.nBtn('发·长文本', 'publish LONG_TEXT', () => {
            this.pubLong();
          })
          this.nBtn('发·多行', 'publish MULTILINE', () => {
            this.pubMulti();
          })
          this.nBtn('发·大图', 'publish PICTURE (生成PixelMap)', () => {
            this.pubPicture();
          })
          this.nBtn('发·进度条', 'publish + downloadTemplate', () => {
            this.pubProgress();
          })
        }
        .width('100%')

        LogView({ logs: this.logs })
          .margin({ top: 6 })

        Text('说明：HarmonyOS 通知需用户授权（应用首次弹窗或系统设置中开启）。未授权时 publish 返回 code=1600009。进度条通知使用 downloadTemplate 模板。')
          .fontSize(11)
          .fontColor('#636366')
          .margin({ top: 8 })
      }
      .padding(14)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
