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

There is a single icon. Once flavors exist (P8-T01), the dev flavor gets a small "dev" badge; until then there is nothing to badge.

## Files

| File | Role |
|---|---|
| `app/assets/brand/icon.svg` | Source of truth for the geometry (1024 x 1024). |
| `app/lib/core/widgets/brand_mark.dart` | The same geometry as a `CustomPainter` (first-run screen, asset renderer). Keep it in step with the SVG. |
| `app/assets/brand/icon.png`, `icon_foreground.png`, `splash_mark.png`, `splash_mark_dark.png` | Generator inputs, rendered from the painter. |
| `app/flutter_launcher_icons.yaml` | `flutter_launcher_icons` config (iOS + Android, adaptive icon background `#0B6B63`). |
| `app/flutter_native_splash.yaml` | `flutter_native_splash` config (light/dark, Android 12). |
| `app/test/golden/goldens/brand_mark_*.png` | Golden rendering of the mark (light/dark). |

`flutter_launcher_icons` and `flutter_native_splash` are dev dependencies only (they run at design time and ship nothing in the app).

## Replacing the placeholder

1. Put the new 1024 x 1024 full-bleed `icon.png` (no rounded corners, the stores mask it), a transparent `icon_foreground.png` (mark inside the central 66 %), and `splash_mark.png` / `splash_mark_dark.png` into `app/assets/brand/`. Update `icon.svg` and `brand_mark.dart` if the new mark should also appear in the app.
2. Regenerate the platform files:

   ```sh
   cd app
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```

3. Commit the generated Android (`res/mipmap-*`, `res/drawable*`, `res/values*`) and iOS (`Assets.xcassets`, `LaunchScreen.storyboard`) files together with the PNGs.

To re-render the PNGs from the current painter instead: `cd app && flutter test tool/render_brand_assets_test.dart`.
