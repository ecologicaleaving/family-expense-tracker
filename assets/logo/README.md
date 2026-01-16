# Fin Logo & Icon Assets

Official logo and icon assets for the Fin family budget management app.

## Main Files

### `icon_original.png`
- **Size**: 1024×1024px
- **Format**: PNG with transparency
- **Background**: Deep Forest green (#2D4A3E) with rounded corners
- **Source**: Original design
- **Use**: Master icon file for generating all app icons

## Design Elements

The Fin logo represents the harmony between **family unity** and **financial balance**:

1. **🌳 Growing Tree**: Symbolizes financial growth and prosperity
2. **⚖️ Balance Scale**: Represents balanced budgeting and fairness in shared finances
3. **💰 Dollar Coin**: Clear financial focus
4. **👨‍👩‍👧‍👦 Two Figures**: Adult and child working together - family collaboration
5. **🍃 Sage Green Leaves**: Natural growth and healthy finances

## Color Palette

- **Deep Forest**: #2D4A3E (background, tree, figures, scale)
- **Sage Green**: #7A9B76 (leaves, scale pans)
- **Cream/White**: #FFFBF5 (dollar coin, highlights)

## Generated Icons

App icons are auto-generated using `flutter_launcher_icons` package:

### Android
- Standard launcher icons: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Adaptive icons: `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`
- Background color: #2D4A3E (defined in `colors.xml`)

### iOS
- App icon: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Regenerating Icons

If you update `icon_original.png`, regenerate all platform icons:

```bash
flutter pub run flutter_launcher_icons
```

Configuration is in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#2D4A3E"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  min_sdk_android: 24
```

## Usage in Flutter

Icons are available as assets:

```dart
// Display logo in app
Image.asset('assets/logo/icon_original.png', width: 100, height: 100)

// Or from icons folder
Image.asset('assets/icons/app_icon.png', width: 100, height: 100)
```

## Notes

- Keep `icon_original.png` at high resolution (1024×1024px minimum)
- Maintain rounded corners for consistency
- Deep Forest background is part of the brand identity
- The two-figure design emphasizes family collaboration
