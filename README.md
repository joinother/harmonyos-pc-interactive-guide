# HarmonyOS PC（2in1）交互能力演示 —— PcShowcase

面向鸿蒙 PC（2in1）的原生 ArkTS 演示工程，bundleName：`com.example.pcshowcase`。
六个顶部 Tab 逐一**真实调用**系统能力，调用结果与错误码直接显示在界面日志区；不支持的特性如实标注，不做假实现。

实测设备：HUAWEI MateBook Pro（HAD-W32，HarmonyOS 7.0.0.111，API 26，2in1）。

## 功能模块与实测结果（本机）

| Tab | 内容 | 实测 |
|---|---|---|
| 窗口沙盘 | `setWindowDecorVisible` / `setWindowTitleButtonVisible` / `setTitleAndDockHoverShown` / `maximize(EXIT_IMMERSIVE · ENTER_IMMERSIVE · ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER)` / `recover()` / `minimize()`；隐藏装饰后自绘三键栏（`startMoving()` 拖动、`terminateSelf()` 关闭） | ✅ 全部可用 |
| 通知中心 | `isNotificationEnabled` / `requestEnableNotification`；基础文本 / 长文本 / 多行 / 大图（离线生成渐变 PixelMap，无网络）/ 进度条（downloadTemplate） | ✅ 全部可用（截图已见系统通知中心展示） |
| 实况窗 | SDK 26 公开接口中无 `liveViewManager` / `@kit.LiveViewKit`；页面做 `canIUse` 探测并如实说明 | ❌ 本版本不支持（诚实标注） |
| 悬浮与透明 | 应用内浮层（Stack + 半透明 + 圆角 + 可拖动 + 不透明度滑块）；系统级悬浮窗说明权限限制 | ✅ 应用内可用；系统级三方受限 |
| 子窗口 | 五种窗口形态，见下表 | 见下表 |
| 鼠标样式 | `getCursorController().setCursor` 遍历 `pointer.PointerStyle` 全部 52 个命名样式（49-51 激光类仅手写笔空中鼠标，点击时如实提示未调用）；`setCustomCursor` 加载 `rawfile/cursor_star.png` 自定义光标；`restoreDefault()` 恢复；`pointer.setPointerVisible(false)` 隐藏系统光标 + `onMouse` 旋转跟随图层（动画光标对照方案） | 代码真实调用，结果见日志区 |

### 子窗口五种形态实测（API 26 · 2in1）

| 形态 | API | 实测结果 |
|---|---|---|
| ① 独立子窗（非模态、不跟随） | `windowStage.createSubWindowWithOptions({ title, decorEnabled: true, zLevelAboveParentLoosened: true, maximizeSupported: true })`（26.0.0+） | ✅ 成功：独立系统标题栏三键，可拖出主窗范围，不随主窗前后台切换 |
| ② 从属子窗（跟随主窗） | `createSubWindow()`（9+）+ `setFollowParentWindowLayoutEnabled(true)`（17+） | ✅ 创建成功；主窗 `minimize()` 后从属子窗跟随隐藏（窗口列表消失）；主窗恢复前台后从属子窗**不自动恢复**，需重建。「最小化精确跟随」以真机实测为准 |
| ③ 模态对话框 | 窗口层：`isModal` 创建参数 + `setSubWindowModal(true, WINDOW_MODALITY / APPLICATION_MODALITY)`（12+/14+）；UI 层对照：`CustomDialogController` | ✅ 两种窗口模态均成功，父窗/应用被锁定；UI 层对照为页内遮罩弹窗，语义不同。已知现象：子窗被系统三键 ✕ 关闭后，应用内缓存的句柄失效，再次 `destroyWindow` 返回 `1300002`（界面如实显示） |
| ④ 外部应用 | `startAbility` 拉起 `com.huawei.hmos.settings.MainAbility` / `com.huawei.hmos.filemanager.MainAbility` | ✅ 均成功拉起（独立进程、独立窗口） |
| ⑤ 同应用新进程 | `startAbility(want, { processMode: NEW_PROCESS_ATTACH_TO_PARENT, startupVisibility: STARTUP_SHOW })` 拉起本应用 `SecondAbility` | ✅ 成功：`ps -ef` 可见第二个进程 `com.example.pcshowcase…:entry:SecondAbility:1`。**注意：`processMode` 与 `startupVisibility` 必须成对设置，否则同步抛 401**（本工程已修复并加 try-catch）。仅 2in1/平板生效，手机返回 801 |

## 构建

环境：macOS + DevEco Studio（内置 SDK 26.0.0）。

```bash
export DEVECO_HOME=/Applications/DevEco-Studio.app/Contents
export DEVECO_SDK_HOME="$DEVECO_HOME/sdk"
"$DEVECO_HOME/tools/hvigor/bin/hvigorw" assembleHap
```

产物：`entry/build/default/outputs/default/entry-default-signed.hap`（配置签名后）。

## 签名（重要）

本仓库**不包含任何签名材料**（`.certs/`、`build-profile.json5` 中的 signingConfigs 已脱敏）。请为本工程生成全新 debug 签名，不要复用其他工程的证书：

1. 用 DevEco Studio 打开本工程
2. `File` → `Project Structure…` → `Project` → `Signing Configs`
3. 勾选 **Automatically generate signature**（需登录华为账号，设备已注册）→ OK
4. DevEco 自动生成新的 `.p12/.cer/.p7b` 并写入 `build-profile.json5`

## 安装与启动

```bash
hdc install entry/build/default/outputs/default/entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.example.pcshowcase
hdc shell snapshot_display -f /data/local/tmp/shot.jpeg   # 截图验证
```

## 目录

- `entry/src/main/ets/pages/` —— 五个 Tab 页面 + `Second.ets`（SecondAbility 页面）+ `sub/`（子窗内容页）
- `entry/src/main/ets/secondability/SecondAbility.ets` —— 同应用新进程演示用的第二个 UIAbility
- `docs/harmonyos-pc-visual-guide.html` —— 配套的鸿蒙 PC 交互可视化指南（浏览器打开）
- `docs/*.md` —— 调研笔记（子窗口形态 / 沉浸式 API / PC 独有 API）

## 真实 API vs 模拟/不支持

- **真实调用**：窗口沙盘全部按钮、五种通知、子窗口五种形态、应用内浮层。
- **诚实标注不支持**：实况窗（SDK 26 无公开 API）；系统级悬浮窗（三方应用无 `SYSTEM_FLOAT_WINDOW` 权限，仅说明不强行实现）。
- 所有系统 API 调用均 try-catch，失败时把 `code` 与 `message` 显示在页面日志区（含同步抛出的 401 参数错误）。
