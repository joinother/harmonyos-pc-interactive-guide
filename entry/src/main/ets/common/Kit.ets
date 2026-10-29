import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export function nowStr(): string {
  const d = new Date();
  const p = (n: number): string => (n < 10 ? '0' + n : '' + n);
  return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

export function errText(e: Object): string {
  const err = e as BusinessError;
  if (err && err.code !== undefined) {
    return `code=${err.code} msg=${err.message}`;
  }
  return `${e}`;
}

/** 子窗口集中管理，避免开太多收不回来 */
export class SubWinManager {
  private static wins: Map<string, window.Window> = new Map<string, window.Window>();

  static set(name: string, w: window.Window): void {
    SubWinManager.wins.set(name, w);
  }

  static has(name: string): boolean {
    return SubWinManager.wins.has(name);
  }

  static async close(name: string): Promise<string> {
    const w = SubWinManager.wins.get(name);
    if (!w) {
      return `${name} 不存在`;
    }
    SubWinManager.wins.delete(name);
    try {
      await w.destroyWindow();
      return `${name} 已销毁`;
    } catch (e) {
      return `${name} 销毁失败 ${errText(e)}`;
    }
  }

  static async closeAll(): Promise<string> {
    const names: string[] = [];
    SubWinManager.wins.forEach((v: window.Window, k: string) => {
      names.push(k);
    });
    let ok = 0;
    for (const n of names) {
      const w = SubWinManager.wins.get(n);
      SubWinManager.wins.delete(n);
      if (w) {
        try {
          await w.destroyWindow();
          ok++;
        } catch (e) {
          // ignore
        }
      }
    }
    return `已销毁 ${ok}/${names.length} 个子窗`;
  }
}

@Component
export struct SectionHeader {
  title: string = '';
  note: string = '';

  build() {
    Column() {
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      if (this.note.length > 0) {
        Text(this.note)
          .fontSize(12)
          .fontColor('#8E8E93')
          .margin({ top: 4 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 8 })
  }
}

@Component
export struct LogView {
  @Prop logs: string[];

  build() {
    Column() {
      Text('运行日志')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8E8E93')
        .margin({ bottom: 6 })
      Scroll() {
        Column() {
          if (this.logs.length === 0) {
            Text('（尚无日志，点击上方按钮执行真实 API 调用）')
              .fontSize(12)
              .fontColor('#636366')
          }
          ForEach(this.logs, (line: string) => {
            Text(line)
              .fontSize(12)
              .fontColor(line.indexOf('失败') >= 0 || line.indexOf('code=') >= 0 ? '#FF6961' : '#D1D1D6')
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 2 })
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .scrollBar(BarState.Auto)
      .height(150)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(10)
    .backgroundColor('#1C1C1E')
    .borderRadius(10)
  }
}
