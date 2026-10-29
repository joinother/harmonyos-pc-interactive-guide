import { pointer } from '@kit.InputKit';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SectionHeader, LogView, errText, nowStr } from '../common/Kit';

class PointerItem {
  id: number = 0;
  name: string = '';
  style: pointer.PointerStyle = pointer.PointerStyle.DEFAULT;
  since: string = '9';
  direct: boolean = true;
}

function mk(id: number, name: string, style: pointer.PointerStyle, since: string, direct: boolean): PointerItem {
  const it = new PointerItem();
  it.id = id;
  it.name = name;
  it.style = style;
  it.since = since;
  it.direct = direct;
  return it;
}

/**
 * 鼠标样式：pointer.PointerStyle 全量命名样式逐个真实切换（getCursorController().setCursor），
 * 外加 setCustomCursor 自定义图片光标与 setPointerVisible 隐藏系统光标做跟随图层对照。
 * 结果（含错误码）全部写入下方日志，不做假实现。
 */
@Component
export struct MouseStylePage {
  @State logs: string[] = [];
  @State current: string = '未设置';
  @State demoRunning: boolean = false;
  @State followX: number = 100;
  @State followY: number = 60;
  @State rotAngle: number = 0;
  private timerId: number = -1;

  private items: PointerItem[] = [
    mk(0, 'DEFAULT', pointer.PointerStyle.DEFAULT, '9', true),
    mk(1, 'EAST', pointer.PointerStyle.EAST, '9', true),
    mk(2, 'WEST', pointer.PointerStyle.WEST, '9', true),
    mk(3, 'SOUTH', pointer.PointerStyle.SOUTH, '9', true),
    mk(4, 'NORTH', pointer.PointerStyle.NORTH, '9', true),
    mk(5, 'WEST_EAST', pointer.PointerStyle.WEST_EAST, '9', true),
    mk(6, 'NORTH_SOUTH', pointer.PointerStyle.NORTH_SOUTH, '9', true),
    mk(7, 'NORTH_EAST', pointer.PointerStyle.NORTH_EAST, '9', true),
    mk(8, 'NORTH_WEST', pointer.PointerStyle.NORTH_WEST, '9', true),
    mk(9, 'SOUTH_EAST', pointer.PointerStyle.SOUTH_EAST, '9', true),
    mk(10, 'SOUTH_WEST', pointer.PointerStyle.SOUTH_WEST, '9', true),
    mk(11, 'NE_SW', pointer.PointerStyle.NORTH_EAST_SOUTH_WEST, '9', true),
    mk(12, 'NW_SE', pointer.PointerStyle.NORTH_WEST_SOUTH_EAST, '9', true),
    mk(13, 'CROSS', pointer.PointerStyle.CROSS, '9', true),
    mk(14, 'CURSOR_COPY', pointer.PointerStyle.CURSOR_COPY, '9', true),
    mk(15, 'CURSOR_FORBID', pointer.PointerStyle.CURSOR_FORBID, '9', true),
    mk(16, 'COLOR_SUCKER', pointer.PointerStyle.COLOR_SUCKER, '9', true),
    mk(17, 'HAND_GRABBING', pointer.PointerStyle.HAND_GRABBING, '9', true),
    mk(18, 'HAND_OPEN', pointer.PointerStyle.HAND_OPEN, '9', true),
    mk(19, 'HAND_POINTING', pointer.PointerStyle.HAND_POINTING, '9', true),
    mk(20, 'HELP', pointer.PointerStyle.HELP, '9', true),
    mk(21, 'MOVE', pointer.PointerStyle.MOVE, '9', true),
    mk(22, 'RESIZE_L_R', pointer.PointerStyle.RESIZE_LEFT_RIGHT, '9', true),
    mk(23, 'RESIZE_U_D', pointer.PointerStyle.RESIZE_UP_DOWN, '9', true),
    mk(24, 'SHOT_CHOOSE', pointer.PointerStyle.SCREENSHOT_CHOOSE, '9', true),
    mk(25, 'SHOT_CURSOR', pointer.PointerStyle.SCREENSHOT_CURSOR, '9', true),
    mk(26, 'TEXT_CURSOR', pointer.PointerStyle.TEXT_CURSOR, '9', true),
    mk(27, 'ZOOM_IN', pointer.PointerStyle.ZOOM_IN, '9', true),
    mk(28, 'ZOOM_OUT', pointer.PointerStyle.ZOOM_OUT, '9', true),
    mk(29, 'MB_EAST', pointer.PointerStyle.MIDDLE_BTN_EAST, '9', true),
    mk(30, 'MB_WEST', pointer.PointerStyle.MIDDLE_BTN_WEST, '9', true),
    mk(31, 'MB_SOUTH', pointer.PointerStyle.MIDDLE_BTN_SOUTH, '9', true),
    mk(32, 'MB_NORTH', pointer.PointerStyle.MIDDLE_BTN_NORTH, '9', true),
    mk(33, 'MB_N_S', pointer.PointerStyle.MIDDLE_BTN_NORTH_SOUTH, '9', true),
    mk(34, 'MB_NE', pointer.PointerStyle.MIDDLE_BTN_NORTH_EAST, '9', true),
    mk(35, 'MB_NW', pointer.PointerStyle.MIDDLE_BTN_NORTH_WEST, '9', true),
    mk(36, 'MB_SE', pointer.PointerStyle.MIDDLE_BTN_SOUTH_EAST, '9', true),
    mk(37, 'MB_SW', pointer.PointerStyle.MIDDLE_BTN_SOUTH_WEST, '9', true),
    mk(38, 'MB_NSWE', pointer.PointerStyle.MIDDLE_BTN_NORTH_SOUTH_WEST_EAST, '9', true),
    mk(39, 'H_TEXT', pointer.PointerStyle.HORIZONTAL_TEXT_CURSOR, '10', true),
    mk(40, 'C_CROSS', pointer.PointerStyle.CURSOR_CROSS, '10', true),
    mk(41, 'C_CIRCLE', pointer.PointerStyle.CURSOR_CIRCLE, '10', true),
    mk(42, 'LOADING', pointer.PointerStyle.LOADING, '10', true),
    mk(43, 'RUNNING', pointer.PointerStyle.RUNNING, '10', true),
    mk(44, 'MB_E_W', pointer.PointerStyle.MIDDLE_BTN_EAST_WEST, '18', true),
    mk(45, 'RUN_LEFT', pointer.PointerStyle.RUNNING_LEFT, '22', true),
    mk(46, 'RUN_RIGHT', pointer.PointerStyle.RUNNING_RIGHT, '22', true),
    mk(47, 'AECH_CUSTOM', pointer.PointerStyle.AECH_DEVELOPER_DEFINED_ICON, '22', true),
    mk(48, 'RECORDER', pointer.PointerStyle.SCREENRECORDER_CURSOR, '20', true),
    mk(49, 'LASER', pointer.PointerStyle.LASER_CURSOR, '22', false),
    mk(50, 'LASER_DOT', pointer.PointerStyle.LASER_CURSOR_DOT, '22', false),
    mk(51, 'LASER_RED', pointer.PointerStyle.LASER_CURSOR_DOT_RED, '22', false)
  ];

