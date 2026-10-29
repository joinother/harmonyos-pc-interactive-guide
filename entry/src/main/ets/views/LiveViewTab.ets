import { BusinessError } from '@kit.BasicServicesKit';
import { LogEntry, errText, nowTime } from '../model/AppState';
import { LogPanel } from './LogPanel';

@Component
export struct LiveViewTab {
  @State logs: LogEntry[] = [];
  @State probeResult: string = '尚未探测';
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

  runProbe(): void {
    const names: string[] = [
      'SystemCapability.LiveView.Core',
      'SystemCapability.LiveView.LiveViewManager',
      'SystemCapability.Notification.LiveView'
    ];
    let out = '';
    for (const n of names) {
      try {
        const r = canIUse(n);
        out += `${n} => ${r}\n`;
        this.addLog(r, `canIUse("${n}") = ${r}`);
      } catch (e) {
        out += `${n} => 异常 ${errText(e as BusinessError)}\n`;
        this.addLog(false, `canIUse("${n}") 异常: ` + errText(e as BusinessError));
      }
    }
    this.probeResult = out;
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 12 }) {
          Text('实况窗（LiveView）能力探测')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
          Text('结论先行：当前 HarmonyOS SDK 26（API26）未向三方应用开放 liveViewManager / @kit.LiveViewKit 公开接口，' +
            'NotificationSystemLiveViewContent 在 SDK 文档中标注为系统应用专用，三方无法直接创建实况窗。' +
            '因此本页不做假实现，只做真实探测并如实展示结果。')
            .fontSize(12)
            .fontColor('#555')
          Button('执行 canIUse 探测')
            .fontSize(13)
            .height(32)
            .width(220)
            .onClick(() => this.runProbe())
          Text(this.probeResult)
            .fontSize(12)
            .fontFamily('monospace')
            .fontColor('#333')
          Text('若以上全部为 false，则本机/本版本不支持三方实况窗（胶囊/卡片）。')
            .fontSize(12)
            .fontColor('#cf222e')
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
