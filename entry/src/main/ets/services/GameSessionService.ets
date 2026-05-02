import { common } from '@kit.AbilityKit';
import {
  CompletedRunRecord,
  DEFAULT_SETTINGS,
  GameSettings,
  getPuzzleModeById,
  PuzzleModeConfig,
  PuzzleSession
} from '../models/GameModels';
import { startNewSession } from '../game/game';
import { preferencesService } from './PreferencesService';
import { ModeBestSummary, statsService } from './StatsService';

class GameSessionStore {
  private initialized: boolean = false;
  private settings: GameSettings = {
    defaultModeId: DEFAULT_SETTINGS.defaultModeId,
    hapticsEnabled: DEFAULT_SETTINGS.hapticsEnabled,
    shakeToShuffleEnabled: DEFAULT_SETTINGS.shakeToShuffleEnabled,
    assistEnabled: DEFAULT_SETTINGS.assistEnabled,
    autoResumeEnabled: DEFAULT_SETTINGS.autoResumeEnabled
  };
  private activeSession?: PuzzleSession;
  private recentRuns: CompletedRunRecord[] = [];

  async initialize(context: common.Context): Promise<void> {
    if (this.initialized) {
      return;
    }
    await preferencesService.init(context);
    this.settings = await preferencesService.getSettings();
    this.activeSession = await preferencesService.getActiveSession();
    this.recentRuns = await preferencesService.getRunHistory();

    if (this.activeSession) {
      const mode = getPuzzleModeById(this.activeSession.mode?.id);
      this.activeSession.mode = mode;
    }
    this.initialized = true;
  }

  getSettings(): GameSettings {
    return this.cloneSettings(this.settings);
  }

  async saveSettings(nextSettings: GameSettings): Promise<void> {
    this.settings = this.mergeSettings(DEFAULT_SETTINGS, nextSettings);
    await preferencesService.saveSettings(this.settings);
  }

  async patchSettings(patch: Partial<GameSettings>): Promise<void> {
    await this.saveSettings(this.mergeSettings(this.settings, patch));
  }

  startSession(mode: PuzzleModeConfig): PuzzleSession {
    const session = startNewSession(mode);
    this.activeSession = session;
    this.persistActiveSession();
    return session;
  }

  getActiveSession(): PuzzleSession | undefined {
    return this.activeSession;
  }

  getResumableSession(modeId?: string): PuzzleSession | undefined {
    if (!this.activeSession || this.activeSession.isCompleted) {
      return undefined;
    }
    if (!this.settings.autoResumeEnabled) {
      return undefined;
    }
    if (modeId && this.activeSession.mode.id !== modeId) {
      return undefined;
    }
    return this.activeSession;
  }

  saveActiveSession(session: PuzzleSession): void {
    this.activeSession = session;
    this.persistActiveSession();
  }

  clearActiveSession(): void {
    this.activeSession = undefined;
    this.clearStoredSession();
  }

  appendRun(record: CompletedRunRecord): void {
    this.recentRuns = this.prependRun(record);
    this.persistRuns();
  }

  getRecentRuns(limit: number = 12): CompletedRunRecord[] {
    return this.copyRuns(limit);
  }

  getAllRuns(): CompletedRunRecord[] {
    return this.copyRuns();
  }

  getModeBest(modeId: string): ModeBestSummary {
    return statsService.getModeBest(this.recentRuns, modeId);
  }

  private cloneSettings(source: GameSettings): GameSettings {
    return {
      defaultModeId: source.defaultModeId,
      hapticsEnabled: source.hapticsEnabled,
      shakeToShuffleEnabled: source.shakeToShuffleEnabled,
      assistEnabled: source.assistEnabled,
      autoResumeEnabled: source.autoResumeEnabled
    };
  }

  private mergeSettings(base: GameSettings, patch: Partial<GameSettings>): GameSettings {
    const merged: GameSettings = this.cloneSettings(base);
    if (patch.defaultModeId !== undefined) {
      merged.defaultModeId = patch.defaultModeId;
    }
    if (patch.hapticsEnabled !== undefined) {
      merged.hapticsEnabled = patch.hapticsEnabled;
    }
    if (patch.shakeToShuffleEnabled !== undefined) {
      merged.shakeToShuffleEnabled = patch.shakeToShuffleEnabled;
    }
    if (patch.assistEnabled !== undefined) {
      merged.assistEnabled = patch.assistEnabled;
    }
    if (patch.autoResumeEnabled !== undefined) {
      merged.autoResumeEnabled = patch.autoResumeEnabled;
    }
    return merged;
  }

  private prependRun(record: CompletedRunRecord): CompletedRunRecord[] {
    const nextRuns: CompletedRunRecord[] = [record];
    for (let index = 0; index < this.recentRuns.length && nextRuns.length < 40; index++) {
      nextRuns.push(this.recentRuns[index]);
    }
    return nextRuns;
  }

  private copyRuns(limit?: number): CompletedRunRecord[] {
    const copied: CompletedRunRecord[] = [];
    const maxCount = limit !== undefined ? Math.min(limit, this.recentRuns.length) : this.recentRuns.length;
    for (let index = 0; index < maxCount; index++) {
      copied.push(this.recentRuns[index]);
    }
    return copied;
  }

  private persistActiveSession(): void {
    if (!this.activeSession) {
      return;
    }
    preferencesService.saveActiveSession(this.activeSession).catch(() => {
    });
  }

  private clearStoredSession(): void {
    preferencesService.clearActiveSession().catch(() => {
    });
  }

  private persistRuns(): void {
    preferencesService.saveRunHistory(this.recentRuns).catch(() => {
    });
  }
}

export const gameSessionService = new GameSessionStore();
