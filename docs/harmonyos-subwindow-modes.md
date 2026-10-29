# HarmonyOS NEXT 同应用多窗口四种形态实现调研

调研日期：2026-10-29。依据：harmonyos_developer_knowledge MCP 检索的华为官方文档（文档 ID 见文末索引）。

## 关键问题先行：手机/平板能不能开同应用的"普通独立窗口"？

**不能直接开"任意摆放的独立窗口"。** 官方《子窗口开发指导》明确：

> - 在非自由窗口状态下，子窗只会在应用主窗口范围显示。
> - 在自由窗口状态下，子窗可超出应用主窗口范围显示。

手机默认是**非自由窗口**状态（全屏单窗口），因此手机上的子窗口被限制在主窗口范围内、无标题栏装饰，本质接近"应用内悬浮层"，不是 PC 意义上的独立窗口。仅部分手机开启"自由多窗"模式后才进入自由窗口状态。平板的"自由多窗/电脑模式"同理（依据：subwindow-guide、freeform-window-overview）。

**手机/平板替代方案**：
- 应用内浮层：UI 层弹窗（`bindContentCover` / `CustomDialogController`）或受限子窗口；
- 全局悬浮窗：`window.createWindow({windowType: window.WindowType.TYPE_FLOAT})`——需 `ohos.permission.SYSTEM_FLOAT_WINDOW` 系统权限，普通三方应用不可用（依据：window-lifecycle，权限要求见 js-apis-window/arkts-apis-window-f，标注：**具体权限名以官方文档为准，属系统权限**）；
- 画中画 `PiPWindow`（视频场景）、闪控球/闪控窗（API 20/26 起，闪控球需 `ohos.permission.USE_FLOAT_BALL` 受限权限）；
- 分屏：由系统/用户触发，应用可通过 `setSupportedWindowModes` 声明支持。

---

## 四种形态对照表

| 维度 | ① 普通独立窗口（非模态，不跟随） | ② 从属窗口（非模态，跟随主窗） | ③ 模态对话框 | ④ 外部应用（新进程） |
|---|---|---|---|---|
| 同进程 | 是 | 是 | 是（UI 层方案同进程同窗口；窗口层方案同进程不同窗口） | 否（跨应用必跨进程）；同应用内可用 processMode 强制新进程 |
| 阻塞主窗口 | 否 | 否 | 是（UI 层锁页面 / 窗口层锁父窗或整个应用） | 否 |
| 跟随主窗最小化/前后台 | **不跟随**（独立子窗 26.0.0+，仅跟随销毁） | **跟随**（普通子窗默认行为） | 模态期间主窗不可操作，谈不上跟随 | 无关 |
| 核心 API | `windowStage.createSubWindowWithOptions(name, {zLevelAboveParentLoosened: true, decorEnabled: true})` | `windowStage.createSubWindow()` / `createSubWindowWithOptions()`；`setParentWindow()`(19+)；`setFollowParentWindowLayoutEnabled()`(17+) | UI 层：`CustomDialogController`、`promptAction.openCustomDialog`、`bindContentCover`；窗口层：`SubWindowOptions.isModal`、`setSubWindowModal(true)`(12+) / `setSubWindowModal(true, ModalityType)`(14+) | `UIAbilityContext.startAbility(want, options)`；`launchType`；`StartOptions.processMode`；`isolationProcess` |
| PC(2in1) 支持 | 支持（自由窗口默认，子窗可越出主窗、可带标题栏三键） | 支持 | 支持（窗口层模态全设备徽章含 2in1） | 支持；processMode/startupVisibility **仅 PC/2in1+Tablet 生效** |
| phone/tablet 支持 | 子窗可创建，但**非自由窗口状态下被限制在主窗口范围内**、无装饰；"不跟随"的独立子窗语义面向自由窗口 | 支持（同上范围限制） | 支持，PC/手机行为一致（模态语义相同） | startAbility 全设备；processMode 在 phone 上返回 801 |
| 版本门槛 | 独立子窗 `zLevelAboveParentLoosened`：API 26.0.0；`decorEnabled/title/isModal/maximizeSupported`：API 11 | createSubWindow：API 9；带 Options：API 11 | setSubWindowModal：API 12；ModalityType：API 14 | processMode/StartupVisibility：API 12（2in1 13+）；`isolationProcess`：module.json5 标签 |

---

## ① 同程序、普通独立窗口（非模态）

