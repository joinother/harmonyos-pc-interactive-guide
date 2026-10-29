# HarmonyOS PC「沉浸式」概念与 API 全解

调研日期：2026-10-29。依据：harmonyos_developer_knowledge MCP + 官方《窗口沉浸式》指南。

## 一、概念区分（这是"觉得奇怪"的根源）

| UI 元素 | 是什么 | 由谁绘制 | 应用能否控制 |
|---|---|---|---|
| **系统状态栏**（PC 顶部/底部的系统栏，含时间、Wi-Fi、电量等） | 系统级、跨所有应用的全局栏 | 系统 | **基本不能**。PC（自由窗口）下 `setWindowSystemBarEnable`/`setSpecificSystemBarEnabled` **不生效** |
| **窗口标题栏（含三键）** | 每个自由窗口顶部那一条：应用图标+应用名+最小化/最大化/关闭 | 窗口管理器（系统），属窗口"装饰" | **能**：`setWindowDecorVisible(false)` 可隐藏；三键可单独控制可见性 |
| **任务栏/Dock**（屏幕底部图标栏） | 系统全局 | 系统 | 仅能扩展自己图标的右键菜单（quickBarManager）；不能隐藏。全屏沉浸时可禁用 hover 唤出 |

**手机 vs PC 的"沉浸式"不是一回事**：

- **手机（非自由窗口，全屏单窗）**：沉浸式 = 隐藏状态栏+导航条 + 内容延伸到它们下方。靠 `setWindowLayoutFullScreen` + `setSpecificSystemBarEnabled('status', false)`。
- **PC（自由窗口）**：窗口本身是带装饰的矩形，"沉浸式"指**窗口标题栏隐藏、应用内容铺满整个窗口**；顶部系统状态栏和底部 Dock 不在应用窗口权限内。官方《窗口沉浸式》指南原文：

  > 自由窗口状态下，可通过 `setWindowDecorVisible()` 接口控制窗口标题栏显隐，当标题栏隐藏时，窗口处于沉浸式布局。

  且：

  > `setSpecificSystemBarEnabled`、`setWindowSystemBarEnable` 等控制系统界面元素显示的接口**仅非自由窗口状态下的主窗口支持**，在辅助窗口中调用或自由窗口状态下调用**不生效**。

这就是把手机沉浸代码搬到 PC 上"设了没效果"的原因——PC 永远是自由窗口，系统栏 API 直接被无视。

## 二、沉浸式/装饰相关 API 全清单

| API | 所属模块 | 起始版本 | 设备支持（徽章） | 实际作用 | PC(2in1) 效果 |
|---|---|---|---|---|---|
| `setWindowLayoutFullScreen(isLayoutFullScreen)` | @kit.ArkUI window | 9 | phone 12+ \| 2in1 13+ \| tablet 12+ \| tv 19+ \| wearable 23+ | 设窗口为沉浸式布局，内容延伸到状态栏/导航条/三键导航区域，可与之重叠 | 自由窗口下用 `setWindowDecorVisible` 更直接；本接口在自由窗口下仍可设布局但不隐藏系统栏 |
| `setImmersiveModeEnabledState(enabled)` | @kit.ArkUI window | 12 | phone 12+ \| 2in1 13+ \| tablet 12+ \| tv 19+ \| wearable 18+ | 开启沉浸式布局（不改变窗口模式/大小），仅主窗/子窗 | 同上，PC 自由窗口语义由标题栏隐藏决定 |
| `getImmersiveModeEnabledState()` / `isImmersiveLayout()`(20+) | @kit.ArkUI window | 12 / 20 | 全设备 | 查询是否沉浸式布局 | 可用 |
| `setWindowDecorVisible(isVisible)` | @kit.ArkUI window | 11 | phone 12+ \| 2in1 13+ \| tablet 12+ | 显示/隐藏**窗口标题栏** | **PC 沉浸式核心**：隐藏后内容铺满窗口；全屏时鼠标 hover 顶部热区仍可能显悬浮标题栏 |
| `setWindowDecorHeight(height)` / `getWindowDecorHeight()` | @kit.ArkUI window | 11 | phone 12+ \| 2in1 13+ \| tablet 12+ | 设置/获取标题栏高度 | PC 自由窗口生效 |
| `getTitleButtonRect()` / `on('windowTitleButtonRectChange')` | @kit.ArkUI window | 11 | phone 12+ \| 2in1 13+ \| tablet 12+ | 获取三键矩形区域，自绘顶部时避让 | PC 必用（隐藏标题栏后自绘需避让三键） |
| `setWindowTitleButtonVisible(max, min, close?)` | @kit.ArkUI window | 14 | phone 14+ \| 2in1 14+ \| tablet 14+ | 单独控制三键可见性；仅主窗/独立子窗 | PC 可隐藏；但关闭窗口需自绘按钮或靠系统快捷键（Alt+F4 等系统保留，应用不可绑定） |
| `setWindowTitleMoveEnabled(enabled)` | @kit.ArkUI window | 14 | phone 14+ \| 2in1 14+ \| tablet 14+ | 禁用标题栏默认拖拽移动/双击最大化 | PC 自绘标题栏时配合 `startMoving()` 用 |
| `setTitleAndDockHoverShown(isTitle?, isDock?)` | @kit.ArkUI window | 14 | phone 14+ \| 2in1 14+ \| tablet 14+ | 全屏模式下鼠标 hover 热区是否显示标题栏和 **Dock** | PC 视频/PPT 全屏沉浸时禁用 hover 唤出 |
| `setWindowSystemBarEnable()` | @kit.ArkUI window | 9 | **phone 12+ \| tablet 12+ \| tv 19+ \| wearable 18+（无 2in1）** | 控制状态栏/导航条显隐 | **PC 不生效**（徽章不含 2in1；官方指南明确自由窗口下不生效） |
| `setSpecificSystemBarEnabled(name, enable)` | @kit.ArkUI window | 11 | phone 12+ \| tablet 12+ \| tv 19+ \| wearable 18+（无 2in1） | 单独隐藏状态栏/导航条/三键导航 | **PC 不生效**；且非全屏/最大化时不立即生效 |
| `setWindowSystemBarProperties()` | @kit.ArkUI window | 9 | phone \| tablet \| tv \| wearable（无 2in1） | 设置状态栏颜色等属性 | **PC 不生效** |
| `maximize(presentation?: MaximizePresentation)` | @kit.ArkUI window | 12 | phone 12+ \| 2in1 13+ \| tablet 12+ | 窗口最大化；传参可进入沉浸全屏（`ENTER_IMMERSIVE` / `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER`） | **应用主动调用时** `presentation` 默认 `ENTER_IMMERSIVE`→进全屏（隐藏标题栏/Dock/状态栏）；**系统标题栏放大按钮默认走 MAXIMIZE**（保留标题栏/Dock/状态栏），两者不是同一路径 |
| `maximizeWithOptions(maximizeOptions?: MaximizeOptions)` | @kit.ArkUI window | 26.0.0 | phone 26.0.0+ \| 2in1 26.0.0+ \| tablet 26.0.0+ | 最大化，可配置布局/跨屏/截图动画；不传参等同 `maximize()` 默认值 | `maximizePresentation` 默认 `ENTER_IMMERSIVE`；同样仅影响应用主动调用，不改变系统放大按钮行为 |
| `recover()` | @kit.ArkUI window | 11 | 2in1 11+ \| tablet 11+（无 phone） | 从全屏/最大化还原为自由悬浮窗口 | PC 退出全屏沉浸用 |
| `setWindowContainerColor(active, inactive)` | @kit.ArkUI window | 20 | **2in1 20+ \| tablet 23+（无 phone）** | 窗口容器焦点/非焦点态背景色（含标题栏+内容） | PC 美化沉浸边缘 |
| `setWindowContainerModalColor()` | @kit.ArkUI window | 26.0.0 | **仅 2in1** | 模态窗口容器背景色 | PC 专属 |
| `setWindowShadowEnabled(enable)` | @kit.ArkUI window | 20 | 2in1 20+ \| tablet 23+（无 phone） | 主窗口阴影开关 | PC 去边框沉浸感 |
| `setWindowShadowRadius()` / `setWindowCornerRadius()` | @kit.ArkUI window | 17/18 | phone/2in1/tablet | 子窗/悬浮窗阴影半径、圆角 | PC 视觉沉浸 |

