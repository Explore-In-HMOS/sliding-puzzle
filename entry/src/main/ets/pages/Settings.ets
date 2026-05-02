import { AppButton } from '../components/AppButton';
import { AppCard } from '../components/AppCard';
import { WearableScaffold } from '../components/WearableScaffold';
import { GameSettings, PUZZLE_MODES } from '../models/GameModels';
import { APP_ROUTES } from '../models/Routes';
import { gameSessionService } from '../services/GameSessionService';
import { wearableTokens } from '../theme/Tokens';

@Component
export struct SettingsPage {
  navPathStack?: NavPathStack = undefined;
  @State private settings: GameSettings = gameSessionService.getSettings();
  @State private loading: boolean = true;
  @State private statusMessage: string = '';

  aboutToAppear(): void {
    this.loading = true;
    const context = this.getUIContext().getHostContext();
    if (context) {
      gameSessionService.initialize(context).then(() => {
        this.settings = gameSessionService.getSettings();
        this.loading = false;
      }).catch(() => {
        this.loading = false;
        this.statusMessage = 'Could not load saved settings. Using defaults.';
      });
      return;
    }
    this.settings = gameSessionService.getSettings();
    this.loading = false;
  }

  build() {
    NavDestination() {
      WearableScaffold() {
        AppCard() {
          Text('Settings')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(wearableTokens.colors.textPrimary)

          Text(`Default mode: ${this.getDefaultModeTitle()}`)
            .fontSize(12)
            .fontColor(wearableTokens.colors.textSecondary)

          if (this.loading) {
            Text('Loading settings...')
              .fontSize(11)
              .fontColor(wearableTokens.colors.textSecondary)
          }

          AppButton({
            label: 'Cycle Default Mode',
            primary: false,
            onPress: () => {
              this.cycleDefaultMode();
            }
          })
        }

        AppCard() {
          Text('Wearable Behavior')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(wearableTokens.colors.textPrimary)

          AppButton({
            label: `Haptics: ${this.settings.hapticsEnabled ? 'On' : 'Off'}`,
            primary: false,
            onPress: () => {
              this.saveSettingPatch({ hapticsEnabled: !this.settings.hapticsEnabled });
            }
          })

          AppButton({
            label: `Shake Reshuffle: ${this.settings.shakeToShuffleEnabled ? 'On' : 'Off'}`,
            primary: false,
            onPress: () => {
              this.saveSettingPatch({ shakeToShuffleEnabled: !this.settings.shakeToShuffleEnabled });
            }
          })

          AppButton({
            label: `Assist Buttons: ${this.settings.assistEnabled ? 'On' : 'Off'}`,
            primary: false,
            onPress: () => {
              this.saveSettingPatch({ assistEnabled: !this.settings.assistEnabled });
            }
          })

          AppButton({
            label: `Auto Resume: ${this.settings.autoResumeEnabled ? 'On' : 'Off'}`,
            primary: false,
            onPress: () => {
              this.saveSettingPatch({ autoResumeEnabled: !this.settings.autoResumeEnabled });
            }
          })
        }

        Text(this.statusMessage)
          .fontSize(11)
          .fontColor(wearableTokens.colors.textSecondary)
          .textAlign(TextAlign.Center)
          .visibility(this.statusMessage.length > 0 ? Visibility.Visible : Visibility.None)

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

  private saveSettingPatch(patch: Partial<GameSettings>): void {
    const nextSettings: GameSettings = {
      defaultModeId: this.settings.defaultModeId,
      hapticsEnabled: this.settings.hapticsEnabled,
      shakeToShuffleEnabled: this.settings.shakeToShuffleEnabled,
      assistEnabled: this.settings.assistEnabled,
      autoResumeEnabled: this.settings.autoResumeEnabled
    };
    if (patch.defaultModeId !== undefined) {
      nextSettings.defaultModeId = patch.defaultModeId;
    }
    if (patch.hapticsEnabled !== undefined) {
      nextSettings.hapticsEnabled = patch.hapticsEnabled;
    }
    if (patch.shakeToShuffleEnabled !== undefined) {
      nextSettings.shakeToShuffleEnabled = patch.shakeToShuffleEnabled;
    }
    if (patch.assistEnabled !== undefined) {
      nextSettings.assistEnabled = patch.assistEnabled;
    }
    if (patch.autoResumeEnabled !== undefined) {
      nextSettings.autoResumeEnabled = patch.autoResumeEnabled;
    }
    this.settings = nextSettings;
    this.statusMessage = '';
    gameSessionService.patchSettings(patch).catch(() => {
      this.statusMessage = 'Could not save settings right now.';
    });
  }

  private cycleDefaultMode(): void {
    const modeIndex = PUZZLE_MODES.findIndex((mode) => mode.id === this.settings.defaultModeId);
    const nextIndex = modeIndex >= 0 ? (modeIndex + 1) % PUZZLE_MODES.length : 0;
    this.saveSettingPatch({ defaultModeId: PUZZLE_MODES[nextIndex].id });
  }

  private getDefaultModeTitle(): string {
    const selectedMode = PUZZLE_MODES.find((mode) => mode.id === this.settings.defaultModeId);
    return selectedMode?.title ?? PUZZLE_MODES[0].title;
  }
}
