import 'package:material_ui/material_ui.dart';

/// Type scale. System font on purpose (fast cold start, native feel, no
/// asset to ship); personality comes from weight, size contrast and the
/// big tabular result figure.
abstract final class MitlioTypography {
  static const FontFeature _tabular = FontFeature.tabularFigures();

  /// [base] with fixed-width digits, so amounts align and do not jitter.
  static TextStyle tabular(TextStyle? base) =>
      (base ?? const TextStyle()).copyWith(fontFeatures: const [_tabular]);

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
    // Result figure ("12,40 €"): the one thing a screen is about.
    displayMedium: TextStyle(
      fontSize: 48,
      height: 1.1,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
      color: ink,
      fontFeatures: const [_tabular],
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: ink),
    bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: ink),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: muted,
    ),
  );
}
