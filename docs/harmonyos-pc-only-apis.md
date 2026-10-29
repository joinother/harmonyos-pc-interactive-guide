# HarmonyOS（含 HarmonyOS NEXT / HarmonyOS PC）PC 端独有及窗口/菜单相关 API 调研报告

调研日期：2026-10-29
调研方法：通过 harmonyos_developer_knowledge MCP 检索华为官方开发文档（harmonyos-guides / harmonyos-references），逐条核对文档中的设备支持标记（phone / 2in1 / tablet / tv / wearable）与版本约束。所有结论均附文档依据；无法确认的已标注「未确认」。

> 术语说明：官方文档中 PC 形态的设备类型标记为 **2in1**（PC/2in1）。文档徽章格式如 `phone 12+ | 2in1 13+ | tablet 12+` 表示该 API 在对应设备上的起始支持版本。

---

## 一、结论摘要：真正的「PC 独有 / 仅 PC+平板」Top 项

按「官方明确仅 PC/2in1」到「API 支持 PC/2in1+平板但不含手机」排序：

| # | 能力 | 入口 | 设备范围 | 依据 |
|---|------|------|----------|------|
| 1 | **快捷栏（Dock）扩展**：自定义 Dock 图标右键菜单分组、窗口分组、图标、进度条 | DeskTopExtensionKit `quickBarManager` | **仅 PC/2in1 生效**（官方明示） | desktop-quickbar-extension-guide |
| 2 | **桌面/文件管理器右键扩展菜单**（"更多"菜单、"新建"菜单） | module.json5 `fileContextMenu` + profile 配置 | **仅 PC/2in1**（文档标题即标注） | right-click-menu |
| 3 | `Window.setWindowContainerModalColor()` 设置窗口容器焦点态/非焦点态背景色 | @kit.ArkUI window | **仅 2in1 26.0.0+**（无 phone/tablet 标记） | arkts-apis-window-window |
| 4 | `Window.restore()` 主窗口从最小化还原/抬升 | @kit.ArkUI window | **2in1 14+ \| tablet 14+，无 phone** | arkts-apis-window-window |
| 5 | `Window.setWindowContainerColor()` 窗口容器背景色（含标题栏区域） | @kit.ArkUI window | **2in1 20+ \| tablet 23+，无 phone** | arkts-apis-window-window |
| 6 | `Window.setWindowShadowEnabled()` 主窗口阴影开关 | @kit.ArkUI window | **2in1 20+ \| tablet 23+，无 phone** | arkts-apis-window-window |
| 7 | **自由窗口（free window）为默认窗口形态**，含标题栏+三键+边框拖拽缩放 | 系统行为 + 一批窗口装饰 API | PC/2in1 默认；部分平板需开"电脑模式/自由多窗"；部分手机仅"自由多窗" | freeform-window-overview |
| 8 | 反向案例：`setGestureBackEnabled()`（手势返回）**不支持 2in1** | @kit.ArkUI window | phone 13+ \| tablet 13+ \| tv \| wearable（无 2in1） | arkts-apis-window-window |

**重要判断原则**：@ohos.window 大量接口（maximize/minimize/setWindowDecorVisible 等）的设备徽章包含 phone/tablet，但描述写明「**对存在标题栏和三键区的窗口形态生效**」或「自由窗口状态下生效」——即手机上能调通但无实际窗口装饰语义。这类属于「**能用但形态不同**」，不算严格独有，详见第四节对照清单。

---

## 二、菜单相关

### 2.1 真正的 PC 独有菜单能力

