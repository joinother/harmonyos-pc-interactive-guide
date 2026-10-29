import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogEntry, WindowStageHolder, errText, nowTime } from '../model/AppState';
import { LogPanel } from './LogPanel';
import { ApiAction } from './ApiAction';

@Component
export struct WindowSandboxTab {
  @State logs: LogEntry[] = [];
  @State decorHidden: boolean = false;
  @State decorVisibleNow: string = '读取中…';
  private seq: number = 0;

  aboutToAppear(): void {
    this.refreshDecorState();
  }

  addLog(ok: boolean, text: string): void {
    this.seq++;
    const e = new LogEntry();
    e.seq = this.seq;
    e.time = nowTime();
    e.text = text;
    e.ok = ok;
    this.logs.push(e);
  }

  mainWin(): window.Window | null {
    const w = WindowStageHolder.mainWindow();
    if (!w) {
      this.addLog(false, '获取主窗口失败：WindowStage 未就绪');
    }
    return w;
  }

  refreshDecorState(): void {
    const w = WindowStageHolder.mainWindow();
    if (!w) {
      this.decorVisibleNow = 'WindowStage 未就绪';
      return;
    }
    try {
      const v = w.getWindowDecorVisible();
      this.decorVisibleNow = v ? '装饰可见' : '装饰隐藏';
    } catch (e) {
      this.decorVisibleNow = '读取失败: ' + errText(e as BusinessError);
    }
  }

  hideDecor(): void {
    const w = this.mainWin();
    if (!w) {
      return;
    }
    try {
      w.setWindowDecorVisible(false);
      w.setWindowTitleButtonVisible(false, false, false);
      this.decorHidden = true;
      this.addLog(true, '已隐藏窗口装饰与三键（自绘栏已出现）');
      this.refreshDecorState();
    } catch (e) {
      this.addLog(false, '隐藏装饰失败: ' + errText(e as BusinessError));
    }
  }

  showDecor(): void {
    const w = this.mainWin();
    if (!w) {
      return;
    }
    try {
      w.setWindowDecorVisible(true);
      w.setWindowTitleButtonVisible(true, true, true);
      this.decorHidden = false;
      this.addLog(true, '已恢复系统装饰与三键');
      this.refreshDecorState();
    } catch (e) {
      this.addLog(false, '恢复装饰失败: ' + errText(e as BusinessError));
    }
  }

  setHover(hidden: boolean): void {
    const w = this.mainWin();
    if (!w) {
      return;
    }
    w.setTitleAndDockHoverShown(!hidden, !hidden)
      .then(() => this.addLog(true, hidden ? '已禁用标题栏/Dock 悬停显示' : '已恢复标题栏/Dock 悬停显示'))
      .catch((e: BusinessError) => this.addLog(false, 'setTitleAndDockHoverShown 失败: ' + errText(e)));
  }

  doMaximize(mode: window.MaximizePresentation, label: string): void {
    const w = this.mainWin();
    if (!w) {
      return;
    }
    w.maximize(mode)
      .then(() => this.addLog(true, `maximize(${label}) 成功`))
      .catch((e: BusinessError) => this.addLog(false, `maximize(${label}) 失败: ` + errText(e)));
  }

  doRecover(): void {
    const w = this.mainWin();
    if (!w) {
      return;
    }
    w.recover()
      .then(() => this.addLog(true, 'recover() 成功，窗口已还原'))
      .catch((e: BusinessError) => this.addLog(false, 'recover() 失败: ' + errText(e)));
  }

  doMinimize(): void {
    const w = this.mainWin();
    if (!w) {
      return;
    }
    w.minimize()
      .then(() => this.addLog(true, 'minimize() 成功'))
      .catch((e: BusinessError) => this.addLog(false, 'minimize() 失败: ' + errText(e)));
  }

  startMoveMain(): void {
    const w = this.mainWin();
    if (!w) {
      return;
    }
    w.startMoving()
      .then(() => this.addLog(true, 'startMoving() 成功'))
      .catch((e: BusinessError) => this.addLog(false, 'startMoving() 失败: ' + errText(e)));
  }

  quitApp(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (!ctx) {
        this.addLog(false, '获取 UIAbilityContext 失败');
        return;
      }
      ctx.terminateSelf()
        .catch((e: BusinessError) => this.addLog(false, 'terminateSelf 失败: ' + errText(e)));
    } catch (e) {
      this.addLog(false, 'terminateSelf 异常: ' + errText(e as BusinessError));
    }
  }

  build() {
    Column() {
      if (this.decorHidden) {
        Row() {
          Text('PcShowcase 自绘标题栏（按住此处拖动窗口）')
            .fontSize(13)
            .fontColor('#ffffff')
            .layoutWeight(1)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.startMoveMain();
              }
            })
          Button('—')
            .fontSize(12)
            .width(40)
            .height(26)
            .onClick(() => this.doMinimize())
          Button('□')
            .fontSize(12)
            .width(40)
            .height(26)
            .onClick(() => this.doMaximize(window.MaximizePresentation.EXIT_IMMERSIVE, 'EXIT_IMMERSIVE'))
          Button('×')
            .fontSize(12)
            .width(40)
            .height(26)
            .backgroundColor('#c0392b')
            .onClick(() => this.quitApp())
        }
        .width('100%')
        .height(36)
        .backgroundColor('#2f3242')
        .padding({ left: 12, right: 8 })
      }

      Scroll() {
        Column({ space: 10 }) {
          Text(`主窗口装饰状态（getWindowDecorVisible API18）: ${this.decorVisibleNow}`)
            .fontSize(12)
            .fontColor('#333')
          ApiAction({
            title: '隐藏装饰+三键（无边框）',
            note: 'setWindowDecorVisible API11 + setWindowTitleButtonVisible API14，随后顶部出现自绘三键栏',
            onRun: () => this.hideDecor()
          })
          ApiAction({
            title: '恢复装饰与三键',
            note: 'setWindowDecorVisible(true) + setWindowTitleButtonVisible(true,true,true)',
            onRun: () => this.showDecor()
          })
          ApiAction({
            title: '禁用标题/Dock 悬停显示',
            note: 'setTitleAndDockHoverShown(false,false) API14，仅主窗',
            onRun: () => this.setHover(true)
          })
          ApiAction({
            title: '恢复标题/Dock 悬停显示',
            note: 'setTitleAndDockHoverShown(true,true) API14',
            onRun: () => this.setHover(false)
          })
          ApiAction({
            title: '普通最大化',
            note: 'maximize(EXIT_IMMERSIVE) API12',
            onRun: () => this.doMaximize(window.MaximizePresentation.EXIT_IMMERSIVE, 'EXIT_IMMERSIVE')
          })
          ApiAction({
            title: '沉浸最大化',
            note: 'maximize(ENTER_IMMERSIVE) API12',
            onRun: () => this.doMaximize(window.MaximizePresentation.ENTER_IMMERSIVE, 'ENTER_IMMERSIVE')
          })
          ApiAction({
            title: '沉浸最大化+禁悬停',
            note: 'maximize(ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER) API14',
            onRun: () => this.doMaximize(window.MaximizePresentation.ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER, 'ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER')
          })
          ApiAction({
            title: '还原窗口',
            note: 'recover() API12，最大化后恢复',
            onRun: () => this.doRecover()
          })
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