## 三、"有没有沉浸的设置"——直接回答

**有，但分两层**：

1. **应用代码层（能做）**：
   - `setWindowDecorVisible(false)` 隐藏窗口标题栏 → 应用内容铺满窗口（这是 PC 上的"无边框沉浸"）；
   - 配合 `getTitleButtonRect` 自绘顶部区域，避让三键，或用 `setWindowTitleButtonVisible` 隐藏三键；
   - `maximize(MaximizePresentation.ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER)` 进入真正的沉浸全屏（连系统状态栏+Dock 都不 hover 出来，视频/PPT 用）。

2. **系统设置层**：系统状态栏/Dock 的全局显隐由系统设置/手势控制，三方应用**无权隐藏**系统状态栏。

**应用在 PC 上的极限**：无边框（隐藏窗口标题栏）+ 自绘标题栏 + 内容铺满窗口 + 最大化；要"连系统状态栏和 Dock 都消失"只能走**全屏沉浸模式**（`maximize` 沉浸参数），且退出后恢复。

**三键隐藏后怎么关窗**：应用自绘关闭按钮调 `destroyWindow()`；系统侧有窗口关闭手势/快捷键（如 Alt+F4 属系统保留快捷键，应用不能绑定拦截——见 keyboardShortcut 禁止项），**具体 PC 关闭手势未在文档中明确列出，标注：未确认**。

## 四、通俗解释：三个概念别再混

- **无边框沉浸**：`setWindowDecorVisible(false)`——把你窗口自己的标题栏和三键那条去掉，内容顶到窗口上边缘。窗口还是那个窗口，大小不变；**系统状态栏和 Dock 还在**。
- **最大化铺满（MAXIMIZE）**：系统放大按钮的默认态，或应用调 `maximize(EXIT_IMMERSIVE)` ——窗口放大到占满屏幕，**仍保留标题栏、三键、系统状态栏和 Dock**（window-faqs / window-mode-overview 原文：MAXIMIZE = 铺满整个屏幕，有 dock 栏、状态栏和标题栏）。和"全屏"不是一回事。
- **全屏沉浸（FULL_SCREEN）**：应用调 `maximize(ENTER_IMMERSIVE)` / `maximize(ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER)` 或 `maximize()` 默认参数——铺满屏幕，**默认隐藏标题栏/三键/状态栏/Dock**，hover 热区可唤出（除非用 `_DISABLE_TITLE_AND_DOCK_HOVER`）。
- **真正隐藏系统栏**：`maximize(MaximizePresentation.ENTER_IMMERSIVE...)`——进入沉浸全屏，系统状态栏/Dock 被隐藏，鼠标 hover 也不唤出（视频播放、PPT 演示场景）。

手机沉浸代码（`setWindowLayoutFullScreen` + `setSpecificSystemBarEnabled`）搬到 PC 之所以"没效果"，是因为 PC 永远是自由窗口，系统栏 API 在自由窗口下被官方明确禁用；PC 要沉浸得换用 `setWindowDecorVisible` / `maximize(沉浸参数)` 这一套。

## 五、代码骨架（PC 无边框沉浸 + 自绘避让三键）

```ts
import { window } from '@kit.ArkUI';

onWindowStageCreate(windowStage: window.WindowStage): void {
  windowStage.loadContent('pages/Index', async () => {
    const win = windowStage.getMainWindowSync();
    // PC 沉浸：隐藏窗口标题栏（内容铺满窗口）
    win.setWindowDecorVisible(false);
    // 若要隐藏三键（仅主窗/独立子窗），需自绘关闭按钮
    // win.setWindowTitleButtonVisible(false, false, false);
  });
}

// 页面内自绘顶部栏时避让系统三键
const rect = win.getTitleButtonRect(); // {right, top, width, height}
// 顶部自定义 Row 的宽度 = 窗口宽 - rect.width，避免遮挡三键

// 需要连系统状态栏+Dock 一起隐藏时（视频全屏）：
await win.maximize(window.MaximizePresentation.ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER);
// 退出：
await win.recover();
```

## 六、未确认/边界项

- PC 顶部系统状态栏的准确位置（顶部还是底部）与显隐手势：官方 PC 设计规范未在本次检索中逐字核对，**未确认**；可确认的是三方应用无法隐藏系统状态栏。
- 隐藏三键后 PC 端系统关闭窗口的快捷键/手势兜底：未在文档中明确，**未确认**。
- `setWindowLayoutFullScreen` 在 PC 自由窗口下的具体效果差异：指南明示自由窗口用 `setWindowDecorVisible`，本接口在 PC 上主要影响布局延伸而非系统栏显隐。

## 七、追加问题 A：无边框窗口"鼠标移到顶部有时弹出标题栏三键，有时不弹"——触发条件

**核心结论**：这是**窗口形态 + decor 状态**共同决定的，不是随机。分清"系统悬停唤出"和"三键残留"两种完全不同的现象。

### 悬停显隐触发条件表

| 窗口形态 | decorVisible | 三键可见性 | 鼠标移到顶部是否弹标题栏/三键 | 触发方 | 应用能否关闭 |
|---|---|---|---|---|---|
| 普通自由窗口（非全屏） | true（默认） | 显示 | 无（本来就在） | 系统 | — |
| 普通自由窗口 | **false** | **三键仍显示**（官方：隐藏标题栏后仅保留右上角三键） | 不弹，三键常驻右上角 | 系统绘制 | 想完全去掉三键须再调 `setWindowTitleButtonVisible(false,false,false)` |
| 普通自由窗口 | false | **false**（三键全隐） | 不弹、不显示 | — | 稳定无系统装饰 |
| **全屏沉浸**（`maximize(ENTER_IMMERSIVE...)`） | false | 已隐 | **会弹"悬浮标题栏"**（系统顶部热区） | **系统固定行为** | 可：`setTitleAndDockHoverShown(false,false)` 禁用 |
| 最大化（默认 MAXIMIZE） | false | 已隐 | 顶部热区是否弹：**未确认**（按全屏沉浸规律推断可能弹，需实测） | 系统 | 同 `setTitleAndDockHoverShown` |
| 分屏 | — | 通常显示 | 非自由窗口语义 | — | 不适用 |
| 只调 `setWindowLayoutFullScreen(true)`，没调 `setWindowDecorVisible(false)` | 仍 true | 显示 | 标题栏+三键都还在（只是内容延伸上去了） | — | 必须再 `setWindowDecorVisible(false)` |