  aboutToDisappear(): void {
    this.stopDemo();
  }

  addLog(ok: boolean, text: string): void {
    this.logs = [...this.logs, `${nowStr()} ${ok ? '✓' : '✗'} ${text}`];
  }

  applyStyle(item: PointerItem): void {
    if (!item.direct) {
      this.addLog(false, `${item.id} ${item.name}：仅手写笔空中鼠标模式可用，不能直接 setCursor（未调用）`);
      return;
    }
    try {
      this.getUIContext().getCursorController().setCursor(item.style);
      this.current = `${item.id} ${item.name}`;
      this.addLog(true, `setCursor(${item.name}) 已调用（下一渲染帧生效；since ${item.since}）`);
    } catch (e) {
      this.addLog(false, `setCursor(${item.name}) 失败: ` + errText(e as Object));
    }
  }

  tryDeveloperDefined(): void {
    try {
      this.getUIContext().getCursorController().setCursor(pointer.PointerStyle.DEVELOPER_DEFINED_ICON);
      this.addLog(true, 'setCursor(DEVELOPER_DEFINED_ICON=-100) 调用未报错（文档要求用 setCustomCursor 设置，此处实测验证）');
    } catch (e) {
      this.addLog(false, 'setCursor(DEVELOPER_DEFINED_ICON) 失败（文档预期）: ' + errText(e as Object));
    }
  }

  restore(): void {
    try {
      this.getUIContext().getCursorController().restoreDefault();
      this.current = 'DEFAULT(恢复)';
      this.addLog(true, 'restoreDefault() 成功');
    } catch (e) {
      this.addLog(false, 'restoreDefault() 失败: ' + errText(e as Object));
    }
  }

