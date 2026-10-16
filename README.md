> **Note:** To access all shared projects, get information about environment setup, and view other guides, please visit [Explore-In-HMOS Index](https://github.com/Explore-In-HMOS/hmos-index).

# Sliding Puzzle

Sliding Puzzle is a HarmonyOS Next wearable puzzle app built for round watch screens.

The app ships with a multi-page flow (Home, Game, Stats, Settings), three playable modes, session resume, run history,
best-record tracking, assist actions (Hint/Peek), and wearable-native feedback such as haptics and optional
shake-to-reshuffle.

# Preview

<p align="left">
  <img src="screenshots/screenshot1.png" width="25%">
  <img src="screenshots/screenshot2.png" width="25%">
</p>

# Use Cases

- Quick daily puzzle sessions on a watch with mode-based challenge variety.
- Resume an unfinished run after reopening the app.
- Track improvement with mode bests, completion streak, and recent history.
- Enable/disable wearable behaviors (haptics, shake reshuffle, assist tools) from Settings.

# Tech Stack

- **Languages**: ArkTS, ArkUI
- **Frameworks**: HarmonyOS SDK 6.0.0(20)
- **Tools**: DevEco Studio (HarmonyOS 6.0 line)
- **Libraries**: @kit.ArkUI, @kit.ArkData, @kit.SensorServiceKit, @kit.AbilityKit

# Directory Structure

```
entry/src/main/ets/
├───entryability
│       EntryAbility.ets
├───entrybackupability
│       EntryBackupAbility.ets
├───components
│       AppButton.ets
│       AppCard.ets
│       WearableScaffold.ets
├───game
│       game.ts
│       constants.ts
│       puzzlecontroller.ets
│       puzzlerenderer.ets
│       slidingpuzzlegame.ets
│       types.ts
├───models
│       GameModels.ts
│       Routes.ts
├───pages
│       Game.ets
│       Home.ets
│       Index.ets
│       Settings.ets
│       Stats.ets
├───services
│       GameSessionService.ets
│       HapticsService.ets
│       MotionService.ets
│       PreferencesService.ets
│       StatsService.ets
├───theme
│       Tokens.ets
```

# Constraints and Restrictions

## Supported Devices

- Huawei Watch 5

# LICENSE

Sliding Puzzle is distributed under the terms of the MIT License.
See the [LICENSE](/LICENSE) for more information.