**逐条核实依据**：

1. **隐藏标题栏后三键仍在**：官方最佳实践《Immersive Title Bar in the Freeform Window》原文："Call `setWindowDecorVisible(false)` to hide the title bar and **display only the three buttons** in the upper-right corner. In this case, the app page is extended to the title bar area." —— 这是用户最常遇到的"明明设了无边框，三键还在"。
2. **全屏沉浸时 hover 弹悬浮标题栏**：`setWindowDecorVisible` 文档原文："设置窗口标题栏不可见后，当主窗口进入**全屏沉浸状态**时，此时鼠标 Hover 到上方窗口标题栏热区上会显示悬浮标题栏。若想禁用悬浮标题栏显示，请使用 `setTitleAndDockHoverShown()` 接口。" —— **仅全屏沉浸态才有的系统固定行为**。
3. **禁用 hover 唤出**：`setTitleAndDockHoverShown(isTitleHoverShown?, isDockHoverShown?)`（API 14+，phone/2in1/tablet），在自由窗口设备上生效，其它设备返回 801。
4. **彻底隐藏三键**：`setWindowTitleButtonVisible(max, min, close?)`（API 14+），仅主窗/独立子窗。
5. **应用级"鼠标动才显示、静止就隐藏"**：官方 FAQ《PC应用如何隐藏导航栏右上角三键》方案：用 `onMouse` 监听鼠标位置，定时检测静止 → 静止时 `setWindowDecorVisible(false)` + `setWindowTitleButtonVisible(false,false,false)`；移动时再显示。这是**应用自实现的悬停逻辑**，不是系统行为。
6. **部分接口在 2in1 机型不生效**：同一 FAQ 明确"Window 部分接口虽然显示支持 PC/2in1……在部分机型下不生效"——这也是"有时有反应有时没反应"的可能来源，需做机型适配与 try-catch。
7. **子窗 decorEnabled**：`SubWindowOptions.decorEnabled`（创建时）决定子窗是否带标题栏；自由窗口下 `decorEnabled: true` 才有标题栏+三键，`false` 为沉浸式。运行时仍可 `setWindowDecorVisible` 切换。

**系统固定行为（应用无法关闭）**：全屏沉浸下顶部"悬停唤出悬浮标题栏"的热区机制本身，只能用 `setTitleAndDockHoverShown(false,false)` 关显示，不能关热区。系统状态栏/Dock 的 hover 唤出同理。

## 八、追加问题 B：自绘三键（把窗口控制"画进内容区"）

### 能不能"既保留系统三键又把它画进内容区"？

**不能，二选一。** 依据：系统三键由窗口管理器绘制在窗口"三键区"（标题栏右侧固定位置），没有 API 能把系统三键"移动"或"嵌入"到应用内容区。最佳实践原文也只给两条路：① 隐藏标题栏、**保留系统三键**（内容延伸到标题栏区，但必须用 `getTitleButtonRect()` 避让右上角那一块）；② **隐藏系统三键 + 自绘**。没有"系统三键进内容"的方案。

### 完整方案

```ts
// 1) EntryAbility：隐藏系统装饰与三键
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', () => {
      const win = windowStage.getMainWindowSync();
      win.setWindowDecorVisible(false);                      // 隐藏标题栏
      win.setWindowTitleButtonVisible(false, false, false);  // 隐藏三键（主窗/独立子窗）
      // 禁用系统默认标题栏拖拽/双击最大化，改由自绘标题栏接管
      win.setWindowTitleMoveEnabled(false);
      // 若处于全屏沉浸，禁用 hover 唤出悬浮标题栏
      win.setTitleAndDockHoverShown(false, false).catch(() => {});
    });
  }
}
```

```ts
// 2) 自绘标题栏组件（页面顶部一条 Row）
import { window, common } from '@kit.ArkUI';

@Component
struct MyTitleBar {
  private ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private win: window.Window | undefined = undefined;
  @State isMax: boolean = false;

  aboutToAppear() {
    this.ctx.windowStage?.getMainWindow().then(w => {
      this.win = w;
      w.on('windowStatusChange', (status) => {
        this.isMax = (status === window.WindowStatusType.MAXIMIZE);
      });
    });
  }

  // 拖动窗口：必须在 onTouch 的 TouchType.Down 中调用 startMoving
  build() {
    Row() {
      Text('我的应用').layoutWeight(1)
      Button('—').onClick(() => this.win?.minimize())
      Button(this.isMax ? '❐' : '▢').onClick(() => {
        if (this.isMax) this.win?.recover(); else this.win?.maximize();
      })
      Button('✕').onClick(() => {
        // 关闭主窗口：推荐 terminateSelf（destroyWindow 文档未列主窗）
        this.ctx.terminateSelf();
      })
    }
    .width('100%').height(40)
    .onTouch((e) => {
      if (e.type === TouchType.Down) {
        this.win?.startMoving();   // 自由窗口主窗生效；非自由窗口主窗返回 801/1300004
      }
    })
    // 双击最大化/还原（用 onTouch 计数或 gesture）
    .gesture(TapGesture({ count: 2 }).onAction(() => {
      if (this.isMax) this.win?.recover(); else this.win?.maximize();
    }))
  }
}
```

### API 核对与注意点

| 能力 | API | 版本/设备 | 备注 |
|---|---|---|---|
| 隐藏系统标题栏 | `setWindowDecorVisible(false)` | 11+，phone/2in1/tablet | 自由窗口下为沉浸式布局 |
| 隐藏系统三键 | `setWindowTitleButtonVisible(false,false,false)` | 14+，phone/2in1/tablet | 仅主窗/独立子窗，其他返回 1300004 |
| 禁用系统标题栏拖拽/双击最大化 | `setWindowTitleMoveEnabled(false)` | 14+，phone/2in1/tablet | 与自绘 `startMoving` 配合 |
| 拖动窗口 | `startMoving()` | 14+ | **必须在 onTouch(TouchType.Down) 回调里调**；自由窗口主窗生效 |
| 最小化 | `minimize()` | 11+，全设备 | 主窗最小化；PC 可从 Dock/restore 还原 |
| 最大化/还原 | `maximize()` / `recover()` | 12+/11+ | 子窗需 `maximizeSupported: true` |
| 查询窗口状态 | `getWindowStatus()` / `on('windowStatusChange')` | 12+/11+ | 判断当前是否 MAXIMIZE 以切换按钮图标 |
| 关闭主窗口 | `UIAbilityContext.terminateSelf()` | — | **推荐**；`destroyWindow()` 文档支持 系统窗/子窗/悬浮窗/模态窗，**未列应用主窗**，主窗关闭请用 terminateSelf |
| 销毁子窗 | `destroyWindow()` | 9+ | 子窗/模态窗用这个 |
| 禁用 hover 悬浮标题栏 | `setTitleAndDockHoverShown(false,false)` | 14+ | 仅全屏沉浸场景需要 |
| 自绘避让系统三键 | `getTitleButtonRect()` | 11+ | 仅"保留系统三键+内容延伸"时用；全自绘方案不需要 |

