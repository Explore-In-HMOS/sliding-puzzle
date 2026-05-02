import { describe, expect, it } from '@ohos/hypium';
import { createRunRecord, createSolvedPuzzle, getHintText, markHintUsed, markPreviewUsed, moveTile, moveTileByPosition, shufflePuzzleSmart, startNewSession } from '../main/ets/game/game';
import { CompletedRunRecord, DEFAULT_MODE, parseSession, PUZZLE_MODES, serializeSession } from '../main/ets/models/GameModels';
import { statsService } from '../main/ets/services/StatsService';

export default function localUnitTest() {
  describe('SlidingPuzzleLogicTests', () => {
    it('moveTile blocks invalid direction and increments valid moves', 0, () => {
      const solved = createSolvedPuzzle(3);
      const invalid = moveTile(solved, 'up');
      expect(invalid === null).assertTrue();

      const moved = moveTile(solved, 'left');
      expect(moved !== null).assertTrue();
      expect(moved?.moves).assertEqual(1);
      expect(moved?.isComplete).assertFalse();
    });

    it('moveTileByPosition only moves adjacent tiles', 0, () => {
      const solved = createSolvedPuzzle(3);
      const blocked = moveTileByPosition(solved, { x: 0, y: 0 });
      expect(blocked === null).assertTrue();

      const moved = moveTileByPosition(solved, { x: 1, y: 2 });
      expect(moved !== null).assertTrue();
      expect(moved?.moves).assertEqual(1);
    });

    it('shufflePuzzleSmart returns shuffled unfinished puzzle', 0, () => {
      const solved = createSolvedPuzzle(DEFAULT_MODE.boardSize);
      const shuffled = shufflePuzzleSmart(solved, 80);
      expect(shuffled.isShuffled).assertTrue();
      expect(shuffled.moves).assertEqual(0);
      expect(shuffled.isComplete).assertFalse();
    });

    it('session helpers increment assist counters and record completion', 0, () => {
      let session = startNewSession(PUZZLE_MODES[0]);
      session = markHintUsed(session);
      session = markPreviewUsed(session);
      expect(session.hintsUsed).assertEqual(1);
      expect(session.previewsUsed).assertEqual(1);

      const completedRecord = createRunRecord(session, 'completed');
      expect(completedRecord.status).assertEqual('completed');
      expect(completedRecord.objectiveMet).assertTrue();

      const failedRecord = createRunRecord(session, 'failed');
      expect(failedRecord.objectiveMet).assertFalse();
    });

    it('session serialization and parse failures are handled', 0, () => {
      const session = startNewSession(PUZZLE_MODES[1]);
      const parsed = parseSession(serializeSession(session));
      expect(parsed !== null).assertTrue();
      expect(parsed?.sessionId).assertEqual(session.sessionId);
      expect(parsed?.mode.id).assertEqual(PUZZLE_MODES[1].id);

      const invalidParsed = parseSession('{broken_json');
      expect(invalidParsed === null).assertTrue();
    });

    it('stats service aggregates overview and per-mode best values', 0, () => {
      const now = Date.now();
      const records: CompletedRunRecord[] = [
        createRecord('s-1', PUZZLE_MODES[0].id, 3, 44, 95, 'completed', now - 1000),
        createRecord('s-2', PUZZLE_MODES[0].id, 3, 38, 88, 'completed', now - 500),
        createRecord('s-3', PUZZLE_MODES[1].id, 4, 210, 320, 'failed', now - 100)
      ];

      const bestClassic = statsService.getModeBest(records, PUZZLE_MODES[0].id);
      expect(bestClassic.completedCount).assertEqual(2);
      expect(bestClassic.bestMoves).assertEqual(38);
      expect(bestClassic.bestTimeSeconds).assertEqual(88);

      const overview = statsService.getOverview(records);
      expect(overview.totalRuns).assertEqual(3);
      expect(overview.totalCompleted).assertEqual(2);
      expect(overview.totalFailed).assertEqual(1);
      expect(overview.currentCompletionStreak).assertEqual(0);
    });

    it('hint text returns contextual guidance', 0, () => {
      const solved = createSolvedPuzzle(3);
      const hintFromSolved = getHintText(solved);
      expect(hintFromSolved).assertContain('Try moving a tile');

      const moved = moveTile(solved, 'left');
      if (moved) {
        const hint = getHintText(moved);
        expect(hint).assertContain('Hint:');
      }
    });
  });
}

function createRecord(
  sessionId: string,
  modeId: string,
  boardSize: number,
  moves: number,
  elapsedSeconds: number,
  status: 'completed' | 'failed',
  completedAt: number
): CompletedRunRecord {
  return {
    sessionId,
    modeId,
    boardSize,
    moves,
    elapsedSeconds,
    hintsUsed: 0,
    previewsUsed: 0,
    status,
    objectiveMet: status === 'completed',
    startedAt: completedAt - 500,
    completedAt
  };
}
