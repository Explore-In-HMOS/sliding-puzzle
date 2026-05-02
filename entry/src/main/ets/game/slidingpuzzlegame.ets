import {
  createRunRecord,
  createSolvedPuzzle,
  incrementSessionSeconds,
  markSessionPaused,
  startNewSession,
  updateSession
} from './game';
import { COLORS, PUZZLE_CONFIG } from './constants';
import { PuzzleRenderer } from './puzzlerenderer';
import { PuzzleController } from './puzzlecontroller';
import { PuzzleState } from './types';
import { CompletedRunRecord, DEFAULT_MODE, PuzzleModeConfig, PuzzleSession } from '../models/GameModels';
import { hapticsService } from '../services/HapticsService';
import { motionService } from '../services/MotionService';
import { wearableTokens } from '../theme/Tokens';

@Component
export struct SlidingPuzzleCanvas {
  mode: PuzzleModeConfig = DEFAULT_MODE;
  @Prop @Watch('onInitialSessionChanged') initialSession?: PuzzleSession = undefined;
  @Prop @Watch('onHapticsEnabledChanged') hapticsEnabled: boolean = true;
  @Prop @Watch('onShakeToShuffleChanged') shakeToShuffleEnabled: boolean = false;
  @Prop @Watch('onAssistEnabledChanged') assistEnabled: boolean = true;
  @State private session?: PuzzleSession = undefined;
  @State private showResult: boolean = false;
  @State private resultTitle: string = '';
  @State private statusMessage: string = '';
  @State private previewEnabled: boolean = false;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private renderer: PuzzleRenderer = new PuzzleRenderer(this.context);
  private controller: PuzzleController = this.buildController(this.mode);
  private gameLoopTimer: number = -1;
  private sessionTimer: number = -1;
  private previewResetTimer: number = -1;
  private gameLoopActive: boolean = false;

  onSessionChange: (session: PuzzleSession) => void = (_session: PuzzleSession) => {
  };

  onCompleted: (record: CompletedRunRecord) => void = (_record: CompletedRunRecord) => {
  };

  onGoHome: () => void = () => {
  };

  aboutToAppear(): void {
    this.initializeSessionState();
    this.applyRuntimeSettings();
    if (this.session) {
      this.onSessionChange(this.session);
    }
    this.startGameLoop();
    this.startSessionTimer();
  }

  aboutToDisappear(): void {
    this.stopGameLoop();
    this.stopSessionTimer();
    this.clearPreviewResetTimer();
    motionService.stop();
  }

