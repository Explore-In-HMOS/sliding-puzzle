import { DEFAULT_MODE, getPuzzleModeById } from '../models/GameModels';
import { APP_ROUTES } from '../models/Routes';
import { GamePage } from './Game';
import { HomePage } from './Home';
import { SettingsPage } from './Settings';
import { StatsPage } from './Stats';
import { gameLaunchService } from '../services/GameLaunchService';
import { wearableTokens } from '../theme/Tokens';

@Entry
@Component
struct SlidingPuzzleApp {
  private navPathStack: NavPathStack = new NavPathStack();
  private shellInitialized: boolean = false;

  aboutToAppear(): void {
    if (!this.shellInitialized) {
      this.shellInitialized = true;
      this.navPathStack.pushPath({ name: APP_ROUTES.HOME });
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(wearableTokens.colors.appBackground)
    }
    .hideNavBar(true)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.navDestinationBuilder)
  }

  private resolvePuzzleMode() {
    return getPuzzleModeById(gameLaunchService.getLaunchOptions().modeId ?? DEFAULT_MODE.id);
  }

  private shouldResumeSession(): boolean {
    return gameLaunchService.getLaunchOptions().resumeSession;
  }

  @Builder
  private navDestinationBuilder(name: string) {
    if (name === APP_ROUTES.HOME) {
      HomePage({ navPathStack: this.navPathStack });
    } else if (name === APP_ROUTES.GAME) {
      GamePage({
        navPathStack: this.navPathStack,
        mode: this.resolvePuzzleMode(),
        resumeSession: this.shouldResumeSession()
      });
    } else if (name === APP_ROUTES.STATS) {
      StatsPage({ navPathStack: this.navPathStack });
    } else if (name === APP_ROUTES.SETTINGS) {
      SettingsPage({ navPathStack: this.navPathStack });
    }
  }
}
