import { PuzzleState } from '../game/types';

export interface PuzzleModeConfig {
  id: string;
  title: string;
  boardSize: number;
  shuffleMoves: number;
  objective: string;
  timeLimitSec?: number;
}

export interface PuzzleSession {
  sessionId: string;
  mode: PuzzleModeConfig;
  startedAt: number;
  updatedAt: number;
  puzzle: PuzzleState;
  elapsedSeconds: number;
  hintsUsed: number;
  previewsUsed: number;
  isPaused: boolean;
  isCompleted: boolean;
}

export interface CompletedRunRecord {
  sessionId: string;
  modeId: string;
  boardSize: number;
  moves: number;
  elapsedSeconds: number;
  hintsUsed: number;
  previewsUsed: number;
  status: 'completed' | 'failed';
  objectiveMet: boolean;
  startedAt: number;
  completedAt: number;
}

export interface GameSettings {
  defaultModeId: string;
  hapticsEnabled: boolean;
  shakeToShuffleEnabled: boolean;
  assistEnabled: boolean;
  autoResumeEnabled: boolean;
}

export const PUZZLE_MODES: PuzzleModeConfig[] = [
  {
    id: 'classic-3x3',
    title: 'Classic 3x3',
    boardSize: 3,
    shuffleMoves: 100,
    objective: 'Solve with fewer than 80 moves.'
  },
  {
    id: 'challenge-4x4',
    title: 'Challenge 4x4',
    boardSize: 4,
    shuffleMoves: 170,
    objective: 'Solve the 4x4 board under 160 moves.'
  },
  {
    id: 'timed-sprint',
    title: 'Timed Sprint',
    boardSize: 3,
    shuffleMoves: 120,
    objective: 'Solve before the 120 second timer ends.',
    timeLimitSec: 120
  }
];

export const DEFAULT_MODE: PuzzleModeConfig = PUZZLE_MODES[0];

export const DEFAULT_SETTINGS: GameSettings = {
  defaultModeId: DEFAULT_MODE.id,
  hapticsEnabled: true,
  shakeToShuffleEnabled: false,
  assistEnabled: true,
  autoResumeEnabled: true
};

export function getPuzzleModeById(modeId?: string): PuzzleModeConfig {
  if (!modeId) {
    return DEFAULT_MODE;
  }
  const matchedMode: PuzzleModeConfig | undefined = PUZZLE_MODES.find((mode: PuzzleModeConfig) => mode.id === modeId);
  return matchedMode ?? DEFAULT_MODE;
}

export function createSessionId(): string {
  return `session-${Date.now()}`;
}

export function serializeSession(session: PuzzleSession): string {
  return JSON.stringify(session);
}

export function parseSession(value: string): PuzzleSession | null {
  try {
    const parsedValue = JSON.parse(value) as Record<string, unknown>;
    if (!parsedValue || typeof parsedValue !== 'object') {
      return null;
    }

    const modeValue = parsedValue.mode as Record<string, unknown> | undefined;
    const modeId = typeof modeValue?.id === 'string'
      ? modeValue.id as string
      : (typeof parsedValue.modeId === 'string' ? parsedValue.modeId as string : undefined);
    const mode = getPuzzleModeById(modeId);

    const puzzleValue = parsedValue.puzzle as Record<string, unknown> | undefined;
    if (!puzzleValue || typeof puzzleValue !== 'object') {
      return null;
    }

    const tilesValue = puzzleValue.tiles;
    const emptyPositionValue = puzzleValue.emptyPosition as Record<string, number | undefined> | undefined;
    if (!Array.isArray(tilesValue) || !emptyPositionValue || typeof emptyPositionValue !== 'object') {
      return null;
    }

    const size = typeof puzzleValue.size === 'number' ? puzzleValue.size : mode.boardSize;
    const moves = typeof puzzleValue.moves === 'number' ? puzzleValue.moves : 0;
    const isComplete = typeof puzzleValue.isComplete === 'boolean' ? puzzleValue.isComplete : false;
    const isShuffled = typeof puzzleValue.isShuffled === 'boolean' ? puzzleValue.isShuffled : true;
    const emptyX = typeof emptyPositionValue.x === 'number' ? emptyPositionValue.x : size - 1;
    const emptyY = typeof emptyPositionValue.y === 'number' ? emptyPositionValue.y : size - 1;

    const startedAt = typeof parsedValue.startedAt === 'number' ? parsedValue.startedAt : Date.now();
    const updatedAt = typeof parsedValue.updatedAt === 'number' ? parsedValue.updatedAt : startedAt;

    return {
      sessionId: typeof parsedValue.sessionId === 'string' ? parsedValue.sessionId : createSessionId(),
      mode,
      startedAt,
      updatedAt,
      puzzle: {
        size,
        tiles: tilesValue as PuzzleState['tiles'],
        emptyPosition: { x: emptyX, y: emptyY },
        moves,
        isComplete,
        isShuffled
      },
      elapsedSeconds: typeof parsedValue.elapsedSeconds === 'number' ? parsedValue.elapsedSeconds : 0,
      hintsUsed: typeof parsedValue.hintsUsed === 'number' ? parsedValue.hintsUsed : 0,
      previewsUsed: typeof parsedValue.previewsUsed === 'number' ? parsedValue.previewsUsed : 0,
      isPaused: typeof parsedValue.isPaused === 'boolean' ? parsedValue.isPaused : false,
      isCompleted: typeof parsedValue.isCompleted === 'boolean' ? parsedValue.isCompleted : false
    };
  } catch (_e) {
    return null;
  }
}