#### 1) 快捷栏（Dock）应用图标右键菜单 —— 仅 PC/2in1
- **API/组件**：`quickBarManager`（`@kit.DeskTopExtensionKit`，模块 `@hms.pcService.quickBarManager`）
- **所属 Kit**：Desktop Extension Kit
- **支持设备**：官方明示「Desktop Extension Kit 相关 API **仅在 PC/2in1 设备上生效**」
- **关键接口与版本门槛**：
  - 菜单分组（右键菜单自定义分组/任务项）：API 6.0.2(22) 起 —— `getCustomCategories / addCustomCategory / updateCustomCategory / deleteCustomCategory / getTasksFromCategory / addQuickTask / updateQuickTask / deleteQuickTask`
  - 窗口分组：API 6.1.0(23) 起 —— `addQuickBarGroup / deleteQuickBarGroup / getQuickBarGroups / setWindowToGroup`
  - 图标与进度条、能力查询：API 26.0.0 起 —— `setQuickBarCombineIcon / setQuickBarLayeredIcon / setProgressState / setProgressValue / isQuickBarCapabilitySupported`
- **关键说明**：快捷栏指 PC/2in1 屏幕底部图标区域（Dock）。应用可为 Dock 图标右键菜单添加分组与任务项（点击后拉起指定 Ability），还可把窗口归组、设置融合/分层图标与下载进度条。使用前应调 `isQuickBarCapabilitySupported()` 判断。
- **依据**：[应用接入快捷栏](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/desktop-quickbar-extension-guide)（desktop-quickbar-extension-guide）；接口文档 desktop-quickbar-extension-manager

#### 2) 桌面/文件管理器右键扩展菜单 —— 仅 PC/2in1
- **API/组件**：module.json5 的 `fileContextMenu` 字段 + `resources/base/profile` 下菜单配置文件（声明式配置，非运行时 API）
- **所属 Kit**：Ability Kit（配置属于应用框架）
- **支持设备**：文档标题即「配置应用右键扩展菜单（PC/2in1）」
- **关键说明**：
  - 「更多」菜单：根节点 `fileContextMenu`，含 `abilityName / menuItem / menuHandler / menuContext`（触发场景 menuKind：空白处/文件/文件夹；单选多选 menuRule；文件类型过滤 fileSupportType 等）。单模块/单应用最多 10 个。用户点击后经 `startAbility` 拉起应用，want 中携带 `menuHandler` 与 `uriList`。
  - 「新建」菜单：根节点 `newFile`（menuName/menuIcon/fileType/fileContent 模板），最多 5 个，如"新建文本文档.txt"。
  - 仅支持在 entry 类型模块中配置。
  - **权限标注**：自定义菜单图标 `menuIcon`（API 23 起）需申请 `ohos.permission.CUSTOMIZE_MENU_ICON`，未授权则不显示自定义图标。其余为基础三方应用能力，非系统应用专属。
  - API 24 起支持三方网盘场景标签（ignoreActiveStatus、fileSupportSyncStatus）。
- **依据**：[配置应用右键扩展菜单（PC/2in1）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/right-click-menu)（right-click-menu）

### 2.2 菜单相关但**非** PC 独有（容易误判）

| API/组件 | 设备支持 | 说明 | 依据 |
|---|---|---|---|
| `Menu` / `MenuItem` / `MenuItemGroup` 组件（ArkUI） | phone 12+ \| 2in1 13+ \| tablet 12+ \| tv 19+ \| wearable 18+ | 全设备；支持多级子菜单（subMenuBuilder）、`labelInfo` 可标注如 Ctrl+C 快捷键提示 | ts-basic-components-menu |
| `bindMenu` / `bindContextMenu`（通用属性） | phone 12+ \| 2in1 13+ \| tablet 12+ \| tv 19+ \| wearable 18+ | 全设备。`bindContextMenu` 触发方式为长按或**鼠标右键**；弹出的菜单在独立子窗口内，**可显示在应用窗口外**（PC 上体验完整）；API 23 起有 `bindContextMenuWithResponse`，26.0.0 起 `bindContextMenuByResponseType` / `bindContextMenuByIsShow` | ts-universal-attributes-menu |
| 菜单中轴避让（hover mode） | **2in1 上默认启用**（API 20 起，且窗口处于瀑布模式时） | `ContextMenuOptions.enableHoverMode` 控制；这是 2in1 上的差异化默认行为，但 API 本身全设备 | arkts-popup-and-menu-components-menu |
| `keyboardShortcut`（组件快捷键） | phone 12+ \| 2in1 13+ \| tablet 12+ \| tv 19+ \| wearable 18+ | **非 PC 独有**，但实际依赖物理键盘，主要价值在 PC/平板。支持 Ctrl/Shift/Alt+字符或 FunctionKey；禁止绑定系统快捷键（Alt+F4、Alt+TAB、Ctrl+Shift+ESC 等）；窗口获焦即响应，组件无需获焦 | ts-universal-events-keyboardshortcut |
| Navigation `menus` / NavDestination `menus`（页面菜单栏） | 全设备 | 这是"页面右上角菜单栏"，**不是** PC 桌面式应用菜单栏；竖屏最多 3 图标、横屏 5 图标 | arkts-navigation-architecture |
| 「MenuBar」桌面式顶部菜单栏组件 | **未确认存在** | 在官方 ArkUI 文档中未检索到名为 MenuBar 的组件；PC 上窗口顶部为系统标题栏（含应用图标+名称+三键），三方应用无"系统级应用菜单栏"API。如未来版本新增请以官方文档为准 | 检索自 harmonyos-references |

