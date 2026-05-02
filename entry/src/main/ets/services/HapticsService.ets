import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

type HapticFeedbackType = 'move' | 'invalid' | 'success';

class WearableHapticsService {
  private enabled: boolean = true;

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  play(type: HapticFeedbackType): void {
    if (!this.enabled) {
      return;
    }

    const effectId = this.getPresetEffect(type);
    vibrator.isSupportEffect(effectId, (_error: BusinessError, state: boolean) => {
      if (state) {
        this.triggerPreset(effectId, type);
      } else {
        this.triggerFallbackTime(type);
      }
    });
  }

  private getPresetEffect(type: HapticFeedbackType): string {
    if (type === 'success') {
      return 'haptic.notice.success';
    }
    if (type === 'invalid') {
      return 'haptic.notice.fail';
    }
    return 'haptic.common.click';
  }

  private triggerPreset(effectId: string, fallbackType: HapticFeedbackType): void {
    try {
      vibrator.startVibration({
        type: 'preset',
        effectId,
        count: 1
      }, {
        usage: 'notification'
      }).catch(() => {
        this.triggerFallbackTime(fallbackType);
      });
    } catch (_error) {
      this.triggerFallbackTime(fallbackType);
    }
  }

  private triggerFallbackTime(type: HapticFeedbackType): void {
    const duration = type === 'success' ? 80 : (type === 'invalid' ? 50 : 24);
    try {
      vibrator.startVibration({
        type: 'time',
        duration
      }, {
        id: 0,
        usage: 'notification'
      }).catch(() => {
      });
    } catch (_error) {
      // No-op by design.
    }
  }
}

export const hapticsService = new WearableHapticsService();
