import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { SectionHeader, LogView, nowStr, errText } from '../common/Kit';

/** 窗口沙盘：真实调用主窗口装饰 / 最大化 / 沉浸 / 自绘三键 等 API */
@Component
export struct WindowSandbox {
  @State logs: string[] = [];
  @State winStatus: string = '未知';
  @State customBar: boolean = false;
  @State isMax: boolean = false;
  private mainWin: window.Window | undefined = undefined;

  private log(msg: string): void {
    const arr = this.logs.slice(0, 40);
    arr.unshift(`[${nowStr()}] ${msg}`);
    this.logs = arr;
  }

  private getWin(): window.Window | undefined {
    if (this.mainWin) {
      return this.mainWin;
    }
    const stage = AppStorage.get('windowStage') as window.WindowStage | undefined;
    if (!stage) {
      this.log('windowStage 未就绪');
      return undefined;
    }
    try {
      this.mainWin = stage.getMainWindowSync();
      return this.mainWin;
    } catch (e) {
      this.log(`getMainWindowSync 失败 ${errText(e)}`);
      return undefined;
    }
  }

  private refreshStatus(): void {
    const w = this.getWin();
    if (!w) {
      return;
    }
    try {
      const s = w.getWindowStatus();
      const names: string[] = ['UNDEFINED', 'FULL_SCREEN', 'MAXIMIZE', 'MINIMIZE', 'FLOATING', 'SPLIT_SCREEN'];
      this.winStatus = names[s] ?? `code=${s}`;
      this.isMax = (s === window.WindowStatusType.MAXIMIZE || s === window.WindowStatusType.FULL_SCREEN);
    } catch (e) {
      this.log(`getWindowStatus 失败 ${errText(e)}`);
    }
  }

  private async run(name: string, fn: (w: window.Window) => Promise<void>): Promise<void> {
    const w = this.getWin();
    if (!w) {
      return;
    }
    try {
      await fn(w);
      this.log(`${name} 成功`);
    } catch (e) {
      this.log(`${name} 失败 ${errText(e)}`);
    }
    this.refreshStatus();
  }

  aboutToAppear(): void {
    const w = this.getWin();
    if (w) {
      try {
        w.on('windowStatusChange', (s: window.WindowStatusType) => {
          const names: string[] = ['UNDEFINED', 'FULL_SCREEN', 'MAXIMIZE', 'MINIMIZE', 'FLOATING', 'SPLIT_SCREEN'];
          this.winStatus = names[s as number] ?? `code=${s}`;
          this.isMax = (s === window.WindowStatusType.MAXIMIZE || s === window.WindowStatusType.FULL_SCREEN);
        });
      } catch (e) {
        // ignore
      }
    }
    this.refreshStatus();
  }

  @Builder
  apiBtn(label: string, api: string, action: () => void) {
    Column() {
      Button(label)
        .fontSize(13)
        .width('100%')
        .onClick(action)
      Text(api)
        .fontSize(10)
        .fontColor('#636366')
        .margin({ top: 2 })
    }
    .width('31%')
    .margin({ bottom: 10 })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Scroll() {
        Column() {
          SectionHeader({ title: '窗口沙盘（主窗口真实 API）', note: `当前窗口状态: ${this.winStatus}` })

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            this.apiBtn('隐藏标题栏', 'setWindowDecorVisible(false) · 11+', () => {
              this.run('隐藏标题栏', async (w: window.Window) => {
                await w.setWindowDecorVisible(false);
              });
            })
            this.apiBtn('恢复标题栏', 'setWindowDecorVisible(true) · 11+', () => {
              this.run('恢复标题栏', async (w: window.Window) => {
                await w.setWindowDecorVisible(true);
              });
            })
            this.apiBtn('隐藏三键', 'setWindowTitleButtonVisible(F,F,F) · 14+', () => {
              this.run('隐藏三键', async (w: window.Window) => {
                await w.setWindowTitleButtonVisible(false, false, false);
              });
            })
            this.apiBtn('恢复三键', 'setWindowTitleButtonVisible(T,T,T) · 14+', () => {
              this.run('恢复三键', async (w: window.Window) => {
                await w.setWindowTitleButtonVisible(true, true, true);
              });
            })
            this.apiBtn('普通最大化', 'maximize(EXIT_IMMERSIVE) 保留三键', () => {
              this.run('普通最大化', async (w: window.Window) => {
                await w.maximize(window.MaximizePresentation.EXIT_IMMERSIVE);
              });
            })
            this.apiBtn('沉浸最大化', 'maximize(ENTER_IMMERSIVE) 悬停唤出', () => {
              this.run('沉浸最大化', async (w: window.Window) => {
                await w.maximize(window.MaximizePresentation.ENTER_IMMERSIVE);
              });
            })
            this.apiBtn('沉浸·禁悬停', 'maximize(ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER) · 14+', () => {
              this.run('沉浸·禁悬停', async (w: window.Window) => {
                await w.maximize(window.MaximizePresentation.ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER);
              });
            })
            this.apiBtn('还原窗口', 'recover() · 11+ (2in1/tablet)', () => {
              this.run('还原窗口', async (w: window.Window) => {
                await w.recover();
              });
            })
            this.apiBtn('禁用悬停唤出', 'setTitleAndDockHoverShown(F,F) · 14+', () => {
              this.run('禁用悬停唤出', async (w: window.Window) => {
                await w.setTitleAndDockHoverShown(false, false);
              });
            })
            this.apiBtn('恢复悬停唤出', 'setTitleAndDockHoverShown(T,T) · 14+', () => {
              this.run('恢复悬停唤出', async (w: window.Window) => {
                await w.setTitleAndDockHoverShown(true, true);
              });
            })
            this.apiBtn('最小化', 'minimize() · 11+', () => {
              this.run('最小化', async (w: window.Window) => {
                await w.minimize();
              });
            })
            this.apiBtn('无边框自绘模式', 'decor F + 三键 F + startMoving', () => {
              this.enterCustomBar();
            })
          }
          .width('100%')

          LogView({ logs: this.logs })
            .margin({ top: 6 })

          Text('提示：自绘模式下拖动顶部横条移动窗口（startMoving），关闭按钮调 terminateSelf()。还原后请点「恢复标题栏+三键」。')
            .fontSize(11)
            .fontColor('#636366')
            .margin({ top: 8 })
        }
        .padding(14)
        .width('100%')
      }
      .width('100%')
      .height('100%')