---

## 三、窗口相关

### 3.1 自由窗口形态（PC 默认，手机/平板默认没有）

- **结论**：自由窗口（free window）本身不是"API"，而是窗口状态。**PC/2in1 设备上窗口默认为自由窗口**；部分 Tablet 需开启"自由多窗"或"电脑模式"；部分 Phone 仅支持"自由多窗"。自由窗口默认带标题栏（应用图标+应用名+三键：最大化/还原、最小化、关闭），支持拖边缘缩放、拖标题栏移动、Z 轴层叠。
- **检测接口**：`Window.isInFreeWindowMode()`、`on('freeWindowModeChange')` / `off('freeWindowModeChange')` —— API 22 起，徽章为全设备（phone/2in1/tablet/tv/wearable 22+），但只有在自由窗口形态下才有意义。
- **依据**：[自由窗口简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/freeform-window-overview)（freeform-window-overview）、[应用适配自由窗口](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-adaptation-freeform-window)（application-adaptation-freeform-window）

### 3.2 严格设备范围受限的窗口 API（徽章不含 phone）

| API | 起始版本与设备 | 功能 | 依据 |
|---|---|---|---|
| `Window.restore()` | **2in1 14+ \| tablet 14+**（无 phone） | 主窗口从最小化还原到前台并恢复大小位置；前台时仅抬升层级 | arkts-apis-window-window |
| `Window.setWindowContainerColor(activeColor, inactiveColor)` | **2in1 20+ \| tablet 23+**（无 phone） | 设置窗口容器焦点态/非焦点态背景色，覆盖标题栏+内容区域 | arkts-apis-window-window |
| `Window.setWindowShadowEnabled(enable)` | **2in1 20+ \| tablet 23+**（无 phone） | 主窗口是否显示阴影（默认显示） | arkts-apis-window-window |
| `Window.setWindowContainerModalColor(activeColor, inactiveColor)` | **仅 2in1 26.0.0+**（无 phone/tablet） | 设置主窗口容器（模态场景）焦点态/非焦点态背景色 | arkts-apis-window-window |

### 3.3 窗口装饰（标题栏/三键）相关 API —— 徽章含 phone，但语义仅对"存在标题栏和三键区的窗口形态"生效

以下均属 @kit.ArkUI（window 模块，`SystemCapability.Window.SessionManager`），普通三方应用可用：

