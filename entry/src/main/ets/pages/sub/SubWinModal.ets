import { window } from '@kit.ArkUI';
import { errText } from '../../common/Kit';

/** 模态子窗 */
@Entry
@Component
struct SubWinModal {
  @State msg: string = '';

  private closeSelf(): void {
    try {
      const w = window.findWindow('win_modal');
      w.destroyWindow().catch((e: Object) => {
        this.msg = `destroyWindow 失败 ${errText(e)}`;
      });
    } catch (e) {
      this.msg = `findWindow 失败 ${errText(e)}`;
    }
  }

  build() {
    Column() {
      Text('模态子窗')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text('isModal=true / setSubWindowModal：父窗被锁定，须关闭本子窗才能继续操作主窗。')
        .fontSize(12)
        .fontColor('#D1D1D6')
        .margin({ top: 10 })
      Text('窗口名: win_modal')
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
