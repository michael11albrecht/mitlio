# Brand: app icon and splash

**Status: v1 placeholder.** The icon and splash are a simple, honest mark so the app does not ship with the Flutter default. **The owner is expected to replace them** with a designed identity before the store listing (P8). Nothing else in the app depends on the mark's look.

## The v1 mark

An open gauge (the taxometer) with its needle: a 270 degree arc, open at the bottom, a needle pointing up and right, and a hub. Bold shapes only so it stays legible at 29 pt. Colours come from the theme ("Nordic petrol", `app/lib/core/theme/colors.dart`):

| Part | Colour |
|---|---|
| Icon background | `#0B6B63` (`lightAccent`) |
| Gauge arc, hub | `#FFFFFF` (`lightOnAccent`) |
| Needle | `#D3EEE9` (`lightAccentContainer`) |

Splash: plain theme background (`#F4F7F6` light, `#0C1413` dark) with the mark in the accent colour (`#0B6B63` / `#5ED0C0`). No text, no animation, no spinner.

The prod flavor uses the mark above. The dev flavor (P8-T01) gets the same mark lifted a little with an amber "dev" tag in the opening of the gauge, so a dev build is never mistaken for the real app on the same phone. Android: `app/android/app/src/dev/res/` (overlays `main`). iOS: `AppIcon-dev` appiconset, selected by `ASSETCATALOG_COMPILER_APPICON_NAME` in the three dev build configurations of `Runner.xcodeproj`. The splash is the same for both.

## Files

| File | Role |
|---|---|
| `app/assets/brand/icon.svg` | Source of truth for the geometry (1024 x 1024). |
| `app/lib/core/widgets/brand_mark.dart` | The same geometry as a `CustomPainter` (first-run screen, asset renderer). Keep it in step with the SVG. |
| `app/assets/brand/icon.png`, `icon_foreground.png`, `icon_dev.png`, `icon_dev_foreground.png`, `splash_mark.png`, `splash_mark_dark.png` | Generator inputs, rendered from the painter by `app/tool/render_brand_assets_test.dart`. |
| `app/flutter_launcher_icons.yaml`, `flutter_launcher_icons-dev.yaml` | `flutter_launcher_icons` config for prod and the dev flavor (iOS + Android, adaptive icon background `#0B6B63`). |
| `app/flutter_native_splash.yaml` | `flutter_native_splash` config (light/dark, Android 12). |
| `app/test/golden/goldens/brand_mark_*.png` | Golden rendering of the mark (light/dark). |

`flutter_launcher_icons` and `flutter_native_splash` are dev dependencies only (they run at design time and ship nothing in the app).

## Replacing the placeholder

1. Put the new 1024 x 1024 full-bleed `icon.png` (no rounded corners, the stores mask it), a transparent `icon_foreground.png` (mark inside the central 66 %), and `splash_mark.png` / `splash_mark_dark.png` into `app/assets/brand/`. Update `icon.svg` and `brand_mark.dart` if the new mark should also appear in the app.
2. Regenerate the platform files:

   ```sh
   cd app
   dart run flutter_launcher_icons -f flutter_launcher_icons.yaml   # prod
   dart run flutter_launcher_icons                                  # dev flavor (finds flutter_launcher_icons-dev.yaml)
   dart run flutter_native_splash:create
   ```

3. Review the diff before committing. The generators also rewrite `ios/Runner/Info.plist` (whole-file re-indent, a status bar key we do not need) and `Runner.xcodeproj/project.pbxproj` (a wrong `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` value; the `AppIcon-dev` selection for the three dev configurations is the only intended change). Revert those unintended changes; commit the generated Android (`res/mipmap-*`, `res/drawable*`, `res/values*`, `src/dev/res`) and iOS (`Assets.xcassets`, `LaunchScreen.storyboard`) files together with the PNGs.

To re-render the PNGs from the current painter instead: `cd app && flutter test tool/render_brand_assets_test.dart`.