| API | 版本/设备徽章 | 关键说明 |
|---|---|---|
| `setWindowDecorVisible(isVisible)` | 11+（phone 12+/2in1 13+/tablet 12+） | 显示/隐藏窗口标题栏；隐藏后进入全屏沉浸时鼠标 hover 顶部热区可显示悬浮标题栏（可用 `setTitleAndDockHoverShown` 禁用） |
| `setWindowDecorHeight(height)` / `getWindowDecorHeight()` | 11+ | 设置/获取标题栏高度（vp）；悬浮标题栏高度固定 37vp |
| `getTitleButtonRect()` / `on('windowTitleButtonRectChange')` | 11+ | 获取/监听标题栏上最小化、最大化、关闭按钮的矩形区域，用于自绘顶部区域时避让三键 |
| `setWindowTitleButtonVisible(max, min, close?)` | 14+ | 控制三键各自可见性；**仅支持主窗和独立子窗**，其他窗口返回 1300004 |
| `setWindowTitle(titleName)` | 15+ | 设置窗口标题 |
| `setWindowTitleMoveEnabled(enabled)` | 14+ | 禁止/使能标题栏默认拖拽移动与双击最大化；禁用后可用 `startMoving()` + `maximize()` 自实现 |
| `setTitleAndDockHoverShown(isTitleHoverShown?, isDockHoverShown?)` | 14+ | 全屏模式下鼠标 hover 热区是否显示标题栏和 **Dock 栏**（Dock 为 PC 概念） |
| `maximize(presentation?: MaximizePresentation)` | 12+ | 主窗口最大化；子窗口需创建时 `maximizeSupported: true`。PC 上最大化默认铺满屏幕但保留 Dock 栏和状态栏；传 `ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER` 等可进入沉浸全屏（视频/PPT 场景） |
| `maximizeWithOptions(options?)` | 26.0.0 | 最大化并配置布局策略/折叠屏跨屏策略/截图动画 |
| `minimize()` | 11+ | 主窗口最小化，可在多任务还原，**PC/2in1 上可通过 Dock 栏或 `restore()` 还原** |
| `recover()` | 11+ | 主窗口从全屏/最大化/分屏还原为自由悬浮窗口（FLOATING）并恢复之前大小位置 |
| `setResizeByDragEnabled(enable)` | 14+ | 禁止/使能拖拽边缘缩放主窗口或带标题栏子窗口（子窗口需 `decorEnabled: true`） |
| `startMoving()` / `stopMoving()` | 14+ | 在 onTouch(TouchType.Down) 中调发起窗口拖拽移动；自由窗口状态下主窗口可用，非自由窗口状态主窗口调用返回 801/1300004 |
| `setWindowTopmost(isWindowTopmost)` | 14+ | 主窗口置顶（不被其他应用窗口遮挡）；可配合自定义快捷键切换 |
| `setAspectRatio(ratio)` / `resetAspectRatio()` / `setContentAspectRatio()`（21+） | 10+ | 设置窗口内容布局宽高比（自由窗口下生效） |
| `setWindowLimits(windowLimits)` / `getWindowLimits()` / `getWindowLimitsVP()`（22+） | 11+ | 限制自由窗口最大/最小尺寸；与 StartOptions、module.json5（maxWindowWidth 等）、系统默认限制取交集 |
| `on('windowStatusChange')` | 11+ | 监听窗口模式变化（WindowStatusType：FULLSCREEN/MAXIMIZE/MINIMIZE/FLOATING/SPLIT_SCREEN） |

依据：[Interface (Window)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-window-window)（arkts-apis-window-window）、[应用适配自由窗口](application-adaptation-freeform-window)、[窗口开发常见问题](window-faqs)、[窗口模式简介](window-mode-overview)

### 3.4 子窗口 / 多窗口 / windowStage 在 PC 的特殊行为

- **`WindowStage.createSubWindowWithOptions(name, options: SubWindowOptions)`**（API 11+，全设备徽章）：
  - `SubWindowOptions` 含 `title`（子窗口标题）、`decorEnabled`（是否开启标题栏）、`isModal`（是否模态）、`maximizeSupported`（是否支持最大化）、`zLevelAboveParentLoosened`（为 true 时创建**独立子窗**）。
  - **PC 差异**：自由窗口状态下 `decorEnabled: true` 的子窗口带标题栏（非沉浸式）；非自由窗口状态下子窗口无标题栏、默认沉浸式。即"带装饰的子窗口"只在自由窗口形态（PC 默认）成立。