### 如何避免系统又把三键露出来

- 普通自由窗口：`setWindowDecorVisible(false)` + `setWindowTitleButtonVisible(false,false,false)` 后，系统不会再显示系统三键（非全屏态无 hover 弹出）；
- 若进入全屏沉浸：再调 `setTitleAndDockHoverShown(false,false)` 关 hover 唤出；
- 不建议只调 `setWindowLayoutFullScreen(true)`（内容延伸但 decor 还在，三键仍在）；
- 部分 2in1 机型接口存在适配性问题（FAQ 原文），务必 try-catch 并提供降级。

### 隐藏三键后的关闭兜底

- **应用自绘关闭按钮**（必做）——调 `terminateSelf()`；
- **Dock 图标右键 → 关闭**（系统级，应用不可控但客观存在）；
- **系统快捷键**：如 Alt+F4 属系统保留快捷键，应用不可绑定/拦截，由系统关闭窗口（PC 上是否生效未在文档逐字确认，标注：未确认，以实测为准）；
- 任务管理器强制结束。

## 九、追加部分未确认项

- 普通最大化（非沉浸）时顶部是否存在"悬停唤出悬浮标题栏"热区：未确认（官方仅明确"全屏沉浸状态"有）；
- PC 隐藏三键后系统级关闭快捷键（如 Alt+F4）是否生效：未确认；
- `destroyWindow()` 在主窗上的实际效果：文档支持列表未列主窗，不推荐用于主窗关闭；
- 部分 2in1 机型窗口接口适配性差异：官方 FAQ 已明示存在，需机型实测。

## 十、追加问题 C：系统三键叠在内容上时——透明还是方块？标题栏背景能否透明？

### 1. 系统三键的视觉构成（图标 / 热区 / 底色）

- 官方《PC应用如何隐藏导航栏右上角三键》FAQ 提到深色模式下"右上角三键的显示颜色……升级后三键将显示为白色"——说明三键是**符号图标**（最小化/还原/关闭），颜色随深浅色主题变化，并非带常驻底色的实心方块。
- 按钮是否带常驻方形底色：官方文字规范**未逐字说明**，按桌面系统惯例与 FAQ 描述判断为「图标 + 悬停/按压时圆角高亮态」；**是否有常驻方块底色标注：未确认**，建议以官方设计规范截图/真机为准。
- 三键位于窗口标题栏右侧固定的"三键区"，由窗口管理器绘制，层级在应用内容之上。

### 2. 内容延伸到标题栏下时，那条区域的背景是什么

两种情况要分清：

| 操作 | 标题栏区域显示 |
|---|---|
| 只调 `setWindowLayoutFullScreen(true)`，**不**调 `setWindowDecorVisible(false)` | 系统标题栏仍在，背景 = 窗口容器色（`setWindowContainerColor`，默认跟随系统深浅色主题），形成一条**系统底色横条 + 三键**。内容被这条横条压住，不能真正铺上去 |
| `setWindowDecorVisible(false)`（隐藏标题栏） | 标题栏"装饰"消失，**应用内容可以铺到顶部**；三键仍浮在右上角（除非再 `setWindowTitleButtonVisible(false)`）。此时三键区域背后是你的应用内容，不是系统底色条 |

依据：
- `setWindowContainerColor` 文档："窗口容器背景色覆盖整个窗口区域，**包括标题栏和内容区域**……标题栏显示窗口容器背景色"（2in1 20+ / tablet 23+，**无 phone**）。
- `setWindowBackgroundColor`：徽章仅 `tv 19+ | wearable 18+`，**PC/2in1 不支持**。
- 自由窗口沉浸式最佳实践：`setWindowDecorVisible(false)` 后"the app page is extended to the title bar area"。

### 3. 能否控制标题栏背景透明/颜色/模糊

| 能力 | API | PC(2in1) 支持 | 说明 |
|---|---|---|---|
| 窗口容器（含标题栏）背景色 | `setWindowContainerColor(activeColor, inactiveColor)` | 2in1 20+ | 可设焦点/非焦点态背景色，含标题栏区 |
| 窗口整体背景色 | `setWindowBackgroundColor` | **不支持**（仅 tv/wearable） | PC 上不要用 |
| 标题栏单独透明/模糊 | — | **未找到对应 API** | 无 `setWindowTitleBarTransparent` / `setWindowDecorBlur` 类接口；透明效果靠隐藏装饰 + 自绘内容实现 |
| 异形/透明掩码 | `setWindowMaskWithAlpha` | 2in1 26.0.0+ | 仅限子窗/全局悬浮窗，主窗不可用 |
| 窗口背景模糊（毛玻璃） | — | **未确认**（本次未检索到窗口级 blur API） | |

### 4. 两种"透明"的区分

- **窗口整体透明（透出桌面）**：主窗无通用透明 API；子窗/悬浮窗可用 `setWindowMaskWithAlpha`（26.0.0）做异形透明。**主窗整体透出桌面：未确认有官方能力**。
- **内容从标题栏下面透出来**：`setWindowDecorVisible(false)` 后即可，应用内容绘制到标题栏区域，三键以图标形式浮在内容之上。

### 5. 结论：会不会出现一个个方块？

- **只铺内容不隐藏装饰** → 看到一条系统底色横条 + 三键（不是融入画面）。
- **隐藏装饰后内容铺到顶** → 三键以**图标形式**叠在你的内容上，背后是应用内容而非系统底色；正常情况下**不会**出现独立的方块底色（悬停时才出现圆角高亮）。
- 想让三键区域完全无底色、和画面融为一体：只能**自绘三键**（`setWindowTitleButtonVisible(false,false,false)` + 自绘按钮），并自己处理 hover/按压态。

---

## 十一、追加问题 D：点系统"放大"按钮后，标题栏和三键"有时隐藏、有时不隐藏"——真实原因与确定性做法

> **本节是对上一版结论的纠正**。上一版写"系统放大按钮固定走 `maximize()`，`presentation` 默认 `ENTER_IMMERSIVE`，所以一定进沉浸全屏"——这个说法**过于绝对，与用户实测和官方指南冲突**。下面按官方原文重新核对。

### 1. 先分清两件事：`maximize()` API 默认值 ≠ 系统放大按钮行为

**（1）`maximize()` API 的默认参数（已逐字核实，arkts-apis-window-window）**

`maximize(presentation?: MaximizePresentation): Promise<void>`

> 参数 `presentation` 说明："主窗口或子窗口最大化时的布局枚举。**默认值 `window.MaximizePresentation.ENTER_IMMERSIVE`，即默认最大化时进入全屏模式**。"

`MaximizePresentation` 完整枚举（arkts-apis-window-e，已核实）：

