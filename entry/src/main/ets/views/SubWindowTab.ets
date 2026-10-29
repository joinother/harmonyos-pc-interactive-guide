import { window } from '@kit.ArkUI';
import { common, Want, contextConstant, StartOptions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogEntry, WindowStageHolder, SubWindowRegistry, errText, nowTime } from '../model/AppState';
import { LogPanel } from './LogPanel';
import { ApiAction } from './ApiAction';

@Component
export struct SubWindowTab {
  @State logs: LogEntry[] = [];
  @State subStatus: string = '未创建';
  private seq: number = 0;
  private sub: window.Window | null = null;

  addLog(ok: boolean, text: string): void {
    this.seq++;
    const e = new LogEntry();
    e.seq = this.seq;
    e.time = nowTime();
    e.text = text;
    e.ok = ok;
    this.logs.push(e);
  }

  hostCtx(): common.UIAbilityContext | null {
    try {
      const c = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (!c) {
        this.addLog(false, 'hostContext 为空');
        return null;
      }
      return c;
    } catch (e) {
      this.addLog(false, '获取 context 失败: ' + errText(e as BusinessError));
      return null;
    }
  }

  async setupAndShow(name: string, w: window.Window, label: string): Promise<void> {
    SubWindowRegistry.set(name, w);
    await w.setUIContent('pages/SubPage');
    await w.resize(560, 380);
    await w.moveWindowTo(220, 180);
    await w.showWindow();
    this.sub = w;
    this.subStatus = `${name} 已显示`;
    this.addLog(true, `${label} 已创建并显示`);
  }

  async openBasic(): Promise<void> {
    const stage = WindowStageHolder.get();
    if (!stage) {
      this.addLog(false, 'WindowStage 未就绪');
      return;
    }
    try {
      const w = await stage.createSubWindow('sub_basic');
      await this.setupAndShow('sub_basic', w, '普通子窗（createSubWindow API9）');
    } catch (e) {
      this.addLog(false, '创建普通子窗失败: ' + errText(e as BusinessError));
    }
  }

  async openWithOptions(): Promise<void> {
    const stage = WindowStageHolder.get();
    if (!stage) {
      this.addLog(false, 'WindowStage 未就绪');
      return;
    }
    try {
      const opts: window.SubWindowOptions = { title: '选项子窗', decorEnabled: true };
      const w = await stage.createSubWindowWithOptions('sub_opts', opts);
      await this.setupAndShow('sub_opts', w, '带选项子窗（createSubWindowWithOptions API12）');
    } catch (e) {
      this.addLog(false, '创建带选项子窗失败: ' + errText(e as BusinessError));
    }
  }

  async openIndependent(): Promise<void> {
    const stage = WindowStageHolder.get();
    if (!stage) {
      this.addLog(false, 'WindowStage 未就绪');
      return;
    }
    try {
      const opts: window.SubWindowOptions = {
        title: '独立子窗',
        decorEnabled: true,
        zLevelAboveParentLoosened: true
      };
      const w = await stage.createSubWindowWithOptions('sub_indep', opts);
      await this.setupAndShow('sub_indep', w, '独立子窗（zLevelAboveParentLoosened API26）');
    } catch (e) {
      this.addLog(false, '创建独立子窗失败: ' + errText(e as BusinessError));
    }
  }

  async openChildFollow(): Promise<void> {
    const stage = WindowStageHolder.get();
    if (!stage) {
      this.addLog(false, 'WindowStage 未就绪');
      return;
    }
    try {
      const w = await stage.createSubWindow('sub_child');
      const main = WindowStageHolder.mainWindow();
      if (main) {
        const mainId = main.getWindowProperties().id;
        await w.setParentWindow(mainId);
        this.addLog(true, `setParentWindow(${mainId}) 成功 (API19)`);
      }
      await w.setFollowParentWindowLayoutEnabled(true);
      this.addLog(true, 'setFollowParentWindowLayoutEnabled(true) 成功 (API17)');
      await this.setupAndShow('sub_child', w, '从属子窗（跟随父窗布局）');
    } catch (e) {
      this.addLog(false, '创建从属子窗失败: ' + errText(e as BusinessError));
    }
  }

