@Entry
@Component
struct Second {
  build() {
    Column() {
      Text('SecondAbility · 同应用新进程')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 40 })
      Text('本页面由 SecondAbility 承载。使用 StartOptions.processMode = NEW_PROCESS_ATTACH_TO_PARENT 拉起，运行在与 EntryAbility 不同的进程中（用 hdc shell ps -ef | grep pcshowcase 可看到两个进程）。')
        .fontSize(14)
        .fontColor('#AAAAAA')
        .margin({ top: 16, left: 32, right: 32 })
      Text('仅 2in1 / 平板生效；手机上 startAbility 返回错误码 801。')
        .fontSize(13)
        .fontColor('#FF9F0A')
        .margin({ top: 12, left: 32, right: 32 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1C1C1E')
  }
}