| 名称 | 值 | 说明 |
|---|---|---|
| `FOLLOW_APP_IMMERSIVE_SETTING` | 0 | 最大化时，**跟随应用当前设置的全屏模式** |
| `EXIT_IMMERSIVE` | 1 | 最大化时，如果当前窗口设置了全屏模式会**退出**全屏模式（即进 MAXIMIZE，保留标题栏/Dock） |
| `ENTER_IMMERSIVE` | 2 | 最大化时，**进入全屏模式**，鼠标悬停热区显示标题栏和 dock 栏 |
| `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER`（14+） | 3 | 最大化时，进入全屏模式，**悬停热区也不显示**标题栏和 dock 栏 |

`maximizeWithOptions(MaximizeOptions)`（26.0.0+）的 `maximizePresentation` 字段默认也是 `ENTER_IMMERSIVE`；不传参时行为等同 `maximize()` 默认值。

**这个默认值只对「应用主动调用 `maximize()`」生效。**

**（2）系统标题栏放大按钮的默认行为（官方指南原文）**

《应用适配自由窗口》（application-adaptation-freeform-window）原文：

> "在 PC/2in1 设备或开启电脑模式的 Tablet 设备上，**点击窗口最大化按钮，窗口默认以最大化显示，且不会自动隐藏标题栏、Dock 栏**。如果应用需要进入沉浸式全屏显示，隐藏标题栏、Dock 栏，则需要进行适配。"

《窗口模式简介》（window-mode-overview）对两种模式的定义：

- **MAXIMIZE**："窗口占据整个屏幕空间，**不需要 hover 就可以显示 dock 栏、状态栏和标题栏**。仅在自由窗口状态下存在该模式。"
- **FULL_SCREEN**："在自由窗口状态下，窗口铺满整个屏幕，**默认无 dock 栏、标题栏和状态栏显示**。"

window-faqs 也确认：MAXIMIZE = 铺满整个屏幕，有 dock 栏和状态栏。

**结论：系统放大按钮默认进 `MAXIMIZE`（保留标题栏/三键/Dock/状态栏），不是 `FULL_SCREEN`。** 上一版"系统放大按钮内部走 `maximize()` 默认参数"的推断不成立——系统按钮走的是系统自己的最大化路径（进 MAXIMIZE），不等同于应用调 `maximize(ENTER_IMMERSIVE)`。

**（3）官方文档之间的一处矛盾（如实标注）**

window-mode-overview 在 FULL_SCREEN 的"触发方式"里列了一条"用户点击系统标题栏中的最大化按钮"，与 application-adaptation-freeform-window 及 games-adapt-pc-platform 的描述（点击→MAXIMIZE，保留标题栏/Dock）**直接冲突**。

采信原则：application-adaptation-freeform-window 是专门讲自由窗口适配的指南，games-adapt-pc-platform 给出了可运行的代码模式（监听 `MAXIMIZE` 后再调 `maximize(ENTER_IMMERSIVE)` 才能隐藏标题栏/Dock），且与用户实测"有时不隐藏"一致；window-mode-overview 那条可能是简化表述或对应更高 API 版本/特定配置。**本报告以 application-adaptation-freeform-window + games-adapt-pc-platform 的描述为准。**

### 2. 为什么"有时隐藏、有时不隐藏"——可能的条件

系统放大按钮默认保留标题栏/Dock。出现"隐藏"的情况，通常是应用做了适配或窗口此前处于特定状态：

| 条件 | 点放大后标题栏/三键 | 依据/说明 |
|---|---|---|
| 默认情况（应用未做任何最大化适配） | **保留**（MAXIMIZE） | application-adaptation-freeform-window 原文 |
| 应用在 `windowStatusChange` 监听到 `MAXIMIZE` 后调了 `maximize(ENTER_IMMERSIVE)` | **隐藏**（切到 FULL_SCREEN） | games-adapt-pc-platform 给出的标准模式 |
| 应用此前调过 `setWindowLayoutFullScreen(true)` / `setImmersiveModeEnabledState(true)` 设了全屏模式，且系统放大内部走 `FOLLOW_APP_IMMERSIVE_SETTING` 语义 | **可能隐藏** | 枚举 `FOLLOW_APP_IMMERSIVE_SETTING`=0 的语义是"跟随应用当前全屏设置"；但**系统放大按钮内部是否用此枚举，官方未公开，标注：未确认/疑似** |
| 应用显式 `setWindowDecorVisible(false)` + `setWindowTitleButtonVisible(false,false,false)` | 三键隐藏（标题栏已隐） | 任意窗口形态下都生效，与最大化路径无关 |
| 子窗口 `decorEnabled:false` 创建，且 `maximizeSupported:true` | 子窗最大化时无标题栏 | SubWindowOptions.decorEnabled |
| `module.json5` 配置 `supportWindowMode` 不含 `"fullscreen"` | 无法进入 FULL_SCREEN，最大化只能是 MAXIMIZE（保留标题栏） | window-mode-overview：自由窗口下 fullscreen 才表示支持 FULL_SCREEN+MAXIMIZE |
| 设备处于分屏/自由多窗非电脑模式 | 路径不同，通常保留标题栏 | 非自由窗口语义 |
| 不同 API 版本 / 厂商机型 / 2in1 vs 平板电脑模式 | **可能存在差异** | window-faqs 明示"部分 2in1 接口存在适配性问题"；具体差异未公开，标注：未确认/疑似厂商适配 |

### 3. 系统三键点击到底调什么、应用能不能配置

- 系统放大/最小化/关闭按钮的点击由**窗口管理器内部处理**，**没有公开 API 暴露其内部调用**，应用**无法拦截、重写或配置**系统三键的行为。
- 应用能做的只有**被动监听**：`on('windowStatusChange')`（API 11+，变化立即触发，属性可能未更新）/ `on('windowStatusDidChange')`（API 20+，Rect 更新后触发），以及 `getWindowStatus()` 主动查询。
- `MaximizePresentation` / `MaximizeOptions.maximizePresentation` 只在**应用主动调 `maximize()` / `maximizeWithOptions()`** 时生效，**不影响系统放大按钮**。
- `module.json5` 的窗口相关 metadata（`ohos.ability.window.isMaximize`、`ohos.ability.window.supportWindowModeInFreeMultiWindow`、`supportWindowMode` 属性）只控制**启动模式**和**支持的模式范围**，**不能改变系统放大按钮点击后的默认形态**。
  - `ohos.ability.window.isMaximize=true`：主窗启动即 MAXIMIZE（PC/2in1 生效），不是改系统按钮行为。
  - 不存在 `maximizeMode` 这类控制"系统放大按钮走沉浸还是最大化"的配置字段（已核实 window-config-m 全文，无此字段）。

### 4. 确定性做法

#### 做法 A：点系统放大后**一定**无边框、无三键（进 FULL_SCREEN）

因为系统按钮默认进 MAXIMIZE 保留标题栏，应用必须在状态回调里主动切到 FULL_SCREEN：

