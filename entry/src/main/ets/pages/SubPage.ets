import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { SubWindowRegistry } from '../model/AppState';

@Entry
@Component
struct SubPage {
  @State winName: string = '';

  aboutToAppear(): void {
    try {
      const n = this.getUIContext().getWindowName();
      this.winName = n === undefined ? '' : n;
    } catch (e) {
      this.winName = '';
    }
  }

  curWin(): window.Window | null {
    if (this.winName.length === 0) {
      return null;
    }
    return SubWindowRegistry.get(this.winName);
  }

  onDrag(ev: TouchEvent): void {
    if (ev.type !== TouchType.Down) {
      return;
    }
    const w = this.curWin();
    if (!w) {
      return;
    }
    w.startMoving().catch((e: BusinessError) => {
    });
  }

  closeMe(): void {
    const w = this.curWin();
    if (!w) {
      return;
    }
    const n = this.winName;
    w.destroyWindow()
      .then(() => {
        SubWindowRegistry.remove(n);
      })
      .catch((e: BusinessError) => {
      });
  }

  build() {
    Column() {
      Row() {
        Text(this.winName.length > 0 ? `子窗口: ${this.winName}（按住此处拖动）` : '子窗口')
          .fontSize(13)
          .fontColor('#ffffff')
          .layoutWeight(1)
          .onTouch((ev: TouchEvent) => this.onDrag(ev))
        Button('×')
          .fontSize(13)
          .width(36)
          .height(26)
          .backgroundColor('#c0392b')
          .onClick(() => this.closeMe())
      }
      .width('100%')
      .height(34)
      .backgroundColor('#3a4a6b')
      .padding({ left: 10, right: 6 })

      Column() {
        Text('这是子窗口内容页 pages/SubPage')
          .fontSize(16)
        Text('拖动顶部条移动窗口；× 销毁窗口')
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f7f8fa')
  }
}