- **`WindowStage.setSupportedWindowModes()`**（15+，phone/2in1/tablet）：动态设置主/子窗口支持的窗口模式（FULL_SCREEN/FLOATING/SPLIT 等）；配合 module.json5 的 `supportWindowMode`、`metadata` 中 `ohos.ability.window.isMaximize=true` 可让主窗口以 MAXIMIZE 模式启动（仅自由窗口状态下存在该模式）。
- **windowStage 生命周期**：`on('windowStageClose')`（14+，phone/2in1/tablet）可监听 PC 上点关闭键销毁窗口等事件；WindowStage 接口整体全设备，无 PC 独有接口。
- **StartOptions**：`minWindowWidth/minWindowHeight/maxWindowWidth/maxWindowHeight`（vp）在 `startAbility` 时限制目标主窗口尺寸——面向自由窗口场景。
- 依据：[Interface (WindowStage)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-window-windowstage)（arkts-apis-window-windowstage）、[窗口类型开发概述](window-type-overview)、[窗口模式简介](window-mode-overview)、[配置启动参数](application-startup-options)

### 3.5 悬浮类窗口（闪控球/闪控窗/画中画）

| 能力 | 设备范围 | 说明 | 依据 |
|---|---|---|---|
| `@ohos.window.floatView`（闪控窗） | 26.0.0+，徽章全设备 | 悬浮在桌面/应用界面上的小窗口；`isFloatViewEnabled` 判断是否支持 | js-apis-floatview |
| `@ohos.window.floatingBall`（闪控球） | 20+。**HarmonyOS 7.0.0 之前**：仅 Phone、Tablet（非电脑模式）；**7.0.0 起**：Phone + PC/2in1 + Tablet | 需 `ohos.permission.USE_FLOAT_BALL` 权限；`restoreMainWindow` 在点击闪控球后调用（有 `ohos.permission.AUTO_RESTORE_MAIN_WINDOW` 可免点击）。**注意权限为受限权限，普通三方应用上架需申请 ACL，非完全自由可用** | js-apis-floatingball |
| PiPWindow（画中画） | 全设备 | 视频场景，非 PC 独有 | js-apis-pipwindow |

### 3.6 PC 上不生效的窗口 API（反向注意）

- `setWindowSystemBarEnable()` / `setSystemBarEnable()`：**API 12 起在 PC/2in1 上不生效**（全屏下状态栏显隐由系统布局约束）。
- `setGestureBackEnabled()`：徽章为 phone 13+ | tablet 13+ | tv | wearable，**不含 2in1**（PC 无手势返回）。
- 依据：changelogs-targeting-api12-b031；arkts-apis-window-window

---

## 四、「其他 PC 相关能力」（与菜单/窗口强相关的简列）

| 能力 | API/入口 | 设备支持 | 说明 | 依据 |
|---|---|---|---|---|
| 鼠标/触控板事件 | `onMouse`、`onHover`（通用事件） | 徽章全设备（phone 12+/2in1 13+…） | API 非独有，但仅在外接鼠标/触控板时触发；可获取按键（左/右/中/前进/后退）、坐标、悬浮状态 | ts-universal-mouse-key、arkts-interaction-development-guide-mouse |
| 指针（光标）样式 | `@ohos.multimodalInput.pointer` `setPointerStyle(windowId, pointerStyle)`；ArkUI 侧 `UIContext.getCursorController().setCursor()` / `cursorControl` | 实际面向有指针的设备（PC/平板外接鼠标）；逐设备徽章未逐一确认，**标注：未确认** | 设置本应用进程内窗口的鼠标样式（PointerStyle 枚举） | pointerstyle-guidelines、js-apis-pointer、ts-universal-attributes-cursor |
| 统一拖拽（含文件拖入） | `onDragStart` / `onDrop` / `draggable` 等 | 徽章全设备 | 框架跨设备；**PC 上的跨窗口拖拽、从桌面/文件管理器拖文件进应用窗口**是典型 PC 场景（与右键菜单、Dock 构成 PC 文件操作闭环） | ts-universal-events-drag-drop、arkts-common-events-drag-event |
| 键盘事件 | `onKeyEvent` / `onKeyPreIme` / `keyboardShortcut` | 全设备 | 见 2.2；PC 上为主力输入方式 | ts-universal-events-key、ts-universal-events-keyboardshortcut |
| Dock 栏 / 任务栏 | 系统 UI，三方不可控；仅可通过 quickBarManager 扩展**自己应用**的 Dock 图标 | 仅 PC/2in1 | 无"系统托盘（system tray）图标"三方 API：**未确认存在**；设计规范中 PC 状态栏（屏幕底部）支持系统应用功能图标，未检索到三方接入 API | desktop-quickbar-extension-guide、design-guides/statusbar |
| 音频输入设备切换 | Audio Kit | PC/2in1 场景文档 | PC/2in1 常有多路输入设备，应用可按应用级/流级指定输入设备 | audio-input-device-switcher |

