# HarmonyOS PC（2in1）交互能力演示 —— PcShowcase

面向鸿蒙 PC（2in1 设备）的原生 ArkTS 演示工程， bundleName：`com.example.pcshowcase`，
五个顶部 Tab 逐一真实调用系统能力，所有调用结果（含错误码）直接显示在界面日志区，不做假实现。

## 功能模块

| Tab | 内容 | 真实性 |
|---|---|---|
| 窗口沙盘 | `setWindowDecorVisible`、`setWindowTitleButtonVisible`、`setTitleAndDockHoverShown`、`maximize(EXIT_IMMERSIVE / ENTER_IMMERSIVE / ENTER_IMMERSIVE_DISABLE_TITLE_AND_DOCK_HOVER)`、`recover()`、`minimize()`；隐藏装饰后顶部出现自绘三键栏（拖动=`startMoving()`、关闭=`terminateSelf()`） | 全部真实调用 |
| 通知中心 | `isNotificationEnabled`、`requestEnableNotification(context)` 弹系统授权框；基础文本 / 长文本 / 多行 / 大图（离线生成渐变 PixelMap，无网络）/ 进度条（downloadTemplate，先 `isSupportTemplate` 探测） | 全部真实调用；未授权时显示失败原因 |
| 实况窗 | 仅做 `canIUse` 探测并如实展示。SDK 26 无 `liveViewManager` / `@kit.LiveViewKit` 公开接口，`NotificationSystemLiveViewContent` 为系统应用专用 | 不支持，诚实标注，无假实现 |
| 悬浮与透明 | 应用内浮层（Stack + 半透明 + 圆角 + 阴影 + 可拖动 + 不透明度滑块）；系统级悬浮窗 `window.createWindow(TYPE_FLOAT)` 真实调用，三方无 `ohos.permission.SYSTEM_FLOAT_WINDOW` 时把错误码（预期 201）显示在日志 | 应用内真实；系统级真实调用但预期被拒 |
| 子窗口 | `createSubWindow`（API9）、`createSubWindowWithOptions`（API12）、独立子窗 `zLevelAboveParentLoosened`（API26 新增）、从属子窗 `setParentWindow`（API19）+ `setFollowParentWindowLayoutEnabled`（API17）、应用模态 `setSubWindowModal(true, APPLICATION_MODALITY)`（API14）、`startAbility` + `StartOptions.processMode`（API12，2in1/平板生效，手机 801） | 全部真实调用 |

子窗口内容页为 `pages/SubPage`：顶栏拖动（`startMoving()`），× 按钮自毁（`destroyWindow()`）。

## 构建

环境：macOS + DevEco Studio 26.0.0.851，SDK API 26。

```bash
export DEVECO_HOME=/Applications/DevEco-Studio.app/Contents
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export PATH="$DEVECO_HOME/tools/node/bin:$DEVECO_HOME/tools/hvigor/bin:$PATH"
hvigorw assembleHap
```

产物：`entry/build/default/outputs/default/entry-default-signed.hap`（配置签名后）。

## 签名

使用 DevEco Studio「自动生成签名」为本工程新生成的 debug 签名（不复用任何其他工程的证书）：

1. DevEco Studio 打开本工程
2. `File` → `Project Structure…` → `Project` → `Signing Configs`
3. 勾选 **Automatically generate signature**（需已登录华为账号）→ OK
4. DevEco 自动生成新的 `.p12/.cer/.p7b` 并写入 `build-profile.json5`

## 安装与启动

```bash
hdc install entry/build/default/outputs/default/entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.example.pcshowcase
```

## 设备支持情况（实测环境：HUAWEI MateBook Pro HAD-W32，2in1，API 26，HarmonyOS 7.0.0.111）

- 窗口沙盘全部 API：支持（API ≤ 14 的能力在本机均可调用）
- 通知五类 + 授权：支持；进度条以 `isSupportTemplate('downloadTemplate')` 实测为准
- 实况窗：不支持三方调用（探测结果见 App 内「实况窗」页）
- 应用内浮层：支持；系统悬浮窗：三方预期 201 权限拒绝
- 子窗口全部能力（含 API26 独立子窗）：本机 API26 可全部验证