```ts
mainWindow.on('windowStatusChange', (status) => {
  if (status === window.WindowStatusType.MAXIMIZE) {
    // 系统放大进了 MAXIMIZE，主动切到沉浸全屏
    mainWindow.maximize(window.MaximizePresentation.ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER)
      .catch(() => {});
  }
  if (status === window.WindowStatusType.FULL_SCREEN || status === window.WindowStatusType.MAXIMIZE) {
    mainWindow.setWindowDecorVisible(false);
    mainWindow.setWindowTitleButtonVisible(false, false, false);
    mainWindow.setTitleAndDockHoverShown(false, false).catch(() => {});
  } else if (status === window.WindowStatusType.FLOATING) {
    // 还原时恢复，避免回不到普通窗口
    mainWindow.setWindowDecorVisible(true);
    mainWindow.setWindowTitleButtonVisible(true, true, true);
  }
});
```

要点：
- 监听 `MAXIMIZE`（不是只听 `FULL_SCREEN`），因为系统按钮先进 MAXIMIZE。
- 调 `maximize(ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER)` 把 MAXIMIZE 切到 FULL_SCREEN，同时禁掉 hover 唤出。
- 再用 `setWindowDecorVisible(false)` + `setWindowTitleButtonVisible(false,false,false)` 双保险（部分机型 `maximize(沉浸)` 后三键 hover 仍可能出）。
- 回到 `FLOATING` 时主动恢复 decor 和三键，否则 `recover()` 后用户得到一个无边框无三键的浮动窗（无法拖动、无法系统关闭）。

#### 做法 B：点系统放大后**一定**保留标题栏和三键（MAXIMIZE）

系统默认就是这个行为。应用只需：
- **不要**在 `windowStatusChange` 里调 `maximize(ENTER_IMMERSIVE*)`；
- **不要**全局 `setWindowDecorVisible(false)` / `setWindowTitleButtonVisible(false,false,false)`（或在进入 MAXIMIZE 时主动设回 `true`）；
- 如果应用自己有放大按钮，调 `maximize(window.MaximizePresentation.EXIT_IMMERSIVE)` 或 `maximize(window.MaximizePresentation.FOLLOW_APP_IMMERSIVE_SETTING)`。

### 5. 还原后如何恢复标题栏和三键

`recover()` 只把窗口从全屏/最大化切回 `FLOATING`，**不会自动恢复**应用之前关掉的 decor 和三键。务必在状态回调里主动恢复（见做法 A 中 `FLOATING` 分支）。

## 十二、本轮追加未确认项

- 系统三键图标是否带常驻方形底色（仅确认悬停高亮态）：未确认；
- 普通最大化（非沉浸）是否存在顶部 hover 唤出热区：未确认；
- `MaximizePresentation` 完整枚举值：**已确认**——`FOLLOW_APP_IMMERSIVE_SETTING`(0) / `EXIT_IMMERSIVE`(1) / `ENTER_IMMERSIVE`(2) / `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER`(3, API 14+)；详见第十一节；
- PC 主窗整体透明（毛玻璃/透出桌面）的官方 API：未检索到，未确认。

## 十三、组合矩阵：窗口装饰 × 窗口模式 × 沉浸表现

先把概念拆成三个独立维度（互不自动联动，需分别配置）：

- **维度 1 窗口装饰**：`setWindowDecorVisible(true|false)`（标题栏显隐）+ `setWindowTitleButtonVisible(max,min,close)`（三键显隐）；
- **维度 2 窗口模式**：`WindowStatusType` = `FLOATING`（自由）/ `MAXIMIZE`（最大化）/ `FULL_SCREEN`（全屏）/ `SPLIT_SCREEN`（分屏）/ `MINIMIZE`。切换：`maximize(presentation?)`、`minimize()`、`recover()`、分屏由系统/用户触发；
- **维度 3 沉浸表现**：`setWindowLayoutFullScreen`（PC 5.1.1+ 不生效）、`setWindowSystemBarEnable`（PC 不生效）、`setTitleAndDockHoverShown`（全屏 hover 唤出）。

### 1. 「有边框全屏」vs「无边框全屏」视觉对比

| 元素 | 有边框全屏（decor=true） | 无边框全屏（decor=false） |
|---|---|---|
| 标题栏 | 显示（应用图标+名称） | 隐藏 |
| 三键 | 显示在标题栏右侧 | 默认隐藏（沉浸全屏下系统悬停可唤出；可 `setWindowTitleButtonVisible(false)` 彻底关） |
| 窗口圆角/边框/阴影 | 全屏下通常去圆角、无边框、无阴影 | 同左 |
| 系统状态栏 | `ENTER_IMMERSIVE` 下隐藏（可 hover 唤出） | 同左 |
| Dock/任务栏 | `ENTER_IMMERSIVE` 下隐藏（可 hover 唤出） | 同左 |
| 内容区 | 避让标题栏（不铺满到顶） | 铺满到顶 |

> **纠正**：PC 上点击**系统放大按钮**默认进 `MAXIMIZE`（保留标题栏/三键/Dock/状态栏），**不是**沉浸全屏。要进 `FULL_SCREEN`（隐藏标题栏/Dock）必须应用主动调 `maximize(ENTER_IMMERSIVE*)`，或在 `windowStatusChange` 监听到 `MAXIMIZE` 后再调 `maximize(ENTER_IMMERSIVE*)`。详见第十一节。

### 2. 系统放大按钮到底做什么

- **系统放大按钮默认进 `MAXIMIZE`（保留标题栏/三键/Dock/状态栏）**，依据：application-adaptation-freeform-window 原文"点击窗口最大化按钮，窗口默认以最大化显示，且不会自动隐藏标题栏、Dock 栏"；games-adapt-pc-platform 给出"监听 `MAXIMIZE` 后调 `maximize(ENTER_IMMERSIVE)` 才隐藏标题栏/Dock"的代码模式。
- `maximize()` API 的 `presentation` 默认 `ENTER_IMMERSIVE` 只对**应用主动调用**生效，**不等于**系统放大按钮的行为（上一版此处推断错误）。
- **应用不能拦截/重写系统三键点击**，没有 API 监听系统标题栏按钮事件。
- `maximizePresentation` / `MaximizeOptions.maximizePresentation` 只在应用主动调 `maximize()` / `maximizeWithOptions()` 时生效，**不影响系统按钮**。
- 应用能做的：在 `on('windowStatusChange')` 监听到进入 `MAXIMIZE` 后，**被动**调 `maximize(ENTER_IMMERSIVE*)` 切到 FULL_SCREEN，再配合 `setWindowDecorVisible` / `setWindowTitleButtonVisible` / `setTitleAndDockHoverShown`；`on('windowSizeChange')` 可配合做布局重排。
- 文档矛盾提示：window-mode-overview 的 FULL_SCREEN 触发方式里列了"用户点击系统标题栏中的最大化按钮"，与上述指南冲突；本报告以 application-adaptation-freeform-window + games-adapt-pc-platform 为准（与用户实测一致）。

### 3. 组合矩阵（行 = 装饰 × 模式）

