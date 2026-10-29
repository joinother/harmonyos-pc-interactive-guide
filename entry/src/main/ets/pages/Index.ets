import { WindowSandbox } from './WindowSandbox';
import { NotifyCenter } from './NotifyCenter';
import { LiveViewPage } from './LiveViewPage';
import { OverlayPage } from './OverlayPage';
import { SubWindowPage } from './SubWindowPage';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  private tabTitles: string[] = ['窗口沙盘', '通知中心', '实况窗', '悬浮与透明', '子窗口'];

  @Builder
  tabItem(idx: number, title: string) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(this.currentTab === idx ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTab === idx ? '#0A84FF' : '#8E8E93')
      Divider()
        .strokeWidth(2)
        .color(this.currentTab === idx ? '#0A84FF' : '#00000000')
        .margin({ top: 4 })
    }
    .padding({ left: 18, right: 18, top: 10 })
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() {
          WindowSandbox()
        }.tabBar(this.tabItem(0, this.tabTitles[0]))

        TabContent() {
          NotifyCenter()
        }.tabBar(this.tabItem(1, this.tabTitles[1]))

        TabContent() {
          LiveViewPage()
        }.tabBar(this.tabItem(2, this.tabTitles[2]))

        TabContent() {
          OverlayPage()
        }.tabBar(this.tabItem(3, this.tabTitles[3]))

        TabContent() {
          SubWindowPage()
        }.tabBar(this.tabItem(4, this.tabTitles[4]))
      }
      .barMode(BarMode.Fixed)
      .barBackgroundColor('#2C2C2E')
      .onChange((i: number) => {
        this.currentTab = i;
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
