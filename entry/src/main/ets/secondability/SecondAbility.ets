import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class SecondAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'PcShowcase', 'SecondAbility onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'PcShowcase', 'SecondAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'PcShowcase', 'SecondAbility onWindowStageCreate');
    windowStage.loadContent('pages/Second', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'PcShowcase', 'SecondAbility loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'PcShowcase', 'SecondAbility loadContent ok');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'PcShowcase', 'SecondAbility onWindowStageDestroy');
  }
}