  async openModalApp(): Promise<void> {
    const stage = WindowStageHolder.get();
    if (!stage) {
      this.addLog(false, 'WindowStage 未就绪');
      return;
    }
    try {
      const opts: window.SubWindowOptions = { title: '模态子窗', decorEnabled: true };
      const w = await stage.createSubWindowWithOptions('sub_modal', opts);
      await w.setSubWindowModal(true, window.ModalityType.APPLICATION_MODALITY);
      this.addLog(true, 'setSubWindowModal(true, APPLICATION_MODALITY) 成功 (API14)');
      await this.setupAndShow('sub_modal', w, '应用模态子窗');
    } catch (e) {
      this.addLog(false, '创建模态子窗失败: ' + errText(e as BusinessError));
    }
  }

  async closeSub(): Promise<void> {
    const w = this.sub;
    if (!w) {
      this.addLog(false, '当前无子窗句柄（可能已在子窗内点 × 销毁）');
      return;
    }
    try {
      await w.destroyWindow();
      this.sub = null;
      this.subStatus = '已销毁';
      this.addLog(true, '子窗已销毁 destroyWindow()');
    } catch (e) {
      this.addLog(false, '销毁子窗失败: ' + errText(e as BusinessError));
    }
  }

  startNewProcess(): void {
    const ctx = this.hostCtx();
    if (!ctx) {
      return;
    }
    const want: Want = {
      bundleName: 'com.example.pcshowcase',
      abilityName: 'EntryAbility'
    };
    const opts: StartOptions = {
      processMode: contextConstant.ProcessMode.NEW_PROCESS_ATTACH_TO_PARENT,
      startupVisibility: contextConstant.StartupVisibility.STARTUP_SHOW
    };
    ctx.startAbility(want, opts)
      .then(() => this.addLog(true, 'startAbility(processMode=NEW_PROCESS_ATTACH_TO_PARENT) 调用成功（2in1/平板生效，手机报 801）'))
      .catch((e: BusinessError) => this.addLog(false, 'startAbility 失败: ' + errText(e)));
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 10 }) {
          Text(`子窗状态: ${this.subStatus}　（本机 API26 / 2in1）`)
            .fontSize(12)
            .fontColor('#333')
          ApiAction({
            title: '普通子窗',
            note: 'createSubWindow API9，本机支持',
            onRun: () => {
              this.openBasic();
            }
          })
          ApiAction({
            title: '带选项子窗',
            note: 'createSubWindowWithOptions API12（title/decorEnabled），本机支持',
            onRun: () => {
              this.openWithOptions();
            }
          })
          ApiAction({
            title: '独立子窗',
            note: 'SubWindowOptions.zLevelAboveParentLoosened API26 新增，本机 API26 可验证；低版本会降级报错',
            onRun: () => {
              this.openIndependent();
            }
          })
          ApiAction({
            title: '从属子窗（跟随父窗）',
            note: 'setParentWindow API19 + setFollowParentWindowLayoutEnabled API17，本机支持',
            onRun: () => {
              this.openChildFollow();
            }
          })
          ApiAction({
            title: '应用模态子窗',
            note: 'setSubWindowModal(true, ModalityType.APPLICATION_MODALITY) API14（API12 仅布尔版），本机支持',
            onRun: () => {
              this.openModalApp();
            }
          })
          ApiAction({
            title: '销毁最近创建的子窗',
            note: 'destroyWindow()；也可在子窗内点 × 自毁',
            onRun: () => {
              this.closeSub();
            }
          })
          ApiAction({
            title: 'startAbility 新进程启动自身',
            note: 'StartOptions.processMode API12，PC/平板生效，手机返回 801；processMode 与 startupVisibility 须成对',
            onRun: () => this.startNewProcess()
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
