import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/colors.dart';
import 'package:mitlio/core/theme/spacing.dart';
import 'package:mitlio/core/theme/typography.dart';

/// Light and dark [ThemeData] of the app. Wire both into `MaterialApp`
/// (`theme`, `darkTheme`, `themeMode: system`).
abstract final class MitlioTheme {
  static final ThemeData light = _build(
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: MitlioPalette.lightAccent,
      onPrimary: MitlioPalette.lightOnAccent,
      primaryContainer: MitlioPalette.lightAccentContainer,
      onPrimaryContainer: MitlioPalette.lightOnAccentContainer,
      secondary: MitlioPalette.lightInkMuted,
      onSecondary: MitlioPalette.lightSurface,
      error: MitlioPalette.lightError,
      onError: MitlioPalette.lightOnError,
      errorContainer: MitlioPalette.lightErrorContainer,
      onErrorContainer: MitlioPalette.lightOnErrorContainer,
      surface: MitlioPalette.lightSurface,
      onSurface: MitlioPalette.lightInk,
      onSurfaceVariant: MitlioPalette.lightInkMuted,
      surfaceContainerHighest: MitlioPalette.lightSurfaceMuted,
      outline: MitlioPalette.lightOutline,
      outlineVariant: MitlioPalette.lightOutlineSoft,
    ),
    background: MitlioPalette.lightBackground,
    extension: MitlioColors.light,
  );

  static final ThemeData dark = _build(
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: MitlioPalette.darkAccent,
      onPrimary: MitlioPalette.darkOnAccent,
      primaryContainer: MitlioPalette.darkAccentContainer,
      onPrimaryContainer: MitlioPalette.darkOnAccentContainer,
      secondary: MitlioPalette.darkInkMuted,
      onSecondary: MitlioPalette.darkBackground,
      error: MitlioPalette.darkError,
      onError: MitlioPalette.darkOnError,
      errorContainer: MitlioPalette.darkErrorContainer,
      onErrorContainer: MitlioPalette.darkOnErrorContainer,
      surface: MitlioPalette.darkSurface,
      onSurface: MitlioPalette.darkInk,
      onSurfaceVariant: MitlioPalette.darkInkMuted,
      surfaceContainerHighest: MitlioPalette.darkSurfaceMuted,
      outline: MitlioPalette.darkOutline,
      outlineVariant: MitlioPalette.darkOutlineSoft,
    ),
    background: MitlioPalette.darkBackground,
    extension: MitlioColors.dark,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required MitlioColors extension,
  }) {
    final textTheme = MitlioTypography.textTheme(
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      extensions: [extension],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(Sizes.tapTarget, Sizes.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(Sizes.tapTarget, Sizes.tapTarget),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: Spacing.allMd,
        border: border(scheme.outline),
        enabledBorder: border(scheme.outline),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
      ),
    );
  }
}