      if (this.customBar) {
        this.customTitleBar()
      }
    }
    .width('100%')
    .height('100%')
  }

  private enterCustomBar(): void {
    const w = this.getWin();
    if (!w) {
      return;
    }
    try {
      w.setWindowDecorVisible(false);
      w.setWindowTitleButtonVisible(false, false, false);
      w.setWindowTitleMoveEnabled(false);
      this.customBar = true;
      this.log('进入无边框自绘模式（decor=false, 三键=false, 系统标题拖动禁用）');
    } catch (e) {
      this.log(`进入自绘模式失败 ${errText(e)}`);
    }
  }

  private exitCustomBar(): void {
    const w = this.getWin();
    if (!w) {
      return;
    }
    try {
      w.setWindowDecorVisible(true);
      w.setWindowTitleButtonVisible(true, true, true);
      w.setWindowTitleMoveEnabled(true);
      this.customBar = false;
      this.log('退出自绘模式，恢复系统装饰');
    } catch (e) {
      this.log(`恢复装饰失败 ${errText(e)}`);
    }
  }

  @Builder
  customTitleBar() {
    Row() {
      Text('PcShowcase · 自绘标题栏')
        .fontSize(13)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
      Button('—')
        .fontSize(13)
        .width(44)
        .height(28)
        .backgroundColor('#3A3A3C')
        .onClick(() => {
          const w = this.getWin();
          if (w) {
            w.minimize().then(() => {
              this.log('自绘：最小化成功');
            }).catch((e: Object) => {
              this.log(`自绘：最小化失败 ${errText(e)}`);
            });
          }
        })
      Button(this.isMax ? '❐' : '▢')
        .fontSize(13)
        .width(44)
        .height(28)
        .backgroundColor('#3A3A3C')
        .margin({ left: 8 })
        .onClick(() => {
          const w = this.getWin();
          if (!w) {
            return;
          }
          if (this.isMax) {
            w.recover().then(() => {
              this.log('自绘：还原成功');
            }).catch((e: Object) => {
              this.log(`自绘：还原失败 ${errText(e)}`);
            });
          } else {
            w.maximize(window.MaximizePresentation.EXIT_IMMERSIVE).then(() => {
              this.log('自绘：最大化成功');
            }).catch((e: Object) => {
              this.log(`自绘：最大化失败 ${errText(e)}`);
            });
          }
        })
      Button('✕')
        .fontSize(13)
        .width(44)
        .height(28)
        .backgroundColor('#C43C3C')
        .margin({ left: 8 })
        .onClick(() => {
          const ctx = AppStorage.get('uiAbilityContext') as common.UIAbilityContext | undefined;
          if (ctx) {
            ctx.terminateSelf();
          }
        })
      Button('退出自绘')
        .fontSize(11)
        .height(28)
        .backgroundColor('#0A84FF')
        .margin({ left: 8 })
        .onClick(() => {
          this.exitCustomBar();
        })
    }
    .width('100%')
    .height(40)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#CC2C2C2E')
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        const w = this.mainWin;
        if (w) {
          try {
            w.startMoving();
            this.log('startMoving() 已调用（按住拖动）');
          } catch (err) {
            this.log(`startMoving 失败 ${errText(err)}`);
          }
        }
      }
    })
    .gesture(TapGesture({ count: 2 }).onAction(() => {
      const w = this.mainWin;
      if (!w) {
        return;
      }
      if (this.isMax) {
        w.recover().catch((e: Object) => {
          this.log(`双击还原失败 ${errText(e)}`);
        });
      } else {
        w.maximize(window.MaximizePresentation.EXIT_IMMERSIVE).catch((e: Object) => {
          this.log(`双击最大化失败 ${errText(e)}`);
        });
      }
    }))
  }
}