  build() {
    RelativeContainer() {
      Column({ space: 2 }) {
        Text(this.getDisplayHeader())
          .fontSize(16)
          .fontColor(wearableTokens.colors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textShadow({
            radius: 4,
            color: '#1A2333'
          })

        Text(this.getDisplaySecondaryText())
          .fontSize(11)
          .fontColor(wearableTokens.colors.textSecondary)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textShadow({
            radius: 3,
            color: '#1A2333'
          })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .padding({ top: 10 })
      .width(233)
      .height(42)

      if (this.session) {
        Canvas(this.context)
          .borderRadius(6)
          .borderStyle(BorderStyle.Solid)
          .borderColor(COLORS.TILE_BORDER)
          .borderWidth(1)
          .position({
            left: PUZZLE_CONFIG.CANVAS_OFFSET,
            top: PUZZLE_CONFIG.CANVAS_OFFSET
          })
          .width(PUZZLE_CONFIG.CANVAS_SIZE)
          .height(PUZZLE_CONFIG.CANVAS_SIZE)
          .onReady(() => {
            if (!this.session) {
              return;
            }
            this.renderer.drawPuzzle(this.session.puzzle);
          })
          .onTouch((event: TouchEvent) => {
            if (event.type !== TouchType.Up || !this.session) {
              return;
            }
            if (this.session.isPaused || this.showResult) {
              this.statusMessage = 'Game is paused';
              return;
            }
            const touch = event.touches[0];
            if (!touch) {
              return;
            }
            const moved = this.controller.handleTileTap(this.session.puzzle, touch.x, touch.y);
            if (!moved) {
              this.statusMessage = 'Tap a tile next to empty space';
              hapticsService.play('invalid');
            } else {
              this.statusMessage = '';
              hapticsService.play('move');
            }
          })
          .gesture(
            PanGesture({ fingers: 1, distance: 30 })
              .onActionEnd((event: GestureEvent) => {
                if (!this.session) {
                  return;
                }
                if (this.session.isPaused || this.showResult) {
                  this.statusMessage = 'Game is paused';
                  return;
                }
                const moved = this.controller.handleGesture(this.session.puzzle, event);
                if (!moved) {
                  this.statusMessage = 'No tile moved from swipe';
                  hapticsService.play('invalid');
                } else {
                  this.statusMessage = '';
                  hapticsService.play('move');
                }
              })
          )
      } else {
        Column() {
          Text('Preparing board...')
            .fontSize(11)
            .fontColor(wearableTokens.colors.textSecondary)
        }
        .position({
          left: PUZZLE_CONFIG.CANVAS_OFFSET,
          top: PUZZLE_CONFIG.CANVAS_OFFSET
        })
        .width(PUZZLE_CONFIG.CANVAS_SIZE)
        .height(PUZZLE_CONFIG.CANVAS_SIZE)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(6)
        .backgroundColor(wearableTokens.colors.surface)
      }

      if (this.showResult && this.session) {
        Column() {
          Text(this.resultTitle)
            .fontSize(18)
            .fontColor(wearableTokens.colors.textPrimary)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10 })

          Text(`${this.session.puzzle.moves} moves · ${this.formatTime(this.session.elapsedSeconds)}`)
            .fontSize(13)
            .fontColor(wearableTokens.colors.textSecondary)
          Text(`Hints ${this.session.hintsUsed} · Peek ${this.session.previewsUsed}`)
            .fontSize(12)
            .fontColor(wearableTokens.colors.textSecondary)

          Row({ space: 8 }) {
            Button('Replay')
              .fontSize(12)
              .height(30)
              .fontColor(wearableTokens.colors.textPrimary)
              .backgroundColor(wearableTokens.colors.accent)
              .borderRadius(8)
              .onClick(() => {
                this.resetSessionForCurrentMode();
              })
            Button('Home')
              .fontSize(12)
              .height(30)
              .fontColor(wearableTokens.colors.textPrimary)
              .backgroundColor(wearableTokens.colors.surfaceMuted)
              .borderRadius(8)
              .onClick(() => {
                this.onGoHome();
              })
          }
        }
        .backgroundColor('rgba(6, 11, 18, 0.95)')
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .backgroundColor(wearableTokens.colors.appBackground)
    .width('100%')
    .height('100%')

    .linearGradient({
      angle: 145,
      colors: [[COLORS.GRADIENT_START, 0], [COLORS.GRADIENT_END, 1]]
    })
  }

  private createFreshSession(): PuzzleSession {
    return startNewSession(this.mode ?? DEFAULT_MODE);
  }

  private hasValidSession(session?: PuzzleSession): boolean {
    return session !== undefined && session.puzzle !== undefined && session.puzzle.tiles !== undefined &&
      session.puzzle.size > 0;
  }

  private initializeSessionState(): void {
    const resumableSession = this.initialSession;
    if (this.hasValidSession(resumableSession) && resumableSession!.mode.id === this.mode.id &&
      !resumableSession!.isCompleted) {
      this.session = resumableSession;
      this.statusMessage = 'Resumed from home';
    } else if (!this.hasValidSession(this.session) || this.session!.mode.id !== this.mode.id) {
      this.session = this.createFreshSession();
      this.statusMessage = 'New puzzle ready';
    }
    this.controller = this.buildController(this.mode);
    this.showResult = false;
    this.previewEnabled = false;
    this.resultTitle = '';
  }

  private getPuzzle(): PuzzleState | undefined {
    return this.session?.puzzle;
  }

  private getDisplayHeader(): string {
    return this.mode.title;
  }

  private getDisplayProgressText(): string {
    const moves = this.session?.puzzle?.moves ?? 0;
    const elapsedSeconds = this.session?.elapsedSeconds ?? 0;
    return `${moves} moves · ${this.formatTime(elapsedSeconds)}`;
  }

  private getDisplaySecondaryText(): string {
    if (this.statusMessage.length > 0) {
      return this.statusMessage;
    }
    return this.getDisplayProgressText();
  }

  private resetSessionForCurrentMode(): void {
    this.controller = this.buildController(this.mode);
    this.session = this.createFreshSession();
    this.showResult = false;
    this.previewEnabled = false;
    this.resultTitle = '';
    this.statusMessage = 'New puzzle ready';
    this.onSessionChange(this.session);
  }

  private buildController(mode: PuzzleModeConfig): PuzzleController {
    return new PuzzleController(
      (puzzle: PuzzleState) => {
        if (!this.session) {
          return;
        }
        this.session = updateSession(this.session, puzzle);
        this.onSessionChange(this.session);
        if (puzzle.isComplete && puzzle.isShuffled && !this.showResult) {
          this.onCompleted(createRunRecord(this.session));
          hapticsService.play('success');
          this.resultTitle = 'Completed!';
          this.showResult = true;
          this.statusMessage = '';
        }
      },
      this.renderer.getTileSize(mode.boardSize)
    );
  }

  private clearPreviewResetTimer(): void {
    if (this.previewResetTimer !== -1) {
      clearTimeout(this.previewResetTimer);
      this.previewResetTimer = -1;
    }
  }

  private startGameLoop(): void {
    if (this.gameLoopActive) {
      return;
    }
    this.gameLoopActive = true;
    this.scheduleGameLoop();
  }

  private stopGameLoop(): void {
    this.gameLoopActive = false;
    if (this.gameLoopTimer !== -1) {
      clearTimeout(this.gameLoopTimer);
      this.gameLoopTimer = -1;
    }
  }

  private scheduleGameLoop(): void {
    if (!this.gameLoopActive) {
      return;
    }
    const puzzle = this.previewEnabled ? createSolvedPuzzle(this.mode.boardSize) : this.getPuzzle();
    if (!puzzle) {
      return;
    }
    this.renderer.drawPuzzle(puzzle);
    this.gameLoopTimer = setTimeout(() => {
      this.scheduleGameLoop();
    }, 16);
  }

  private startSessionTimer(): void {
    if (this.sessionTimer !== -1) {
      return;
    }
    this.sessionTimer = setInterval(() => {
      if (!this.session || this.session.isPaused || this.showResult || this.session.isCompleted) {
        return;
      }
      this.session = incrementSessionSeconds(this.session);
      this.onSessionChange(this.session);
      if (this.mode.timeLimitSec !== undefined && this.session.elapsedSeconds >= this.mode.timeLimitSec) {
        this.session = markSessionPaused(this.session, true);
        this.resultTitle = 'Time Up';
        this.showResult = true;
        this.statusMessage = '';
        hapticsService.play('invalid');
        this.onCompleted(createRunRecord(this.session, 'failed'));
      }
    }, 1000);
  }

  private startMotionShake(): void {
    if (!this.shakeToShuffleEnabled) {
      return;
    }
    motionService.start(() => {
      if (!this.session || this.session.isPaused || this.showResult) {
        return;
      }
      this.resetSessionForCurrentMode();
      this.statusMessage = 'Board reshuffled by shake';
      hapticsService.play('move');
    }, (message: string) => {
      this.statusMessage = message;
    });
  }

  private applyRuntimeSettings(): void {
    hapticsService.setEnabled(this.hapticsEnabled);
    if (this.shakeToShuffleEnabled) {
      this.startMotionShake();
      return;
    }
    motionService.stop();
  }

  private onHapticsEnabledChanged(): void {
    hapticsService.setEnabled(this.hapticsEnabled);
  }

  private onShakeToShuffleChanged(): void {
    if (this.shakeToShuffleEnabled) {
      this.startMotionShake();
      return;
    }
    motionService.stop();
  }

  private onAssistEnabledChanged(): void {
    if (this.assistEnabled) {
      return;
    }
    this.previewEnabled = false;
    this.clearPreviewResetTimer();
  }

  private onInitialSessionChanged(): void {
    if (!this.initialSession) {
      return;
    }
    if (!this.initialSession.puzzle || this.initialSession.mode.id !== this.mode.id ||
    this.initialSession.isCompleted) {
      return;
    }
    this.initializeSessionState();
    if (this.session) {
      this.onSessionChange(this.session);
    }
  }

  private stopSessionTimer(): void {
    if (this.sessionTimer !== -1) {
      clearInterval(this.sessionTimer);
      this.sessionTimer = -1;
    }
  }

  private formatTime(totalSeconds: number): string {
    const mins = Math.floor(totalSeconds / 60).toString().padStart(2, '0');
    const secs = (totalSeconds % 60).toString().padStart(2, '0');
    if (this.mode.timeLimitSec !== undefined && !this.showResult) {
      const remaining = Math.max(this.mode.timeLimitSec - totalSeconds, 0);
      const remMins = Math.floor(remaining / 60).toString().padStart(2, '0');
      const remSecs = (remaining % 60).toString().padStart(2, '0');
      return `${mins}:${secs} (${remMins}:${remSecs})`;
    }
    return `${mins}:${secs}`;
  }
}
