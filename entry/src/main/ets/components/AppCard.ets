import { wearableTokens } from '../theme/Tokens';

@Component
export struct AppCard {
  @BuilderParam content: () => void;

  build() {
    Column({ space: wearableTokens.spacing.sm }) {
      this.content();
    }
    .width('100%')
    .padding(wearableTokens.spacing.md)
    .backgroundColor(wearableTokens.colors.surface)
    .borderRadius(wearableTokens.radius.md)
    .border({ width: 1, color: wearableTokens.colors.border })
  }
}