| 装饰 \ 模式 | 自由窗口 FLOATING | 最大化 MAXIMIZE | 全屏沉浸 FULL_SCREEN |
|---|---|---|---|
| **有边框（decor=true，三键显）** | ✅ 默认态。标题栏+三键+圆角+阴影，状态栏/Dock 常驻。 | ✅ **系统放大按钮默认到这里**：铺满屏幕，保留标题栏+三键，状态栏/Dock 仍在（MAXIMIZE = 铺满屏幕有 dock 栏、状态栏和标题栏）。还原：`recover()`。 | ⚠️ 可达成但矛盾：`maximize(ENTER_IMMERSIVE)` 进全屏后又 `setWindowDecorVisible(true)`——三键/标题栏在全屏下由系统控制，强制显装饰**未确认是否生效**，不推荐。 |
| **无边框（decor=false，三键显）** | ✅ `setWindowDecorVisible(false)`，三键仍浮在右上角。内容铺到顶。系统状态栏/Dock 常驻。 | ⚠️ 系统放大 → MAXIMIZE 保留标题栏/Dock；若应用想隐藏，需在 `windowStatusChange` 里调 `maximize(ENTER_IMMERSIVE)` 切到 FULL_SCREEN。三键 hover 可唤出。 | ✅ 标准沉浸态。要禁 hover 唤出加 `setTitleAndDockHoverShown(false,false)`。 |
| **无边框+三键全隐（decor=false，三键隐）** | ✅ 纯自绘标题栏方案。内容铺满，无任何系统控件。状态栏/Dock 常驻。 | ✅ MAXIMIZE 下 `setWindowDecorVisible(false)` + `setWindowTitleButtonVisible(false,false,false)` 即可无边框无三键；若还要隐藏状态栏/Dock，需再 `maximize(ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER)` 切到 FULL_SCREEN。 | ✅ 同上，最彻底的沉浸。 |
| 分屏 SPLIT_SCREEN | 由系统/用户触发，通常显示标题栏+三键；`setWindowSystemBarEnable` 等在分屏下**不生效**。装饰状态沿用当前 decor 配置。 | — | — |

**还原路径（避免窗口卡死）**：`recover()` 只把窗口从全屏/最大化切回 `FLOATING`，**不恢复 decor 和三键**。务必在 `windowStatusChange` 回到 `FLOATING` 时主动 `setWindowDecorVisible(true)` + `setWindowTitleButtonVisible(true,true,true)`，否则用户会得到一个无边框无三键的浮动窗——无法拖动（除非自绘 `startMoving`）、无法通过系统三键关闭。

### 4. 重点：「有边框状态下点系统放大 → 直接无边框全屏」能否一步到位？

**不能一步到位，但可以确定性实现**。系统放大按钮默认进 `MAXIMIZE`（保留标题栏/Dock），应用无法拦截。要"点放大就无边框全屏"，必须在状态回调里把 `MAXIMIZE` 主动切到 `FULL_SCREEN`：

```ts
mainWindow.on('windowStatusChange', (status) => {
  if (status === window.WindowStatusType.MAXIMIZE) {
    // 系统放大进了 MAXIMIZE，主动切沉浸全屏
    mainWindow.maximize(window.MaximizePresentation.ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER)
      .catch(() => {});
  }
  if (status === window.WindowStatusType.FULL_SCREEN || status === window.WindowStatusType.MAXIMIZE) {
    mainWindow.setWindowDecorVisible(false);
    mainWindow.setWindowTitleButtonVisible(false, false, false);
    mainWindow.setTitleAndDockHoverShown(false, false).catch(() => {});
  } else if (status === window.WindowStatusType.FLOATING) {
    mainWindow.setWindowDecorVisible(true);              // 还原边框
    mainWindow.setWindowTitleButtonVisible(true, true, true); // 还原三键
  }
});
```

**潜在问题**：系统先按 MAXIMIZE 绘制，应用再调 `maximize(沉浸)`——视觉上通常同步，但个别机型可能出现一帧标题栏闪烁，**闪烁幅度未确认**，需实测。

### 5. 做不到 / 系统固定的组合

- ❌ 改变系统放大按钮的默认形态（无 API，系统按钮固定进 MAXIMIZE）；
- ❌ 拦截系统三键点击事件；
- ❌ 在全屏沉浸下强制显示系统标题栏（系统隐藏，应用无法强制拉回，`setWindowDecorVisible(true)` 在沉浸态下是否生效**未确认**）；
- ❌ PC 上用 `setWindowLayoutFullScreen` / `setWindowSystemBarEnable` 控制沉浸（5.1.1+ 不生效）；
- ❌ 通过 `module.json5` 配置让"点系统放大进沉浸"（`isMaximize` 只控制启动态，`supportWindowMode` 只控制支持范围，无 `maximizeMode` 之类字段）。

## 十四、本轮未确认项

- `WindowStatusType` 在 `maximize(ENTER_IMMERSIVE)` 后具体是 `FULL_SCREEN` 还是 `MAXIMIZE`：按文档"进入全屏模式"推断为 `FULL_SCREEN`，**未逐字核对**；
- 全屏沉浸下强制 `setWindowDecorVisible(true)` 是否生效：未确认；
- 监听 `windowStatusChange` 后再调 `maximize(ENTER_IMMERSIVE*)` 的视觉闪烁幅度：未确认，需真机实测；
- 系统放大按钮内部是否走 `FOLLOW_APP_IMMERSIVE_SETTING` 语义（即是否跟随应用此前的全屏设置）：官方未公开，**未确认/疑似**；这是"有时隐藏、有时不隐藏"的可能解释之一；
- 不同 API 版本 / 厂商 2in1 机型上系统放大按钮行为是否一致：window-faqs 明示部分 2in1 接口存在适配性问题，**未确认/疑似厂商适配**；
- ~~"有边框最大化"所需的 `MaximizePresentation` 取值~~：**已确认**——`EXIT_IMMERSIVE`(=1) 即"最大化时退出全屏模式"，对应 MAXIMIZE（保留标题栏/Dock）。完整枚举见第十一节。

## 十五、追加问题 E：沉浸全屏（无边框无三键）后，鼠标移到屏幕顶端，标题栏和三键还会出来吗？

简短结论：**取决于你用的是哪个 `MaximizePresentation`、有没有调 `setTitleAndDockHoverShown`、以及三键是否被单独隐藏。** `ENTER_IMMERSIVE` 默认 hover 会唤出；`ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER` 或 `setTitleAndDockHoverShown(false,false)` 则不会。

### 1. 两个沉浸枚举的悬停差异（已逐字核实，arkts-apis-window-e）

| 枚举 | 值 | 进入全屏后 hover 热区的表现 |
|---|---|---|
| `ENTER_IMMERSIVE` | 2 | 鼠标悬停热区上**显示**窗口标题栏和 Dock 栏 |
| `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER`（14+） | 3 | 鼠标悬停热区上**不显示**窗口标题栏和 Dock 栏 |

两者都会隐藏标题栏/三键/Dock（默认无 hover），**唯一区别是 hover 到顶部/底部热区时是否唤出**。

### 2. `setTitleAndDockHoverShown` 与 presentation 的关系（是否重复/冲突/谁优先）

`setTitleAndDockHoverShown(isTitleHoverShown?, isDockHoverShown?)`（API 14+，仅主窗/自由窗口，默认均为 true）也是控制"全屏模式下 hover 热区是否显示标题栏和 Dock"。