---

## 五、对照清单：手机/平板"也有但 PC 表现不同"（避免误判为独有）

| 能力 | phone/tablet | PC/2in1 差异 |
|---|---|---|
| 自由窗口 | 部分手机/平板需手动开"自由多窗"；部分平板有"电脑模式" | **默认即是自由窗口**；标题栏/三键/边框拖拽常驻 |
| `bindContextMenu` | 长按触发为主 | 右键触发为主；菜单在独立子窗口，可越出应用窗口边界 |
| `keyboardShortcut` / `onKeyEvent` | 需外接键盘，少用 | 主力交互；系统级快捷键（Alt+F4 等）禁止占用 |
| `onMouse` / `onHover` | 仅外接鼠标时触发 | 常驻；右键、中键、侧键可用 |
| `maximize/minimize/recover` 等窗口控制 | 可调但无窗口装饰语义（手机无标题栏） | 对应真实标题栏三键与 Dock 还原 |
| 画中画/悬浮窗 | 有 | 有，且 7.0.0 起闪控球扩展到 PC |
| `setWindowSystemBarEnable` | 控制状态栏有效 | **不生效**（API 12 起） |
| `setGestureBackEnabled` | 有效 | **不支持 2in1** |
| 拖拽 | 长按拖拽 | 鼠标拖拽、跨窗口/桌面文件拖拽 |

---

## 六、权限/系统级限制标注

- `ohos.permission.CUSTOMIZE_MENU_ICON`：右键扩展菜单自定义图标所需（API 23+），普通应用可申请。
- `ohos.permission.USE_FLOAT_BALL`、`ohos.permission.AUTO_RESTORE_MAIN_WINDOW`：闪控球相关，属受限权限，三方应用需走 ACL 申请，非普遍可用。
- 系统托盘图标、全局菜单栏（macOS 式 MenuBar）：未检索到三方 API，**仅系统应用/系统 UI 可用（未确认有三方开放计划）**。
- 窗口装饰（标题栏、三键、边框）本身由系统绘制，应用只能通过上述 API 配置，不能自绘系统三键。

## 附：主要文档依据索引

| 文档 ID | 标题 |
|---|---|
| harmonyos-guides/desktop-quickbar-extension-guide | 应用接入快捷栏 |
| harmonyos-guides/right-click-menu | 配置应用右键扩展菜单（PC/2in1） |
| harmonyos-references/arkts-apis-window-window | Interface (Window) |
| harmonyos-references/arkts-apis-window-windowstage | Interface (WindowStage) |
| harmonyos-guides/freeform-window-overview | 自由窗口简介 |
| harmonyos-guides/application-adaptation-freeform-window | 应用适配自由窗口 |
| harmonyos-guides/window-mode-overview / window-type-overview / window-faqs | 窗口模式/类型/常见问题 |
| harmonyos-references/ts-basic-components-menu / ts-universal-attributes-menu | Menu 组件 / 菜单通用属性 |
| harmonyos-references/ts-universal-events-keyboardshortcut / ts-universal-mouse-key | 快捷键 / 鼠标事件 |
| harmonyos-references/js-apis-floatview / js-apis-floatingball | 闪控窗 / 闪控球 |
| harmonyos-releases/changelogs-targeting-api12-b031 | PC/2in1 上状态栏接口不生效变更 |