  async applyCustomCursor(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (!ctx) {
        this.addLog(false, '获取 context 失败');
        return;
      }
      const data: Uint8Array = ctx.resourceManager.getRawFileContentSync('cursor_star.png');
      const buf = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
      const src: image.ImageSource = image.createImageSource(buf);
      const pm = await src.createPixelMap();
      this.getUIContext().getCursorController().setCustomCursor(pm, 24, 24);
      this.current = '自定义 cursor_star.png';
      this.addLog(true, 'setCustomCursor(pixelMap,24,24) 成功（API26，仅本窗口，≤256×256 静态图）');
    } catch (e) {
      this.addLog(false, '自定义光标失败: ' + errText(e as Object));
    }
  }

  startDemo(): void {
    pointer.setPointerVisible(false)
      .then(() => {
        this.demoRunning = true;
        this.addLog(true, 'pointer.setPointerVisible(false) 成功：系统光标已隐藏，移动鼠标看旋转跟随图层');
        if (this.timerId >= 0) {
          clearInterval(this.timerId);
        }
        this.timerId = setInterval(() => {
          this.rotAngle = (this.rotAngle + 12) % 360;
        }, 40);
      })
      .catch((e: BusinessError) => this.addLog(false, 'setPointerVisible(false) 失败: ' + errText(e)));
  }

  stopDemo(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    if (this.demoRunning) {
      pointer.setPointerVisible(true)
        .then(() => this.addLog(true, 'pointer.setPointerVisible(true) 成功：系统光标已恢复'))
        .catch((e: BusinessError) => this.addLog(false, 'setPointerVisible(true) 失败: ' + errText(e)));
      this.demoRunning = false;
    }
  }

  build() {
    Column() {
      SectionHeader({
        title: '鼠标样式',
        note: `当前光标: ${this.current}　共 52 个命名样式(0-51)，点击格子真实切换；灰底 49-51 仅手写笔空中鼠标，不可直接设置`
      })

      Row({ space: 8 }) {
        Button('恢复默认')
          .fontSize(12)
          .height(30)
          .onClick(() => this.restore())
        Button('自定义图片光标')
          .fontSize(12)
          .height(30)
          .onClick(() => {
            this.applyCustomCursor();
          })
        Button(this.demoRunning ? '停止：恢复系统光标' : '隐藏光标+跟随')
          .fontSize(12)
          .height(30)
          .backgroundColor(this.demoRunning ? '#FF453A' : '#0A84FF')
          .onClick(() => {
            if (this.demoRunning) {
              this.stopDemo();
            } else {
              this.startDemo();
            }
          })
      }
      .width('100%')

      Text('自定义光标：rawfile/cursor_star.png 48×48，setCustomCursor（API26）仅本窗口、≤256×256、静态图。' +
        '跟随演示：pointer.setPointerVisible(false) 隐藏系统光标，onMouse 跟随绘制旋转图层（近似动画光标的对照方案）。')
        .fontSize(11)
        .fontColor('#8E8E93')
        .width('100%')
        .margin({ top: 8 })

      Stack() {
        Text(this.demoRunning ? '在此区域移动鼠标：系统光标已隐藏，红色图层跟随' : '点击上方「隐藏光标+跟随」后，在此区域移动鼠标')
          .fontSize(11)
          .fontColor('#8E8E93')
        if (this.demoRunning) {
          Stack() {
            Circle()
              .width(34)
              .height(34)
              .fillOpacity(0)
              .stroke('#FF453A')
              .strokeWidth(3)
            Column()
              .width(5)
              .height(11)
              .backgroundColor('#FF453A')
              .position({ x: 14.5, y: 0 })
          }
          .width(34)
          .height(34)
          .rotate({ angle: this.rotAngle })
          .position({ x: this.followX - 17, y: this.followY - 17 })
        }
      }
      .width('100%')
      .height(100)
      .backgroundColor('#1C1C1E')
      .borderRadius(10)
      .margin({ top: 8 })
      .onMouse((ev: MouseEvent) => {
        this.followX = ev.x;
        this.followY = ev.y;
      })

      Row({ space: 8 }) {
        Button('验证 DEVELOPER_DEFINED_ICON(-100)')
          .fontSize(11)
          .height(28)
          .onClick(() => this.tryDeveloperDefined())
        Text('文档要求自定义光标走 setCustomCursor；此处真实调用看结果')
          .fontSize(10)
          .fontColor('#8E8E93')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 8 })

      Grid() {
        ForEach(this.items, (item: PointerItem) => {
          GridItem() {
            Column() {
              Text(`${item.id}`)
                .fontSize(10)
                .fontColor('#8E8E93')
              Text(item.name)
                .fontSize(10)
                .fontColor(item.direct ? '#FFFFFF' : '#636366')
                .maxLines(1)
            }
            .width('100%')
            .height(44)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(item.direct ? '#2C2C2E' : '#1C1C1E')
            .borderRadius(6)
            .onClick(() => this.applyStyle(item))
          }
        }, (item: PointerItem) => item.id.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .columnsGap(6)
      .rowsGap(6)
      .layoutWeight(1)
      .margin({ top: 10 })

      LogView({ logs: this.logs })
    }
    .width('100%')
    .height('100%')
    .padding(14)
  }
}
