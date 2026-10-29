import { window } from '@kit.ArkUI';
import { errText } from '../../common/Kit';

/** 从属子窗 */
@Entry
@Component
struct SubWinFollow {
  @State msg: string = '';

  private closeSelf(): void {
    try {
      const w = window.findWindow('win_follow');
      w.destroyWindow().catch((e: Object) => {
        this.msg = `destroyWindow 失败 ${errText(e)}`;
      });
    } catch (e) {
      this.msg = `findWindow 失败 ${errText(e)}`;
    }
  }

  build() {
    Column() {
      Text('从属子窗')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text('createSubWindow 默认从属：跟随主窗前后台切换；「最小化精确跟随隐藏」官方未逐字确认，以真机表现为准。')
        .fontSize(12)
        .fontColor('#D1D1D6')
        .margin({ top: 10 })
      Text('窗口名: win_follow')
        .fontSize(11)
        .fontColor('#8E8E93')
        .margin({ top: 10 })
      if (this.msg.length > 0) {
        Text(this.msg)
          .fontSize(12)
          .fontColor('#FF6961')
          .margin({ top: 8 })
      }
      Button('关闭本窗口 (destroyWindow)')
        .fontSize(13)
        .margin({ top: 18 })
        .onClick(() => {
          this.closeSelf();
        })
    }
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .backgroundColor('#1C1C1E')
  }
}
