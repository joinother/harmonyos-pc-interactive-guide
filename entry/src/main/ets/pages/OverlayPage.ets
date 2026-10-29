import { floatView } from '@kit.ArkUI';
import { SectionHeader, LogView, nowStr, errText } from '../common/Kit';

/** 悬浮与透明：应用内浮层（真实 ArkUI）+ 系统级悬浮能力如实标注 */
@Component
export struct OverlayPage {
  @State logs: string[] = [];
  @State showOverlay: boolean = false;
  @State overlayAlpha: number = 0.6;
  @State floatInfo: string = '未检测';

  private log(msg: string): void {
    const arr = this.logs.slice(0, 40);
    arr.unshift(`[${nowStr()}] ${msg}`);
    this.logs = arr;
  }

  private checkFloatView(): void {
    try {
      const en = floatView.isFloatViewEnabled();
      this.floatInfo = `floatView.isFloatViewEnabled() = ${en}（闪控窗，API 26.0.0+）`;
      this.log(this.floatInfo);
    } catch (e) {
      this.floatInfo = `floatView 调用失败 ${errText(e)}`;
      this.log(this.floatInfo);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Scroll() {
        Column() {
          SectionHeader({ title: '悬浮与透明', note: '应用内浮层为真实 ArkUI 实现；系统级悬浮如实标注限制' })

          // 应用内浮层演示
          Column() {
            Text('1. 应用内浮层 + 半透明（真实 ArkUI）')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            Row() {
              Button(this.showOverlay ? '隐藏浮层' : '显示浮层')
                .fontSize(13)
                .onClick(() => {
                  this.showOverlay = !this.showOverlay;
                  this.log(`应用内浮层 ${this.showOverlay ? '显示' : '隐藏'}`);
                })
              Text(`不透明度 ${(this.overlayAlpha * 100).toFixed(0)}%`)
                .fontSize(12)
                .fontColor('#8E8E93')
                .margin({ left: 12 })
            }
            .margin({ top: 10 })
            .width('100%')

            Slider({ value: this.overlayAlpha, min: 0.1, max: 1 })
              .width('60%')
              .margin({ top: 8 })
              .onChange((v: number) => {
                this.overlayAlpha = v;
              })
          }
          .alignItems(HorizontalAlign.Start)
          .padding(14)
          .backgroundColor('#2C2C2E')
          .borderRadius(10)
          .width('100%')

          // 系统级悬浮窗
          Column() {
            Text('2. 系统级悬浮窗（跨应用全局悬浮）')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            Text('window.createWindow(TYPE_FLOAT) 需要 ohos.permission.SYSTEM_FLOAT_WINDOW 系统权限，' +
              '普通三方应用不可用，本演示不强行实现。')
              .fontSize(12)
              .fontColor('#8E8E93')
              .margin({ top: 6 })
            Row() {
              Button('检测闪控窗能力')
                .fontSize(13)
                .onClick(() => {
                  this.checkFloatView();
                })
            }
            .margin({ top: 10 })
            Text(this.floatInfo)
              .fontSize(12)
              .fontColor('#FFCC00')
              .margin({ top: 8 })
          }
          .alignItems(HorizontalAlign.Start)
          .padding(14)
          .backgroundColor('#2C2C2E')
          .borderRadius(10)
          .width('100%')
          .margin({ top: 12 })

          LogView({ logs: this.logs })
            .margin({ top: 12 })
        }
        .padding(14)
        .width('100%')
      }
      .width('100%')
      .height('100%')

      if (this.showOverlay) {
        // 半透明遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .opacity(this.overlayAlpha)
          .onClick(() => {
            this.showOverlay = false;
          })
        // 浮层卡片
        Column() {
          Text('应用内浮层')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('这是 Stack + 条件渲染 + opacity 实现的真实浮层，仅存在于本应用窗口内。')
            .fontSize(12)
            .fontColor('#D1D1D6')
            .margin({ top: 8 })
          Button('关闭浮层')
            .fontSize(13)
            .margin({ top: 14 })
            .onClick(() => {
              this.showOverlay = false;
              this.log('浮层已关闭');
            })
        }
        .padding(20)
        .backgroundColor('#F2FFFFFF')
        .borderRadius(14)
        .width('60%')
        .opacity(0.95)
        .shadow({ radius: 24, color: '#66000000', offsetY: 8 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
