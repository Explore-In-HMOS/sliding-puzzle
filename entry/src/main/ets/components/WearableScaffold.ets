import { wearableTokens } from '../theme/Tokens';

@Component
export struct WearableScaffold {
  @BuilderParam content: () => void;

  build() {
    Stack() {
      Scroll() {
        Column({ space: wearableTokens.spacing.md }) {
          this.content();
        }
        .width('100%')
        .padding({
          left: wearableTokens.spacing.md,
          right: wearableTokens.spacing.md,
          top: wearableTokens.spacing.md,
          bottom: wearableTokens.spacing.lg
        })
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
    }
    .backgroundColor(wearableTokens.colors.appBackground)
    .width('100%')
    .height('100%')
  }
}
