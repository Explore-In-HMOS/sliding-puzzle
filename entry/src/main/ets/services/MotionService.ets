import { sensor } from '@kit.SensorServiceKit';

const SHAKE_THRESHOLD = 21;
const SHAKE_COOLDOWN_MS = 1600;

class MotionShakeService {
  private active: boolean = false;
  private lastShakeTs: number = 0;

  start(onShake: () => void, onError?: (message: string) => void): boolean {
    if (this.active) {
      return true;
    }
    this.onShakeCallback = onShake;
    this.onErrorCallback = onError ?? (() => {
    });
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        this.handleSensorData(data);
      }, { interval: 100000000 });
      this.active = true;
      return true;
    } catch (_error) {
      this.active = false;
      this.onErrorCallback('Shake unavailable on this device or permission denied.');
      return false;
    }
  }

  stop(): void {
    if (!this.active) {
      return;
    }
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
    } catch (_error) {
      // no-op
    }
    this.active = false;
  }

  private onShakeCallback: () => void = () => {
  };

  private onErrorCallback: (message: string) => void = () => {
  };

  private handleSensorData(data: sensor.AccelerometerResponse): void {
    const magnitude = Math.sqrt((data.x * data.x) + (data.y * data.y) + (data.z * data.z));
    const now = Date.now();
    if (magnitude < SHAKE_THRESHOLD || now - this.lastShakeTs < SHAKE_COOLDOWN_MS) {
      return;
    }
    this.lastShakeTs = now;
    this.onShakeCallback();
  }
}

export const motionService = new MotionShakeService();
