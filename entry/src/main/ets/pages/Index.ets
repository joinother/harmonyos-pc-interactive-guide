import { WindowSandboxTab } from '../views/WindowSandboxTab';
import { NotificationTab } from '../views/NotificationTab';
import { LiveViewTab } from '../views/LiveViewTab';
import { OverlayTab } from '../views/OverlayTab';
import { SubWindowTab } from '../views/SubWindowTab';

@Entry
@Component
struct Index {
  build() {
    Tabs({ barPosition: BarPosition.Start }) {
      TabContent() {
        WindowSandboxTab()
      }
      .tabBar('窗口沙盘')
      TabContent() {
        NotificationTab()
      }
      .tabBar('通知中心')
      TabContent() {
        LiveViewTab()
      }
      .tabBar('实况窗')
      TabContent() {
        OverlayTab()
      }
      .tabBar('悬浮与透明')
      TabContent() {
        SubWindowTab()
      }
      .tabBar('子窗口')
    }
    .barMode(BarMode.Fixed)
    .vertical(false)
    .width('100%')
    .height('100%')
  }
}
