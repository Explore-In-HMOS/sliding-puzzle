import { AppButton } from '../components/AppButton';
import { AppCard } from '../components/AppCard';
import { WearableScaffold } from '../components/WearableScaffold';
import { CompletedRunRecord } from '../models/GameModels';
import { APP_ROUTES } from '../models/Routes';
import { gameSessionService } from '../services/GameSessionService';
import { ModeBestSummary, StatsOverview, statsService } from '../services/StatsService';
import { wearableTokens } from '../theme/Tokens';

@Component
export struct StatsPage {
  navPathStack?: NavPathStack = undefined;
  @State private loading: boolean = true;
  @State private overview: StatsOverview = {
    totalCompleted: 0,
    totalFailed: 0,
    totalRuns: 0,
    currentCompletionStreak: 0
  };
  @State private recentRuns: CompletedRunRecord[] = [];
  @State private modeBreakdown: ModeBestSummary[] = [];

  aboutToAppear(): void {
    this.loading = true;
    const context = this.getUIContext().getHostContext();
    if (context) {
      gameSessionService.initialize(context).then(() => {
        this.loadStats();
        this.loading = false;
      }).catch(() => {
        this.loading = false;
      });
      return;
    }
    this.loadStats();
    this.loading = false;
  }

  build() {
    NavDestination() {
      WearableScaffold() {
        AppCard() {
          Text('Stats')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(wearableTokens.colors.textPrimary)

          Text(`Runs ${this.overview.totalRuns} · Completed ${this.overview.totalCompleted}`)
            .fontSize(13)
            .fontColor(wearableTokens.colors.textSecondary)

          Text(`Failed ${this.overview.totalFailed} · Streak ${this.overview.currentCompletionStreak}`)
            .fontSize(12)
            .fontColor(wearableTokens.colors.textSecondary)

          if (this.loading) {
            Text('Loading run history...')
              .fontSize(12)
              .fontColor(wearableTokens.colors.textSecondary)
          }

          if (this.overview.totalRuns === 0) {
            Text('No history yet. Complete a puzzle run to create records.')
              .fontSize(12)
              .fontColor(wearableTokens.colors.textSecondary)
          }
        }

        if (this.overview.totalRuns > 0) {
          AppCard() {
            Text('Best by Mode')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(wearableTokens.colors.textPrimary)

            ForEach(this.modeBreakdown, (modeSummary: ModeBestSummary) => {
              Column({ space: 2 }) {
                Text(modeSummary.modeTitle)
                  .fontSize(13)
                  .fontColor(wearableTokens.colors.textPrimary)
                Text(modeSummary.bestMoves === undefined || modeSummary.bestTimeSeconds === undefined
                  ? 'No completed runs'
                  : `Best ${modeSummary.bestMoves} moves · ${this.formatTime(modeSummary.bestTimeSeconds)}`)
                  .fontSize(11)
                  .fontColor(wearableTokens.colors.textSecondary)
                Text(`Completed ${modeSummary.completedCount}`)
                  .fontSize(10)
                  .fontColor(wearableTokens.colors.textSecondary)
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
            }, (modeSummary: ModeBestSummary) => modeSummary.modeId)
          }

          AppCard() {
            Text('Recent Sessions')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(wearableTokens.colors.textPrimary)

            ForEach(this.recentRuns, (run: CompletedRunRecord) => {
              Column({ space: 2 }) {
                Text(`${run.modeId} · ${run.status === 'completed' ? 'Solved' : 'Failed'}`)
                  .fontSize(12)
                  .fontColor(wearableTokens.colors.textPrimary)
                Text(`${run.moves} moves · ${this.formatTime(run.elapsedSeconds)}`)
                  .fontSize(10)
                  .fontColor(wearableTokens.colors.textSecondary)
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
            }, (run: CompletedRunRecord) => `${run.sessionId}-${run.completedAt}`)
          }
        }

        AppButton({
          label: 'Back Home',
          primary: false,
          onPress: () => {
            this.navPathStack?.popToName(APP_ROUTES.HOME);
          }
        })
      }
    }
    .hideTitleBar(true)
  }

  private loadStats(): void {
    const allRuns = gameSessionService.getAllRuns();
    this.overview = statsService.getOverview(allRuns);
    this.recentRuns = gameSessionService.getRecentRuns(8);
    this.modeBreakdown = statsService.getModeBreakdown(allRuns);
  }

  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60).toString().padStart(2, '0');
    const secs = (seconds % 60).toString().padStart(2, '0');
    return `${mins}:${secs}`;
  }
}
