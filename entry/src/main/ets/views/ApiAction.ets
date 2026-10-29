@Component
export struct ApiAction {
  title: string = '';
  note: string = '';
  onRun: () => void = () => {
  };

  build() {
    Row({ space: 10 }) {
      Button(this.title)
        .fontSize(13)
        .height(32)
        .width(250)
        .onClick(() => {
          this.onRun();
        })
      Text(this.note)
        .fontSize(11)
        .fontColor('#777')
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
