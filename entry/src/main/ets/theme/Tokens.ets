interface WearableColorTokens {
  appBackground: string;
  surface: string;
  surfaceMuted: string;
  border: string;
  textPrimary: string;
  textSecondary: string;
  accent: string;
  accentPressed: string;
  danger: string;
}

interface WearableSpacingTokens {
  xs: number;
  sm: number;
  md: number;
  lg: number;
}

interface WearableRadiusTokens {
  sm: number;
  md: number;
  lg: number;
}

interface WearableThemeTokens {
  colors: WearableColorTokens;
  spacing: WearableSpacingTokens;
  radius: WearableRadiusTokens;
}

export const wearableTokens: WearableThemeTokens = {
  colors: {
    appBackground: '#0D1117',
    surface: '#1A2333',
    surfaceMuted: '#212D40',
    border: '#2C3D57',
    textPrimary: '#F4F7FF',
    textSecondary: '#B5C2DA',
    accent: '#4D8DFF',
    accentPressed: '#3D71CC',
    danger: '#D96868'
  },
  spacing: {
    xs: 6,
    sm: 10,
    md: 14,
    lg: 18
  },
  radius: {
    sm: 8,
    md: 12,
    lg: 16
  }
};
