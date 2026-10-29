import { window } from '@kit.ArkUI';
import { common, Want, StartOptions, contextConstant } from '@kit.AbilityKit';
import { SectionHeader, LogView, nowStr, errText, SubWinManager } from '../common/Kit';

const NAME_INDEP = 'win_independent';
const NAME_FOLLOW = 'win_follow';
const NAME_MODAL = 'win_modal';

@CustomDialog
struct ContrastDialog {
  controller: CustomDialogController;

  build() {
    Column() {
      Text('UI 层模态（CustomDialogController）')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text('弹窗挂在当前页面 UI 树上，遮罩阻断本页交互；不是独立窗口，不会越出应用窗口。与窗口层模态（setSubWindowModal）锁父窗/锁应用的语义不同。')
        .fontSize(12)
        .fontColor('#D1D1D6')
        .margin({ top: 10 })
      Button('关闭')
        .fontSize(13)
        .margin({ top: 14 })
        .onClick(() => {
          this.controller.close();
        })
    }
    .padding(18)
    .backgroundColor('#2C2C2E')
    .borderRadius(12)
    .width(360)
  }
}

/** 子窗口：五种形态真实演示 */
@Component
export struct SubWindowPage {
  @State logs: string[] = [];
  @State apiLevel: string = `本机 API ${getApiLevelSafe()} · 2in1`;
  private uiDialog: CustomDialogController = new CustomDialogController({
    builder: ContrastDialog(), customStyle: true, autoCancel: false
  });

  private log(msg: string): void {
    const arr = this.logs.slice(0, 60);
    arr.unshift(`[${nowStr()}] ${msg}`);
    this.logs = arr;
  }

  private getStage(): window.WindowStage | undefined {
    const stage = AppStorage.get('windowStage') as window.WindowStage | undefined;
    if (!stage) {
      this.log('windowStage 未就绪');
    }
    return stage;
  }

  // ---------- ① 独立子窗（非模态、不跟随，API 26+） ----------
  private async openIndependent(): Promise<void> {
    const stage = this.getStage();
    if (!stage) {
      return;
    }
    if (SubWinManager.has(NAME_INDEP)) {
      this.log('独立子窗已存在，先点「关闭」再开');
      return;
    }
    try {
      const opts: window.SubWindowOptions = {
        title: '独立子窗',
        decorEnabled: true,
        zLevelAboveParentLoosened: true,
        maximizeSupported: true
      };
      const w = await stage.createSubWindowWithOptions(NAME_INDEP, opts);
      SubWinManager.set(NAME_INDEP, w);
      await w.setUIContent('pages/sub/SubWinIndependent');
      await w.resize(520, 340);
      await w.moveWindowToAsync(200, 160);
      await w.showWindow();
      this.log('独立子窗已打开（API 26 zLevelAboveParentLoosened）');
    } catch (e) {
      this.log(`独立子窗创建失败 ${errText(e)}，降级 createSubWindow`);
      try {
        const w2 = await stage.createSubWindow(NAME_INDEP);
        SubWinManager.set(NAME_INDEP, w2);
        await w2.setUIContent('pages/sub/SubWinFollow');
        await w2.resize(520, 340);
        await w2.showWindow();
        this.log('已降级打开普通子窗（跟随主窗，无独立语义）');
      } catch (e2) {
        this.log(`降级创建也失败 ${errText(e2)}`);
      }
    }
  }

  // ---------- ② 从属子窗（跟随主窗） ----------
  private async openFollow(): Promise<void> {
    const stage = this.getStage();
    if (!stage) {
      return;
    }
    if (SubWinManager.has(NAME_FOLLOW)) {
      this.log('从属子窗已存在，先点「关闭」再开');
      return;
    }
    try {
      const w = await stage.createSubWindow(NAME_FOLLOW);
      SubWinManager.set(NAME_FOLLOW, w);
      await w.setUIContent('pages/sub/SubWinFollow');
      await w.resize(480, 320);
      await w.showWindow();
      try {
        await w.setFollowParentWindowLayoutEnabled(true);
        this.log('从属子窗已打开，setFollowParentWindowLayoutEnabled(true) 成功（17+）');
      } catch (e) {
        this.log(`setFollowParentWindowLayoutEnabled 失败 ${errText(e)}（独立子窗会报 1300004）`);
      }
    } catch (e) {
      this.log(`从属子窗创建失败 ${errText(e)}`);
    }
  }

