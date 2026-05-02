import { Point, PuzzleState, Tile } from './types';
import {
  CompletedRunRecord,
  createSessionId,
  DEFAULT_MODE,
  PuzzleModeConfig,
  PuzzleSession
} from '../models/GameModels';

export function createPuzzle(size: number = 3): PuzzleState {
  const tiles: Tile[] = [];

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const id = y * size + x + 1;
      const isEmpty = id === size * size;

      tiles.push({
        id: isEmpty ? 0 : id,
        position: { x, y },
        targetPosition: { x, y },
        isEmpty
      });
    }
  }

  return shufflePuzzle({
    size,
    tiles,
    emptyPosition: { x: size - 1, y: size - 1 },
    moves: 0,
    isComplete: true,
    isShuffled: false
  });
}

export function createSession(mode: PuzzleModeConfig = DEFAULT_MODE): PuzzleSession {
  const now = Date.now();
  return {
    sessionId: createSessionId(),
    mode,
    startedAt: now,
    updatedAt: now,
    puzzle: createPuzzle(mode.boardSize),
    elapsedSeconds: 0,
    hintsUsed: 0,
    previewsUsed: 0,
    isPaused: false,
    isCompleted: false
  };
}

export function startNewSession(mode: PuzzleModeConfig = DEFAULT_MODE): PuzzleSession {
  const session = createSession(mode);
  return {
    ...session,
    puzzle: shufflePuzzleSmart(session.puzzle, mode.shuffleMoves)
  };
}

export function updateSession(session: PuzzleSession, puzzle: PuzzleState): PuzzleSession {
  return {
    ...session,
    updatedAt: Date.now(),
    puzzle,
    isCompleted: puzzle.isComplete
  };
}

export function incrementSessionSeconds(session: PuzzleSession): PuzzleSession {
  return {
    ...session,
    updatedAt: Date.now(),
    elapsedSeconds: session.elapsedSeconds + 1
  };
}

export function markSessionPaused(session: PuzzleSession, paused: boolean): PuzzleSession {
  return {
    ...session,
    updatedAt: Date.now(),
    isPaused: paused
  };
}

export function markHintUsed(session: PuzzleSession): PuzzleSession {
  return {
    ...session,
    updatedAt: Date.now(),
    hintsUsed: session.hintsUsed + 1
  };
}

export function markPreviewUsed(session: PuzzleSession): PuzzleSession {
  return {
    ...session,
    updatedAt: Date.now(),
    previewsUsed: session.previewsUsed + 1
  };
}

export function createRunRecord(session: PuzzleSession,
  status: 'completed' | 'failed' = 'completed'): CompletedRunRecord {
  const modeGoalMet: boolean = status === 'completed' &&
    (session.mode.timeLimitSec === undefined || session.elapsedSeconds <= session.mode.timeLimitSec);
  return {
    sessionId: session.sessionId,
    modeId: session.mode.id,
    boardSize: session.mode.boardSize,
    moves: session.puzzle.moves,
    elapsedSeconds: session.elapsedSeconds,
    hintsUsed: session.hintsUsed,
    previewsUsed: session.previewsUsed,
    status,
    objectiveMet: modeGoalMet,
    startedAt: session.startedAt,
    completedAt: Date.now()
  };
}

export function shufflePuzzle(puzzle: PuzzleState, shuffleMoves: number = 100): PuzzleState {
  let newPuzzle = { ...puzzle };
  const directions = ['up', 'down', 'left', 'right'];

  for (let i = 0; i < shuffleMoves; i++) {
    const randomDirection = directions[Math.floor(Math.random() * directions.length)];
    const moveResult = moveTile(newPuzzle, randomDirection);
    if (moveResult) {
      newPuzzle = moveResult;
    }
  }

  return {
    ...newPuzzle,
    moves: 0,
    isComplete: false,
    isShuffled: true
  };
}

export function shufflePuzzleSmart(puzzle: PuzzleState, shuffleMoves: number = 100): PuzzleState {
  let candidate = shufflePuzzle(puzzle, shuffleMoves);
  const minimumDistance = Math.floor((puzzle.size * puzzle.size) / 2);

  for (let i = 0; i < 6; i++) {
    const misplacedCount = countMisplacedTiles(candidate);
    if (misplacedCount >= minimumDistance && !candidate.isComplete) {
      return candidate;
    }
    candidate = shufflePuzzle(puzzle, shuffleMoves + (i + 1) * 8);
  }

  return candidate;
}

