import { LogEntry } from '../model/AppState';

@Component
export struct LogPanel {
  @Link logs: LogEntry[];

  build() {
    Column() {
      Row() {
        Text('运行日志（真实调用结果 / 错误码）')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('清空')
          .fontSize(11)
          .height(24)
          .onClick(() => {
            this.logs = [];
          })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 6, bottom: 4 })

      List({ space: 2 }) {
        ForEach(this.logs, (item: LogEntry) => {
          ListItem() {
            Text(`[${item.time}] ${item.text}`)
              .fontSize(11)
              .fontColor(item.ok ? '#1a7f37' : '#cf222e')
              .width('100%')
          }
        }, (item: LogEntry) => item.seq.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 10, right: 10 })
    }
    .width('100%')
    .backgroundColor('#fafbfc')
    .border({ width: { top: 1 }, color: '#e0e0e0' })
  }
}
