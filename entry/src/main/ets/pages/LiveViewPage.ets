import { SectionHeader } from '../common/Kit';

/**
 * 实况窗：本机 SDK 26.0.0 的 ets/api 中不包含 liveViewManager 公开接口
 * （已用 grep 全量检索 SDK 确认）。本页如实说明，并以静态示意图展示胶囊/卡片形态差异。
 */
@Component
export struct LiveViewPage {
  @State supportInfo: string = '本机不支持：SDK 26.0.0 公开 API 中无 liveViewManager 模块';

  aboutToAppear(): void {
    // 实况窗依赖 @kit.LiveViewKit / liveViewManager，仅手机/平板部分场景开放。
    // 本工程编译目标 SDK 26.0.0 中检索不到该模块的 d.ts，因此不做静态引用（否则无法编译），
    // 也无法在运行时真实调用。此处如实标注。
    const canUse: boolean = canIUse('SystemCapability.Notification.LiveView');
    this.supportInfo = `liveViewManager 公开接口：SDK 26.0.0 中不存在（已确认）；` +
      `canIUse(SystemCapability.Notification.LiveView) = ${canUse}`;
  }

  build() {
    Scroll() {
      Column() {
        SectionHeader({ title: '实况窗', note: '状态以本机实测为准，不假装支持' })

        Column() {
          Text(this.supportInfo)
            .fontSize(13)
            .fontColor('#FF6961')
            .width('100%')
          Text('结论：在鸿蒙 PC（2in1, API 26）上无法通过公开 ArkTS 接口创建实况窗（胶囊/卡片）。' +
            '下方为胶囊与卡片形态的静态示意（纯 ArkUI 绘制，非真实况窗）。')
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ top: 8 })
            .width('100%')
        }
        .padding(14)
        .backgroundColor('#2C2C2E')
        .borderRadius(10)
        .width('100%')

        Text('形态示意（非真实况窗）')
          .fontSize(13)
          .fontColor('#8E8E93')
          .margin({ top: 16, bottom: 8 })

        // 胶囊示意
        Row() {
          Text('●')
            .fontColor('#30D158')
            .fontSize(12)
          Text(' 计时中 03:21')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
        .backgroundColor('#1C1C1E')
        .borderRadius(16)

        // 卡片示意
        Row() {
          Column() {
            Text('卡片态示意')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            Text('进度 45% · 预计 2 分钟')
              .fontSize(11)
              .fontColor('#8E8E93')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Progress({ value: 45, total: 100, type: ProgressType.Ring })
            .width(36)
            .height(36)
        }
        .padding(14)
        .backgroundColor('#1C1C1E')
        .borderRadius(12)
        .width('70%')
        .margin({ top: 12 })
      }
      .padding(14)
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
