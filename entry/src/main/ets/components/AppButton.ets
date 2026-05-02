import { wearableTokens } from '../theme/Tokens';

@Component
export struct AppButton {
  label: string = '';
  primary: boolean = true;

  onPress: () => void = () => {
  };

  build() {
    Button(this.label)
      .width('100%')
      .height(36)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(wearableTokens.colors.textPrimary)
      .backgroundColor(this.primary ? wearableTokens.colors.accent : wearableTokens.colors.surfaceMuted)
      .borderRadius(wearableTokens.radius.sm)
      .onClick(() => {
        this.onPress();
      })
  }
}
