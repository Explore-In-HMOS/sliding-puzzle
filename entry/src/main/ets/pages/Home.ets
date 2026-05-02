import { AppButton } from '../components/AppButton';
import { AppCard } from '../components/AppCard';
import { WearableScaffold } from '../components/WearableScaffold';
import { APP_ROUTES } from '../models/Routes';
import { getPuzzleModeById, PUZZLE_MODES, PuzzleModeConfig, PuzzleSession } from '../models/GameModels';
import { gameLaunchService } from '../services/GameLaunchService';
import { gameSessionService } from '../services/GameSessionService';
import { wearableTokens } from '../theme/Tokens';

@Component
export struct HomePage {
  navPathStack?: NavPathStack = undefined;
  @State private resumableSession?: PuzzleSession = undefined;
  @State private defaultMode: PuzzleModeConfig = getPuzzleModeById();
  @State private loading: boolean = true;

  aboutToAppear(): void {
    this.loading = true;
    const context = this.getUIContext().getHostContext();
    if (context) {
      gameSessionService.initialize(context).then(() => {
        this.refreshHomeCards();
        this.loading = false;
      }).catch(() => {
        this.loading = false;
      });
      return;
    }
    this.refreshHomeCards();
    this.loading = false;
  }

  build() {
    NavDestination() {
      WearableScaffold() {
        Text('Sliding Puzzle')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(wearableTokens.colors.textPrimary)
          .width('100%')
          .textAlign(TextAlign.Center)

        if (this.loading) {
          AppCard() {
            Text('Loading your puzzle profile...')
              .fontSize(12)
              .fontColor(wearableTokens.colors.textSecondary)
          }
        }

        AppCard() {
          Text('Quick Start')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(wearableTokens.colors.textPrimary)
          Text(`Default mode: ${this.defaultMode.title}`)
            .fontSize(12)
            .fontColor(wearableTokens.colors.textSecondary)
          AppButton({
            label: 'Play',
            onPress: () => {
              this.goToGame(this.defaultMode);
            }
          })
        }

        if (this.resumableSession) {
          AppCard() {
            Text('Resume')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(wearableTokens.colors.textPrimary)
            Text(`${this.resumableSession.mode.title} · Moves ${this.resumableSession.puzzle.moves}`)
              .fontSize(12)
              .fontColor(wearableTokens.colors.textSecondary)
            Text(`Elapsed ${this.formatTime(this.resumableSession.elapsedSeconds)}`)
              .fontSize(12)
              .fontColor(wearableTokens.colors.textSecondary)
            AppButton({
              label: 'Resume Session',
              onPress: () => {
                this.goToGame(this.resumableSession!.mode, true);
              }
            })
          }
        }

        AppCard() {
          Text('Modes')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(wearableTokens.colors.textPrimary)

          ForEach(PUZZLE_MODES, (mode: PuzzleModeConfig) => {
            Column({ space: 6 }) {
              Text(mode.title)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(wearableTokens.colors.textPrimary)
              Text(mode.objective)
                .fontSize(12)
                .fontColor(wearableTokens.colors.textSecondary)
              Text(this.getModeBestText(mode.id))
                .fontSize(11)
                .fontColor(wearableTokens.colors.textSecondary)
              AppButton({
                label: `Start ${mode.boardSize}x${mode.boardSize}`,
                primary: false,
                onPress: () => {
                  this.goToGame(mode);
                }
              })
            }
            .width('100%')
            .padding({ top: 6, bottom: 6 })
          }, (mode: PuzzleModeConfig) => mode.id)
        }

        AppCard() {
          Text('More')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(wearableTokens.colors.textPrimary)
          AppButton({
            label: 'Stats',
            primary: false,
            onPress: () => {
              this.navPathStack?.pushPath({ name: APP_ROUTES.STATS });
            }
          })
          AppButton({
            label: 'Settings',
            primary: false,
            onPress: () => {
              this.navPathStack?.pushPath({ name: APP_ROUTES.SETTINGS });
            }
          })
        }
      }
    }
    .hideTitleBar(true)
  }

  private refreshHomeCards(): void {
    this.resumableSession = gameSessionService.getResumableSession();
    const settings = gameSessionService.getSettings();
    this.defaultMode = getPuzzleModeById(settings.defaultModeId);
  }

  private goToGame(mode: PuzzleModeConfig, resumeSession: boolean = false): void {
    gameLaunchService.setLaunchOptions(mode.id, resumeSession);
    this.navPathStack?.pushPath({
      name: APP_ROUTES.GAME
    });
  }

  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60).toString().padStart(2, '0');
    const secs = (seconds % 60).toString().padStart(2, '0');
    return `${mins}:${secs}`;
  }

  private getModeBestText(modeId: string): string {
    const best = gameSessionService.getModeBest(modeId);
    if (best.bestMoves === undefined || best.bestTimeSeconds === undefined) {
      return 'No completed runs yet';
    }
    return `Best ${best.bestMoves} moves · ${this.formatTime(best.bestTimeSeconds)}`;
  }
}
