import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export class LogEntry {
  seq: number = 0;
  time: string = '';
  text: string = '';
  ok: boolean = true;
}

export function errText(e: BusinessError): string {
  return `code=${e.code} ${e.message}`;
}

function pad2(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}

export function nowTime(): string {
  const d: Date = new Date();
  return pad2(d.getHours()) + ':' + pad2(d.getMinutes()) + ':' + pad2(d.getSeconds());
}

export class WindowStageHolder {
  private static stage: window.WindowStage | null = null;

  static set(s: window.WindowStage): void {
    WindowStageHolder.stage = s;
  }

  static get(): window.WindowStage | null {
    return WindowStageHolder.stage;
  }

  static mainWindow(): window.Window | null {
    const s = WindowStageHolder.stage;
    if (!s) {
      return null;
    }
    try {
      return s.getMainWindowSync();
    } catch (e) {
      return null;
    }
  }
}

export class SubWindowRegistry {
  private static wins: Map<string, window.Window> = new Map<string, window.Window>();

  static set(name: string, w: window.Window): void {
    SubWindowRegistry.wins.set(name, w);
  }

  static get(name: string): window.Window | null {
    const w = SubWindowRegistry.wins.get(name);
    return w === undefined ? null : w;
  }

  static remove(name: string): void {
    SubWindowRegistry.wins.delete(name);
  }
}
