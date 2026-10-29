import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogEntry, errText, nowTime } from '../model/AppState';
import { LogPanel } from './LogPanel';
import { ApiAction } from './ApiAction';

@Component
export struct OverlayTab {
  @State logs: LogEntry[] = [];
  @State showPanel: boolean = false;
  @State px: number = 80;
  @State py: number = 120;
  @State opacityVal: number = 0.85;
  private seq: number = 0;
  private dragDX: number = 0;
  private dragDY: number = 0;

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

  sysFloat(): void {
    const ctx = this.hostCtx();
    if (!ctx) {
      return;
    }
    const cfg: window.Configuration = {
      name: 'pcshowcase_float',
      windowType: window.WindowType.TYPE_FLOAT,
      ctx: ctx
    };
    window.createWindow(cfg)
      .then((w: window.Window) => {
        this.addLog(true, '系统悬浮窗创建成功（本机允许）');
        w.destroyWindow().catch((e: BusinessError) => this.addLog(false, '销毁悬浮窗失败: ' + errText(e)));
      })
      .catch((e: BusinessError) =>
        this.addLog(false, '系统悬浮窗被拒绝（三方通常无 ohos.permission.SYSTEM_FLOAT_WINDOW 系统权限）: ' + errText(e)));
  }

  onPanelTouch(ev: TouchEvent): void {
    const t = ev.touches[0];
    if (ev.type === TouchType.Down) {
      this.dragDX = t.windowX - this.px;
      this.dragDY = t.windowY - this.py;
    } else if (ev.type === TouchType.Move) {
      this.px = t.windowX - this.dragDX;
      this.py = t.windowY - this.dragDY;
    }
  }

  build() {
    Stack() {
      Column() {
        Scroll() {
          Column({ space: 10 }) {
            ApiAction({
              title: '显示/隐藏 应用内浮层',
              note: '纯 ArkUI Stack 实现，半透明+圆角+阴影，可拖动，不越出应用窗口，无需任何权限',
              onRun: () => {
                this.showPanel = !this.showPanel;
                this.addLog(true, this.showPanel ? '应用内浮层已显示' : '应用内浮层已隐藏');
              }
            })
            Row({ space: 10 }) {
              Text('浮层不透明度')
                .fontSize(12)
                .width(90)
              Slider({ value: this.opacityVal, min: 0.2, max: 1, step: 0.05 })
                .layoutWeight(1)
                .onChange((v: number) => {
                  this.opacityVal = v;
                })
            }
            .width('100%')
            ApiAction({
              title: '尝试创建系统悬浮窗',
              note: 'window.createWindow(TYPE_FLOAT) 真实调用；三方无 SYSTEM_FLOAT_WINDOW 权限时返回错误码（预期 201）',
              onRun: () => this.sysFloat()
            })
            Text('说明：系统级悬浮窗属于系统权限（system_basic），三方应用申请不到，本页只真实调用并把错误码显示出来，不伪造效果。')
              .fontSize(11)
              .fontColor('#777')
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

      if (this.showPanel) {
        Column() {
          Row() {
            Text('应用内浮层（按住拖动）')
              .fontSize(12)
              .fontColor('#ffffff')
              .layoutWeight(1)
              .onTouch((ev: TouchEvent) => this.onPanelTouch(ev))
            Button('×')
              .fontSize(12)
              .width(32)
              .height(24)
              .onClick(() => {
                this.showPanel = false;
              })
          }
          .width('100%')
          .height(30)
          .backgroundColor('#55000000')
          .padding({ left: 10, right: 6 })
          .borderRadius({ topLeft: 10, topRight: 10 })

          Text('半透明背景 #CCFFFFFF + opacity 可调\n圆角 + 阴影；不依赖系统权限')
            .fontSize(11)
            .fontColor('#333')
            .padding(10)
        }
        .width(250)
        .borderRadius(10)
        .backgroundColor('#CCFFFFFF')
        .opacity(this.opacityVal)
        .shadow({ radius: 16, color: '#66000000' })
        .position({ x: this.px, y: this.py })
      }
    }
    .width('100%')
    .height('100%')
  }
}
