import { notificationManager } from '@kit.NotificationKit';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogEntry, errText, nowTime } from '../model/AppState';
import { LogPanel } from './LogPanel';
import { ApiAction } from './ApiAction';

@Component
export struct NotificationTab {
  @State logs: LogEntry[] = [];
  @State authState: string = '未查询';
  @State progress: number = 30;
  private seq: number = 0;

  addLog(ok: boolean, text: string): void {
    this.seq++;
    const e = new LogEntry();
    e.seq = this.seq;
    e.time = nowTime();
    e.text = text;
    e.ok = ok;
    this.logs.push(e);
  }

  hostCtx(): common.UIAbilityContext | null {
    try {
      const c = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (!c) {
        this.addLog(false, 'hostContext 为空');
        return null;
      }
      return c;
    } catch (e) {
      this.addLog(false, '获取 context 失败: ' + errText(e as BusinessError));
      return null;
    }
  }

  checkEnabled(): void {
    notificationManager.isNotificationEnabled()
      .then((v: boolean) => {
        this.authState = v ? '已授权' : '未授权';
        this.addLog(true, `通知授权状态: ${this.authState}`);
      })
      .catch((e: BusinessError) => this.addLog(false, '查询授权状态失败: ' + errText(e)));
  }

  reqAuth(): void {
    const ctx = this.hostCtx();
    if (!ctx) {
      return;
    }
    notificationManager.requestEnableNotification(ctx)
      .then(() => {
        this.addLog(true, 'requestEnableNotification 完成（已授权或用户已操作）');
        this.checkEnabled();
      })
      .catch((e: BusinessError) => {
        this.addLog(false, '授权失败/被拒绝: ' + errText(e));
        this.checkEnabled();
      });
  }

  doPublish(req: notificationManager.NotificationRequest, label: string): void {
    notificationManager.publish(req)
      .then(() => this.addLog(true, `发布[${label}]成功 id=${req.id}`))
      .catch((e: BusinessError) => this.addLog(false, `发布[${label}]失败: ` + errText(e)));
  }

  pubBasic(): void {
    const req: notificationManager.NotificationRequest = {
      id: 101,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: { title: '基础通知', text: '这是一条基础文本通知（BASIC_TEXT）' }
      }
    };
    this.doPublish(req, '基础文本');
  }

  pubLong(): void {
    const req: notificationManager.NotificationRequest = {
      id: 102,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_LONG_TEXT,
        longText: {
          title: '长文本通知',
          text: '折叠时显示的短文本',
          longText: '这是一段很长的通知正文，用于演示 LONG_TEXT 类型在展开状态下的完整显示效果。鸿蒙 PC 通知中心会在展开时展示这段完整内容。',
          briefText: '长文本摘要',
          expandedTitle: '展开后的长文本标题'
        }
      }
    };
    this.doPublish(req, '长文本');
  }

  pubMulti(): void {
    const req: notificationManager.NotificationRequest = {
      id: 103,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_MULTILINE,
        multiLine: {
          title: '多行通知',
          text: '折叠时显示的短文本',
          briefText: '多行摘要',
          longTitle: '展开后的多行标题',
          lines: ['第一行内容：窗口沙盘演示', '第二行内容：通知中心演示', '第三行内容：子窗口演示']
        }
      }
    };
    this.doPublish(req, '多行');
  }

  async pubPicture(): Promise<void> {
    try {
      const w = 128;
      const h = 128;
      const buf = new ArrayBuffer(w * h * 4);
      const arr = new Uint8Array(buf);
      for (let i = 0; i < w * h; i++) {
        arr[i * 4] = 200;
        arr[i * 4 + 1] = Math.floor(255 * (i % w) / w);
        arr[i * 4 + 2] = Math.floor(255 * Math.floor(i / w) / h);
        arr[i * 4 + 3] = 255;
      }
      const opts: image.InitializationOptions = {
        size: { width: w, height: h },
        pixelFormat: image.PixelMapFormat.BGRA_8888
      };
      const pm = await image.createPixelMap(buf, opts);
      const req: notificationManager.NotificationRequest = {
        id: 104,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_PICTURE,
          picture: {
            title: '大图通知',
            text: '图片为离线生成的渐变 PixelMap',
            briefText: '大图摘要',
            expandedTitle: '展开的大图通知',
            picture: pm
          }
        }
      };
      this.doPublish(req, '大图');
    } catch (e) {
      this.addLog(false, '生成 PixelMap 失败: ' + errText(e as BusinessError));
    }
  }

  async pubProgress(): Promise<void> {
    try {
      const support = await notificationManager.isSupportTemplate('downloadTemplate');
      if (!support) {
        this.addLog(false, '本机不支持 downloadTemplate 进度模板');
        return;
      }
      const data: Record<string, Object> = {};
      data['title'] = '文件下载';
      data['fileName'] = 'demo.zip';
      data['progressValue'] = this.progress;
      const tpl: notificationManager.NotificationTemplate = { name: 'downloadTemplate', data: data };
      const req: notificationManager.NotificationRequest = {
        id: 105,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: { title: '下载中', text: `进度 ${this.progress}%` }
        },
        template: tpl
      };
      this.doPublish(req, `进度条 ${this.progress}%`);
      this.progress += 20;
      if (this.progress > 100) {
        this.progress = 30;
      }
    } catch (e) {
      this.addLog(false, '进度通知失败: ' + errText(e as BusinessError));
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 10 }) {
          Text(`通知授权状态: ${this.authState}`)
            .fontSize(12)
            .fontColor('#333')
          ApiAction({
            title: '查询通知授权状态',
            note: 'notificationManager.isNotificationEnabled()',
            onRun: () => this.checkEnabled()
          })
          ApiAction({
            title: '请求通知授权',
            note: 'requestEnableNotification(context)，弹系统授权框；拒绝后失败原因见日志',
            onRun: () => this.reqAuth()
          })
          ApiAction({
            title: '发基础文本通知',
            note: 'ContentType.NOTIFICATION_CONTENT_BASIC_TEXT',
            onRun: () => this.pubBasic()
          })
          ApiAction({
            title: '发长文本通知',
            note: 'ContentType.NOTIFICATION_CONTENT_LONG_TEXT',
            onRun: () => this.pubLong()
          })
          ApiAction({
            title: '发多行通知',
            note: 'ContentType.NOTIFICATION_CONTENT_MULTILINE',
            onRun: () => this.pubMulti()
          })
          ApiAction({
            title: '发大图通知',
            note: 'ContentType.NOTIFICATION_CONTENT_PICTURE，PixelMap 离线渐变生成，无网络依赖',
            onRun: () => {
              this.pubPicture();
            }
          })
          ApiAction({
            title: '发进度条通知（+20%）',
            note: 'downloadTemplate 模板；先发查询 isSupportTemplate，不支持会在日志说明',
            onRun: () => {
              this.pubProgress();
            }
          })
        }
        .alignItems(HorizontalAlign.Start)
        .padding(12)
      }
      .layoutWeight(1)

      LogPanel({ logs: $logs })
        .height(200)
    }
    .width('100%')
    .height('100%')
  }
}