**实现：独立子窗（API 26.0.0 起）**。`SubWindowOptions.zLevelAboveParentLoosened=true` 时创建的是"独立子窗"：

> 独立子窗在自由窗口状态下，不跟随主窗前后台的切换，仅跟随主窗一起销毁，独立子窗与主窗可通过点击调整层级。（subwindow-guide）

- 同进程（同一 UIAbility 的 WindowStage 下），默认非模态（`isModal` 缺省 false）；
- `decorEnabled: true` 时带系统标题栏+三键，可拖拽移动、拖边缩放（配合 `setResizeByDragEnabled(true)`）；
- `maximizeSupported: true` 后子窗可调 `maximize()`；
- **注意**：独立子窗调 `setSubWindowModal()` / `setFollowParentWindowLayoutEnabled()` 不生效或报 1300004（依据：arkts-apis-window-window）。

```ts
// EntryAbility.onWindowStageCreate 中保存 windowStage 到 AppStorage
import { window } from '@kit.ArkUI';

async function openIndependentWindow(windowStage: window.WindowStage) {
  const options: window.SubWindowOptions = {
    title: 'IndependentSubWindow',
    decorEnabled: true,              // PC 自由窗口下带标题栏
    zLevelAboveParentLoosened: true, // 独立子窗：不跟随主窗前后台切换（API 26.0.0+）
    maximizeSupported: true,
  };
  const win = await windowStage.createSubWindowWithOptions('IndependentSubWindow', options);
  await win.moveWindowToAsync(100, 100);   // 自由窗口状态下生效
  await win.resize(1000, 500);
  await win.setUIContent('pages/IndependentSubWindow');
  await win.showWindow();
}
```

**PC 上 26.0.0 之前的近似方案**：普通子窗 + 自行管理显隐；或用 `launchType: "multiton"` 的第二个 UIAbility 开独立主窗（同进程多实例，各自独立任务卡片——形态上更像"另一个主窗口"而非子窗）。**手机**：无等价物，见文首替代方案。

## ② 同程序、从属独立窗口（非模态，跟随主窗）

`windowStage.createSubWindow()` 创建的**普通子窗默认即从属主窗**：官方对独立子窗的反向描述（"不跟随主窗前后台切换，仅跟随销毁"）即说明普通子窗会跟随主窗前后台切换、并跟随销毁（依据：subwindow-guide）。「主窗最小化时子窗是否精确跟随隐藏」未检索到逐字描述，**标注：未确认**；但前后台切换跟随是官方明确行为，最小化会触发主窗退到后台（minimize 文档：可在多任务/Dock 还原）。

相关 API：
- `setParentWindow(windowId)`（19+）：更改子窗父窗口，父窗仅支持同进程主窗/子窗/全局悬浮窗；
- `setFollowParentWindowLayoutEnabled(enabled)`（17+）：子窗/TYPE_DIALOG 模态窗口的位置尺寸完全跟随主窗（仅一级子窗；独立子窗调用返回 1300004）；
- `setRelativePositionToParentWindowEnabled(enabled, anchor?, offsetX?, offsetY?)`（20+）：一级子窗与主窗保持相对位置（需子窗处于 FLOATING 模式）；
- `setFollowParentMultiScreenPolicy`（17+）：跨屏跟随。

```ts
const sub = await windowStage.createSubWindow('toolPanel');
await sub.resize(600, 400);
await sub.setUIContent('pages/ToolPanel');
await sub.showWindow();          // 非模态：主窗仍可操作；主窗前后台切换时跟随
// 需要布局完全跟随主窗时（API 17+，非独立子窗）：
// await sub.setFollowParentWindowLayoutEnabled(true);
```

## ③ 同程序、模态对话框

两种层面，**都能"锁住"，但锁的层级不同**：

**A. UI 层（推荐，PC/手机行为一致）**
- `CustomDialogController`、`promptAction.openCustomDialog`、`bindContentCover`：弹窗挂在当前页面 UI 树上，遮罩阻断页面交互。全设备一致，无窗口概念，PC 上不会越出窗口。

**B. 窗口层（真正的"模态窗口"，PC 上可越出主窗）**
- 创建时 `SubWindowOptions.isModal: true`，或运行时 `setSubWindowModal(true)`（API 12+）；
- API 14+ 可指定模态类型：`ModalityType.WINDOW_MODALITY`（只锁父窗口）/ `ModalityType.APPLICATION_MODALITY`（锁应用所有实例窗口）；
- 官方语义：「启用子窗口模态属性后，其父级窗口不能响应用户操作，直到子窗口关闭或模态被禁用」（arkts-apis-window-window）；
- 限制：仅普通子窗可调，**独立子窗调用不生效**；子窗之外的窗口调用返回 1300004；
- 另有 `window.createWindow({windowType: window.WindowType.TYPE_DIALOG, ctx})` 创建模态窗口（window-lifecycle；模块级 API，见 arkts-apis-window-f）。