  private minimizeMain(): void {
    const stage = this.getStage();
    if (!stage) {
      return;
    }
    try {
      const main = stage.getMainWindowSync();
      main.minimize().then(() => {
        this.log('主窗已最小化：观察从属子窗是否跟随隐藏（行为以真机为准/未确认）');
      }).catch((e: Object) => {
        this.log(`主窗最小化失败 ${errText(e)}`);
      });
    } catch (e) {
      this.log(`getMainWindowSync 失败 ${errText(e)}`);
    }
  }

  // ---------- ③ 模态 ----------
  private async openModal(modality: number): Promise<void> {
    const stage = this.getStage();
    if (!stage) {
      return;
    }
    if (SubWinManager.has(NAME_MODAL)) {
      this.log('模态子窗已存在，先关闭再开');
      return;
    }
    try {
      const opts: window.SubWindowOptions = { title: '模态子窗', decorEnabled: true, isModal: true };
      const w = await stage.createSubWindowWithOptions(NAME_MODAL, opts);
      SubWinManager.set(NAME_MODAL, w);
      await w.setUIContent('pages/sub/SubWinModal');
      await w.resize(440, 280);
      if (modality >= 0) {
        try {
          await w.setSubWindowModal(true, modality as window.ModalityType);
          this.log(`setSubWindowModal(true, ${modality === window.ModalityType.WINDOW_MODALITY ? 'WINDOW_MODALITY' : 'APPLICATION_MODALITY'}) 成功（14+）`);
        } catch (e) {
          this.log(`setSubWindowModal 失败 ${errText(e)}（isModal 创建参数仍生效）`);
        }
      }
      await w.showWindow();
      this.log('模态子窗已打开，尝试点击主窗验证锁定');
    } catch (e) {
      this.log(`模态子窗创建失败 ${errText(e)}`);
    }
  }

  // ---------- ④ 外部应用 / 新进程 ----------
  private startExternal(bundle: string, ability: string, label: string): void {
    const ctx = AppStorage.get('uiAbilityContext') as common.UIAbilityContext | undefined;
    if (!ctx) {
      this.log('context 未就绪');
      return;
    }
    const want: Want = { bundleName: bundle, abilityName: ability };
    try {
      ctx.startAbility(want).then(() => {
        this.log(`已拉起 ${label}（${bundle}，独立进程）`);
      }).catch((e: Object) => {
        this.log(`拉起 ${label} 失败 ${errText(e)}`);
      });
    } catch (e) {
      this.log(`拉起 ${label} 同步异常 ${errText(e)}`);
    }
  }

  private startSelfNewProcess(): void {
    const ctx = AppStorage.get('uiAbilityContext') as common.UIAbilityContext | undefined;
    if (!ctx) {
      this.log('context 未就绪');
      return;
    }
    const want: Want = { bundleName: 'com.example.pcshowcase', abilityName: 'SecondAbility' };
    // processMode 与 startupVisibility 必须成对设置，否则同步抛 401
    const opts: StartOptions = {
      processMode: contextConstant.ProcessMode.NEW_PROCESS_ATTACH_TO_PARENT,
      startupVisibility: contextConstant.StartupVisibility.STARTUP_SHOW
    };
    try {
      ctx.startAbility(want, opts).then(() => {
        this.log('SecondAbility 新进程启动成功（NEW_PROCESS_ATTACH_TO_PARENT，仅 2in1/平板生效）；hdc ps 可见两个 pcshowcase 进程');
      }).catch((e: Object) => {
        this.log(`同应用新进程失败 ${errText(e)}（手机上返回 801；本机为 2in1 应支持）`);
      });
    } catch (e) {
      this.log(`同应用新进程同步异常 ${errText(e)}`);
    }
  }

  private closeOne(name: string): void {
    SubWinManager.close(name).then((r: string) => {
      this.log(r);
    });
  }

