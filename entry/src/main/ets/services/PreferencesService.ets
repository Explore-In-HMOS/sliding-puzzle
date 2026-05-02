import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import {
  CompletedRunRecord,
  DEFAULT_SETTINGS,
  GameSettings,
  parseSession,
  PuzzleSession,
  serializeSession
} from '../models/GameModels';

const PREF_FILE_NAME: string = 'slidingPuzzlePrefs';
const SETTINGS_KEY: string = 'settings';
const ACTIVE_SESSION_KEY: string = 'activeSession';
const RUN_HISTORY_KEY: string = 'runHistory';

class PreferenceStoreService {
  private preferenceStore?: preferences.Preferences;

  async init(context: common.Context): Promise<void> {
    if (this.preferenceStore) {
      return;
    }
    try {
      this.preferenceStore = await preferences.getPreferences(context, PREF_FILE_NAME);
    } catch (_error) {
      this.preferenceStore = undefined;
    }
  }

  async getSettings(): Promise<GameSettings> {
    const rawValue = this.getStringValue(SETTINGS_KEY);
    if (!rawValue) {
      return this.cloneDefaultSettings();
    }
    try {
      const parsedValue = JSON.parse(rawValue) as Partial<GameSettings>;
      return this.mergeWithDefaults(parsedValue);
    } catch (_error) {
      return this.cloneDefaultSettings();
    }
  }

  async saveSettings(settings: GameSettings): Promise<void> {
    await this.putStringValue(SETTINGS_KEY, JSON.stringify(settings));
  }

  async getActiveSession(): Promise<PuzzleSession | undefined> {
    const sessionString = this.getStringValue(ACTIVE_SESSION_KEY);
    if (!sessionString) {
      return undefined;
    }
    const parsedSession = parseSession(sessionString);
    if (!parsedSession || parsedSession.isCompleted) {
      return undefined;
    }
    return parsedSession;
  }

  async saveActiveSession(session: PuzzleSession): Promise<void> {
    await this.putStringValue(ACTIVE_SESSION_KEY, serializeSession(session));
  }

  async clearActiveSession(): Promise<void> {
    await this.deleteValue(ACTIVE_SESSION_KEY);
  }

  async getRunHistory(): Promise<CompletedRunRecord[]> {
    const runHistory = this.getStringValue(RUN_HISTORY_KEY);
    if (!runHistory) {
      return [];
    }
    try {
      const parsedValue = JSON.parse(runHistory) as CompletedRunRecord[];
      return parsedValue;
    } catch (_error) {
      return [];
    }
  }

  async saveRunHistory(history: CompletedRunRecord[]): Promise<void> {
    await this.putStringValue(RUN_HISTORY_KEY, JSON.stringify(history));
  }

  private cloneDefaultSettings(): GameSettings {
    return {
      defaultModeId: DEFAULT_SETTINGS.defaultModeId,
      hapticsEnabled: DEFAULT_SETTINGS.hapticsEnabled,
      shakeToShuffleEnabled: DEFAULT_SETTINGS.shakeToShuffleEnabled,
      assistEnabled: DEFAULT_SETTINGS.assistEnabled,
      autoResumeEnabled: DEFAULT_SETTINGS.autoResumeEnabled
    };
  }

  private mergeWithDefaults(partial?: Partial<GameSettings>): GameSettings {
    const merged: GameSettings = this.cloneDefaultSettings();
    if (!partial) {
      return merged;
    }
    if (partial.defaultModeId !== undefined) {
      merged.defaultModeId = partial.defaultModeId;
    }
    if (partial.hapticsEnabled !== undefined) {
      merged.hapticsEnabled = partial.hapticsEnabled;
    }
    if (partial.shakeToShuffleEnabled !== undefined) {
      merged.shakeToShuffleEnabled = partial.shakeToShuffleEnabled;
    }
    if (partial.assistEnabled !== undefined) {
      merged.assistEnabled = partial.assistEnabled;
    }
    if (partial.autoResumeEnabled !== undefined) {
      merged.autoResumeEnabled = partial.autoResumeEnabled;
    }
    return merged;
  }

  private getStringValue(key: string): string | undefined {
    if (!this.preferenceStore) {
      return undefined;
    }
    try {
      const value = this.preferenceStore.getSync(key, '');
      if (typeof value === 'string' && value.length > 0) {
        return value;
      }
      return undefined;
    } catch (_error) {
      return undefined;
    }
  }

  private async putStringValue(key: string, value: string): Promise<void> {
    if (!this.preferenceStore) {
      return;
    }
    try {
      this.preferenceStore.putSync(key, value);
      await this.preferenceStore.flush();
    } catch (_error) {
      // Keep app fail-soft on persistence issues.
    }
  }

  private async deleteValue(key: string): Promise<void> {
    if (!this.preferenceStore) {
      return;
    }
    try {
      this.preferenceStore.deleteSync(key);
      await this.preferenceStore.flush();
    } catch (_error) {
      // Keep app fail-soft on persistence issues.
    }
  }
}

export const preferencesService = new PreferenceStoreService();