export function moveTile(puzzle: PuzzleState, direction: string): PuzzleState | null {
  const { emptyPosition, size } = puzzle;
  let targetPosition: Point;

  switch (direction) {
    case 'up':
      targetPosition = { x: emptyPosition.x, y: emptyPosition.y + 1 };
      break;
    case 'down':
      targetPosition = { x: emptyPosition.x, y: emptyPosition.y - 1 };
      break;
    case 'left':
      targetPosition = { x: emptyPosition.x + 1, y: emptyPosition.y };
      break;
    case 'right':
      targetPosition = { x: emptyPosition.x - 1, y: emptyPosition.y };
      break;
    default:
      return null;
  }

  if (targetPosition.x < 0 || targetPosition.x >= size ||
    targetPosition.y < 0 || targetPosition.y >= size) {
    return null;
  }

  const tileToMoveIndex = puzzle.tiles.findIndex(
    tile =>
    tile.position.x === targetPosition.x &&
      tile.position.y === targetPosition.y
  );

  if (tileToMoveIndex === -1) {
    return null;
  }

  const newTiles = [...puzzle.tiles];
  const tileToMove = { ...newTiles[tileToMoveIndex] };

  tileToMove.position = { ...emptyPosition };
  newTiles[tileToMoveIndex] = tileToMove;

  const newPuzzle: PuzzleState = {
    ...puzzle,
    tiles: newTiles,
    emptyPosition: targetPosition,
    moves: puzzle.moves + 1
  };

  newPuzzle.isComplete = checkComplete(newPuzzle);

  return newPuzzle;
}

export function moveTileByPosition(puzzle: PuzzleState, tilePosition: Point): PuzzleState | null {
  const { emptyPosition } = puzzle;
  const dx = Math.abs(tilePosition.x - emptyPosition.x);
  const dy = Math.abs(tilePosition.y - emptyPosition.y);

  if ((dx === 1 && dy === 0) || (dx === 0 && dy === 1)) {
    let direction: string;

    if (tilePosition.x > emptyPosition.x) {
      direction = 'left';
    } else if (tilePosition.x < emptyPosition.x) {
      direction =
        'right';
    } else if (tilePosition.y > emptyPosition.y) {
      direction = 'up';
    } else {
      direction = 'down';
    }

    return moveTile(puzzle, direction);
  }

  return null;
}

function checkComplete(puzzle: PuzzleState): boolean {
  return puzzle.tiles.every(tile => {
    if (tile.isEmpty) {
      return tile.position.x === puzzle.size - 1 && tile.position.y === puzzle.size - 1;
    }
    return tile.position.x === tile.targetPosition.x &&
      tile.position.y === tile.targetPosition.y;
  });
}

export function createSolvedPuzzle(size: number): PuzzleState {
  const tiles: Tile[] = [];
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const id = y * size + x + 1;
      const isEmpty = id === size * size;
      tiles.push({
        id: isEmpty ? 0 : id,
        position: { x, y },
        targetPosition: { x, y },
        isEmpty
      });
    }
  }
  return {
    size,
    tiles,
    emptyPosition: { x: size - 1, y: size - 1 },
    moves: 0,
    isComplete: true,
    isShuffled: false
  };
}

export function getHintText(puzzle: PuzzleState): string {
  const nextTile = puzzle.tiles.find((tile: Tile) => !tile.isEmpty &&
    (tile.position.x !== tile.targetPosition.x || tile.position.y !== tile.targetPosition.y));
  if (!nextTile) {
    return 'Try moving a tile beside the empty space.';
  }

  const dx = nextTile.position.x - puzzle.emptyPosition.x;
  const dy = nextTile.position.y - puzzle.emptyPosition.y;
  if (Math.abs(dx) + Math.abs(dy) === 1) {
    return `Hint: move tile ${nextTile.id}.`;
  }

  return `Hint: align tile ${nextTile.id} toward row ${nextTile.targetPosition.y + 1}.`;
}

function countMisplacedTiles(puzzle: PuzzleState): number {
  return puzzle.tiles.filter((tile: Tile) => !tile.isEmpty &&
    (tile.position.x !== tile.targetPosition.x || tile.position.y !== tile.targetPosition.y)).length;
}
