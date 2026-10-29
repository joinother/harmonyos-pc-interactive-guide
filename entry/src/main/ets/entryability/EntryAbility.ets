import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'PcShowcase', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'PcShowcase', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'PcShowcase', 'onWindowStageCreate');
    AppStorage.setOrCreate('windowStage', windowStage);
    AppStorage.setOrCreate('uiAbilityContext', this.context);
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'PcShowcase', 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'PcShowcase', 'loadContent ok');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'PcShowcase', 'onWindowStageDestroy');
  }

  onForeground(): void {
    AppStorage.setOrCreate('appForeground', true);
  }

  onBackground(): void {
    AppStorage.setOrCreate('appForeground', false);
  }
}
