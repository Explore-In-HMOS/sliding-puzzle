import { DEFAULT_MODE } from '../models/GameModels';

interface GameLaunchOptions {
  modeId: string;
  resumeSession: boolean;
}

class PendingGameLaunchService {
  private launchOptions: GameLaunchOptions = {
    modeId: DEFAULT_MODE.id,
    resumeSession: false
  };

  setLaunchOptions(modeId: string, resumeSession: boolean = false): void {
    this.launchOptions = {
      modeId,
      resumeSession
    };
  }

  getLaunchOptions(): GameLaunchOptions {
    return {
      modeId: this.launchOptions.modeId,
      resumeSession: this.launchOptions.resumeSession
    };
  }
}

export const gameLaunchService = new PendingGameLaunchService();