```ts
const dialog = await windowStage.createSubWindowWithOptions('modalDlg', {
  title: '', decorEnabled: false, isModal: true,
});
await dialog.setUIContent('pages/ModalDialog');
await dialog.showWindow();
// 或运行时再打开模态并指定类型（API 14+）：
// await dialog.setSubWindowModal(true, window.ModalityType.WINDOW_MODALITY);
```

**PC/手机一致性**：模态语义两端一致（都是"父窗不响应"）；差异在形态——手机上子窗不能越出主窗范围，PC 自由窗口下可以。UI 层方案两端完全一致。

## ④ 唤起外部应用（新进程）

- 跨应用 `startAbility(want)`：目标应用 UIAbility 必然运行在**目标应用自己的进程**，与调用方内存隔离；PC 上目标窗口以自由窗口呈现、有独立 Dock 图标与任务卡片。
- `launchType`（module.json5）：`singleton`（单实例）/ `multiton`（每次 startAbility 新建实例，最近任务列表可见多个）/ `specified`（业务内自定，依据：uiability-launch-type）。
- **同应用强制新进程**：`StartOptions.processMode`（API 12，contextConstant.ProcessMode）：
  - `NEW_PROCESS_ATTACH_TO_PARENT`(1)：新建进程并跟随父进程退出（限同应用）；
  - `NEW_PROCESS_ATTACH_TO_STATUS_BAR_ITEM`(2) / `ATTACH_TO_STATUS_BAR_ITEM`(3)：绑定到状态栏图标（限同应用、且应用在状态栏有图标）；
  - **设备差异：仅 PC/2in1 和 Tablet 生效，其他设备返回 801**（js-apis-app-ability-contextconstant）。
- `StartOptions.startupVisibility`：`STARTUP_HIDE` 时窗口不上前台、Dock 无图标、不走 onForeground（同样仅 PC/2in1+Tablet）。
- `isolationProcess`（module.json5 abilities 标签）：让该 Ability 运行在独立进程（依据：application-adaptation-freeform-window 中配置示例，**详细语义未单独核对，标注：未确认**）。

```ts
import { common, Want, StartOptions, contextConstant } from '@kit.AbilityKit';

const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
const want: Want = { bundleName: 'com.example.app2', abilityName: 'EntryAbility' };
// 跨应用：默认即目标应用自己的进程，无需 processMode
ctx.startAbility(want);

// 同应用强制新进程（仅 PC/2in1/Tablet；手机返回 801）：
// const options: StartOptions = { processMode: contextConstant.ProcessMode.NEW_PROCESS_ATTACH_TO_PARENT };
// ctx.startAbility(want, options);
```

---

## 未验证/未确认项汇总

- 普通子窗是否"精确跟随主窗最小化隐藏"：未确认（官方仅明确"跟随前后台切换"）。
- 全局悬浮窗 `TYPE_FLOAT` 的权限名与开放范围：属系统权限，普通三方不可用，具体权限名未逐字核对。
- `isolationProcess` 详细语义：未确认。
- 以上代码骨架基于官方示例整理，真机/PC 实机行为未验证。

## 文档依据索引

| 文档 ID | 要点 |
|---|---|
| harmonyos-guides/subwindow-guide | 子窗范围限制、独立子窗语义与示例 |
| harmonyos-guides/freeform-window-overview | 自由窗口设备支持（PC 默认/平板电脑模式/手机自由多窗） |
| harmonyos-references/arkts-apis-window-windowstage | createSubWindow(WithOptions)、SubWindowOptions |
| harmonyos-references/arkts-apis-window-window | setSubWindowModal/ModalityType、setParentWindow、setFollowParentWindowLayoutEnabled、setRelativePositionToParentWindowEnabled |
| harmonyos-guides/window-lifecycle | createWindow 用途（全局悬浮窗/模态窗/系统窗） |
| harmonyos-references/js-apis-app-ability-contextconstant | ProcessMode/StartupVisibility，仅 PC/2in1+Tablet |
| harmonyos-guides/uiability-launch-type | singleton/multiton/specified |