- **作用等价**：`ENTER_IMMERSIVE` ≈ `setTitleAndDockHoverShown(true, true)`；`ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER` ≈ `setTitleAndDockHoverShown(false, false)`。
- **不冲突，后者可覆盖前者**：window-faqs 原文——"当 `maximize()` 和 `setTitleAndDockHoverShown()` 接口都调用时，**以最后调用设置的效果为准**。"
- **所以**：用了 `ENTER_IMMERSIVE` 后又调 `setTitleAndDockHoverShown(false,false)`，最终 hover 不唤出；反之用 `_DISABLE_TITLE_AND_DOCK_HOVER` 后调 `setTitleAndDockHoverShown(true,true)`，最终 hover 会唤出。**以最后一次调用为准**。

### 3. 配合 `setWindowDecorVisible(false)` + `setWindowTitleButtonVisible(false,false,false)` 后，hover 还出什么？

要分三层看，三者控制的不是同一个东西：

| 控制项 | 控制对象 | 对 hover 唤出的影响 |
|---|---|---|
| `setWindowDecorVisible(false)` | 窗口标题栏（装饰）的常驻显隐 | 只决定"不 hover 时"标题栏是否显示；**不影响**全屏态 hover 热区是否唤出"悬浮标题栏" |
| `setWindowTitleButtonVisible(false,false,false)` | 右上角三键的显隐 | 三键被单独隐藏；hover 唤出的"悬浮标题栏"里**三键也不会出现**（三键显隐是独立状态） |
| `setTitleAndDockHoverShown(false,false)` / `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER` | hover 热区是否唤出标题栏/Dock | **直接决定 hover 时顶部那条悬浮标题栏出不出现** |

`setWindowDecorVisible` 文档原文："设置窗口标题栏不可见后，当主窗口进入**全屏沉浸状态**时，鼠标 Hover 到上方窗口标题栏热区上会显示**悬浮标题栏**。若想禁用悬浮标题栏显示，请使用 `setTitleAndDockHoverShown()` 接口。"

所以：
- **只设 `setWindowDecorVisible(false)` + 三键全隐，用 `ENTER_IMMERSIVE`**：hover 到顶部仍会出现一条**悬浮标题栏**（系统绘制的标题栏区域），但因为三键已被 `setWindowTitleButtonVisible(false,false,false)` 隐藏，这条悬浮栏里**没有三键**，只有标题栏本身（应用名/图标区域）。底部 hover 仍会唤出 Dock。
- **再设 `setTitleAndDockHoverShown(false,false)`（或直接用 `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER`）**：hover 顶部**完全不出现**悬浮标题栏，hover 底部也不出现 Dock。这才是真正"移上去也不出来"。

> 唤出的内容是**一整条悬浮标题栏**（系统标题栏区域，含应用图标+标题+三键区），不是只有一条细线；三键是否在其中由 `setWindowTitleButtonVisible` 决定。

### 4. 普通最大化（MAXIMIZE）vs 沉浸全屏（FULL_SCREEN）在这一点上的区别

| 模式 | 标题栏/三键默认状态 | hover 顶部热区 |
|---|---|---|
| **MAXIMIZE**（系统放大默认） | 标题栏+三键**常驻显示**（不需要 hover） | 无"悬停唤出"概念，本来就显示着 |
| **FULL_SCREEN / `ENTER_IMMERSIVE`** | 标题栏+三键+Dock 默认隐藏 | hover 唤出悬浮标题栏和 Dock |
| **FULL_SCREEN / `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER`** | 同上隐藏 | hover **不**唤出 |

### 5. 确定性组合：要"放大后无三键、且移上去也绝不出来"

```ts
// 方式一：一步到位（推荐）
mainWindow.maximize(window.MaximizePresentation.ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER);
mainWindow.setWindowDecorVisible(false);
mainWindow.setWindowTitleButtonVisible(false, false, false);

// 方式二：ENTER_IMMERSIVE + 显式关 hover（等价）
mainWindow.maximize(window.MaximizePresentation.ENTER_IMMERSIVE);
mainWindow.setTitleAndDockHoverShown(false, false);
mainWindow.setWindowDecorVisible(false);
mainWindow.setWindowTitleButtonVisible(false, false, false);
```

要点：
- `setWindowTitleButtonVisible(false,false,false)` 保证三键常驻不显示（包括 hover 唤出的悬浮标题栏里也没有三键）。
- `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER` 或 `setTitleAndDockHoverShown(false,false)` 保证连悬浮标题栏那条都不出现。
- `setWindowDecorVisible(false)` 保证非全屏态下也无边框（双保险）。

## 文档依据索引

| 文档 | 要点 |
|---|---|
| [窗口沉浸式（immersive-window-feature）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/immersive-window-feature) | 沉浸三方式；自由窗口用 `setWindowDecorVisible`；系统栏 API 自由窗口下不生效 |
| [窗口模式简介（window-mode-overview）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/window-mode-overview) | `WindowStatusType` 各模式定义；MAXIMIZE vs FULL_SCREEN 差异；`supportWindowMode` 配置优先级；FULL_SCREEN 触发方式含"用户点击最大化按钮"（与下条冲突） |
| [应用适配自由窗口（application-adaptation-freeform-window）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-adaptation-freeform-window) | **点击系统最大化按钮默认保留标题栏/Dock**，需应用调 `maximize()` 才进全屏；`getTitleButtonRect` 避让三键 |
| [窗口元数据配置（window-config-m）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/window-config-m) | `ohos.ability.window.isMaximize`、`ohos.ability.window.supportWindowModeInFreeMultiWindow` 等 metadata；无 `maximizeMode` 字段 |
| arkts-apis-window-window（Interface Window） | `maximize(presentation)` 默认 `ENTER_IMMERSIVE`；`maximizeWithOptions`(26.0.0)；`setWindowDecorVisible`/`setTitleAndDockHoverShown`/`setWindowTitleButtonVisible`/`startMoving`/`destroyWindow` 签名与设备差异 |
| arkts-apis-window-e（Enums） | `MaximizePresentation` 完整枚举：`FOLLOW_APP_IMMERSIVE_SETTING`(0)/`EXIT_IMMERSIVE`(1)/`ENTER_IMMERSIVE`(2)/`ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER`(3) |
| arkts-apis-window-i（Interfaces 其他） | `MaximizeOptions`(26.0.0)；`SubWindowOptions.decorEnabled` / `maximizeSupported` / `zLevelAboveParentLoosened` |
| window-faqs | MAXIMIZE = 铺满屏幕，有 Dock 栏和状态栏；部分 2in1 接口适配性问题 |
| [PC应用如何隐藏导航栏右上角三键（faqs-computer-7）](https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-computer-7) | onMouse + 定时静止检测 自实现悬停显隐 |
| [游戏适配PC平台（games-adapt-pc-platform）](https://developer.huawei.com/consumer/cn/doc/games-guides/games-adapt-pc-platform-0000002330261222) | 监听 `windowStatusChange`→`MAXIMIZE` 后调 `maximize(ENTER_IMMERSIVE)` 隐藏标题栏/Dock 的标准模式 |
| Immersive Title Bar in the Freeform Window（bpta-multi-device-window-immersive） | `setWindowDecorVisible(false)` 后仅保留右上角三键、内容延伸到标题栏区 |
| changelogs-targeting-api12-b031 | API 12 起 `setWindowSystemBarEnable`/`setSystemBarEnable` 在 PC/2in1 不生效 |
