import { CompletedRunRecord, PUZZLE_MODES } from '../models/GameModels';

export interface ModeBestSummary {
  modeId: string;
  modeTitle: string;
  bestMoves?: number;
  bestTimeSeconds?: number;
  completedCount: number;
}

export interface StatsOverview {
  totalCompleted: number;
  totalFailed: number;
  totalRuns: number;
  currentCompletionStreak: number;
}

class StatsCalculatorService {
  getModeBest(records: CompletedRunRecord[], modeId: string): ModeBestSummary {
    const mode = PUZZLE_MODES.find(item => item.id === modeId);
    const completedModeRuns = records.filter((record: CompletedRunRecord) =>
    record.modeId === modeId && record.status === 'completed');

    if (completedModeRuns.length === 0) {
      return {
        modeId,
        modeTitle: mode?.title ?? modeId,
        completedCount: 0
      };
    }

    let bestMoves = completedModeRuns[0].moves;
    let bestTimeSeconds = completedModeRuns[0].elapsedSeconds;
    completedModeRuns.forEach((record: CompletedRunRecord) => {
      if (record.moves < bestMoves) {
        bestMoves = record.moves;
      }
      if (record.elapsedSeconds < bestTimeSeconds) {
        bestTimeSeconds = record.elapsedSeconds;
      }
    });

    return {
      modeId,
      modeTitle: mode?.title ?? modeId,
      bestMoves,
      bestTimeSeconds,
      completedCount: completedModeRuns.length
    };
  }

  getModeBreakdown(records: CompletedRunRecord[]): ModeBestSummary[] {
    return PUZZLE_MODES.map((mode) => this.getModeBest(records, mode.id));
  }

  getOverview(records: CompletedRunRecord[]): StatsOverview {
    const sortedRuns = [...records].sort((a, b) => b.completedAt - a.completedAt);
    const totalCompleted = sortedRuns.filter((record: CompletedRunRecord) => record.status === 'completed').length;
    const totalFailed = sortedRuns.filter((record: CompletedRunRecord) => record.status === 'failed').length;
    let streak = 0;
    for (let i = 0; i < sortedRuns.length; i++) {
      if (sortedRuns[i].status === 'completed') {
        streak += 1;
      } else {
        break;
      }
    }

    return {
      totalCompleted,
      totalFailed,
      totalRuns: sortedRuns.length,
      currentCompletionStreak: streak
    };
  }
}

export const statsService = new StatsCalculatorService();