  private closeAll(): void {
    SubWinManager.closeAll().then((r: string) => {
      this.log(r);
    });
  }

  @Builder
  sBtn(label: string, action: () => void) {
    Button(label)
      .fontSize(12)
      .height(32)
      .margin({ right: 8, top: 6 })
      .onClick(action)
  }

  @Builder
  sectionCard(title: string, note: string) {
    SectionHeader({ title: title, note: note })
  }

  build() {
    Scroll() {
      Column() {
        SectionHeader({ title: '子窗口 / 多窗口（真实 API 演示）', note: this.apiLevel })

        // ① 独立子窗
        Column() {
          this.sectionCard('① 独立子窗（非模态、不跟随）',
            'createSubWindowWithOptions({ zLevelAboveParentLoosened: true, decorEnabled: true }) · 仅 API 26.0.0+；带标题栏三键，可拖出主窗，不随主窗前后台切换')
          Flex({ wrap: FlexWrap.Wrap }) {
            this.sBtn('打开独立子窗', () => {
              this.openIndependent();
            })
            this.sBtn('关闭', () => {
              this.closeOne(NAME_INDEP);
            })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor('#2C2C2E')
        .borderRadius(10)
        .width('100%')

        // ② 从属子窗
        Column() {
          this.sectionCard('② 从属子窗（跟随主窗）',
            'createSubWindow() 默认从属 · 9+；setFollowParentWindowLayoutEnabled · 17+。「主窗最小化→子窗精确跟随隐藏」官方未逐字确认，以真机为准')
          Flex({ wrap: FlexWrap.Wrap }) {
            this.sBtn('打开从属子窗', () => {
              this.openFollow();
            })
            this.sBtn('最小化主窗（观察跟随）', () => {
              this.minimizeMain();
            })
            this.sBtn('关闭', () => {
              this.closeOne(NAME_FOLLOW);
            })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor('#2C2C2E')
        .borderRadius(10)
        .width('100%')
        .margin({ top: 10 })

        // ③ 模态
        Column() {
          this.sectionCard('③ 模态对话框',
            '窗口层：isModal 创建参数 / setSubWindowModal(true) 12+，ModalityType 14+；UI 层 CustomDialogController 作对照')
          Flex({ wrap: FlexWrap.Wrap }) {
            this.sBtn('窗口模态·锁父窗', () => {
              this.openModal(window.ModalityType.WINDOW_MODALITY);
            })
            this.sBtn('窗口模态·锁全应用', () => {
              this.openModal(window.ModalityType.APPLICATION_MODALITY);
            })
            this.sBtn('UI 层模态（对照）', () => {
              this.uiDialog.open();
            })
            this.sBtn('关闭模态子窗', () => {
              this.closeOne(NAME_MODAL);
            })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor('#2C2C2E')
        .borderRadius(10)
        .width('100%')
        .margin({ top: 10 })

        // ④ 外部应用/新进程
        Column() {
          this.sectionCard('④ 外部应用 / 新进程',
            'startAbility 跨应用必然跨进程；StartOptions.processMode 同应用强制新进程，仅 2in1/平板生效，手机返回 801')
          Flex({ wrap: FlexWrap.Wrap }) {
            this.sBtn('打开系统设置', () => {
              this.startExternal('com.huawei.hmos.settings', 'com.huawei.hmos.settings.MainAbility', '系统设置');
            })
            this.sBtn('打开文件管理器', () => {
              this.startExternal('com.huawei.hmos.filemanager', 'com.huawei.hmos.filemanager.MainAbility', '文件管理器');
            })
            this.sBtn('同应用新进程', () => {
              this.startSelfNewProcess();
            })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor('#2C2C2E')
        .borderRadius(10)
        .width('100%')
        .margin({ top: 10 })

        // ⑤ 管理
        Flex({ wrap: FlexWrap.Wrap }) {
          this.sBtn('关闭全部子窗', () => {
            this.closeAll();
          })
        }

        LogView({ logs: this.logs })
          .margin({ top: 6 })
      }
      .padding(14)
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}

function getApiLevelSafe(): string {
  // canIUse 不直接给 API 版本号；本工程 compatibleSdkVersion=26，设备实测 API 26
  return '26';
}
