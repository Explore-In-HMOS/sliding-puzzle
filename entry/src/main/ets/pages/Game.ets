import { SlidingPuzzleCanvas } from '../game/slidingpuzzlegame';
import { APP_ROUTES } from '../models/Routes';
import { CompletedRunRecord, DEFAULT_MODE, GameSettings, PuzzleModeConfig, PuzzleSession } from '../models/GameModels';
import { gameSessionService } from '../services/GameSessionService';
import { wearableTokens } from '../theme/Tokens';

@Component
export struct GamePage {
  navPathStack?: NavPathStack = undefined;
  mode: PuzzleModeConfig = DEFAULT_MODE;
  resumeSession: boolean = false;
  @State private lastResult: string = '';
  @State private activeSession?: PuzzleSession = undefined;
  @State private settings: GameSettings = gameSessionService.getSettings();

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context) {
      gameSessionService.initialize(context).then(() => {
        this.settings = gameSessionService.getSettings();
        this.activeSession = this.resumeSession ? gameSessionService.getResumableSession(this.mode.id) : undefined;
      }).catch(() => {
      });
      return;
    }
    this.settings = gameSessionService.getSettings();
    this.activeSession = this.resumeSession ? gameSessionService.getResumableSession(this.mode.id) : undefined;
l  }l

  build() {
    NavDestination() {
      Stack() {
        SlidingPuzzleCanvas({
          mode: this.mode,
          initialSession: this.activeSession,
          hapticsEnabled: this.settings.hapticsEnabled,
          shakeToShuffleEnabled: this.settings.shakeToShuffleEnabled,
          assistEnabled: this.settings.assistEnabled,
          onSessionChange: (session: PuzzleSession) => {
            gameSessionService.saveActiveSession(session);
          },
          onCompleted: (record: CompletedRunRecord) => {
            gameSessionService.appendRun(record);
            gameSessionService.clearActiveSession();
            this.lastResult = this.formatSummary(record);
          },
          onGoHome: () => {
            gameSessionService.clearActiveSession();
            this.navPathStack?.popToName(APP_ROUTES.HOME);
          }
        })
          .width('100%')
          .height('100%')
      }
      .backgroundColor(wearableTokens.colors.appBackground)
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  private formatSummary(record: CompletedRunRecord): string {
    const mins = Math.floor(record.elapsedSeconds / 60).toString().padStart(2, '0');
    const secs = (record.elapsedSeconds % 60).toString().padStart(2, '0');
    if (record.status === 'failed') {
      return `Time ended at ${mins}:${secs}.`;
    }
    const help = record.hintsUsed + record.previewsUsed;
    return `${record.moves} moves · ${mins}:${secs}${help > 0 ? ` · Assist ${help}` : ''}`;
  }
}
