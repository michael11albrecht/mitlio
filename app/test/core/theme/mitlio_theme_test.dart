import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, theme, background) in [
    ('light', MitlioTheme.light, MitlioPalette.lightBackground),
    ('dark', MitlioTheme.dark, MitlioPalette.darkBackground),
  ]) {
    group(name, () {
      final s = theme.colorScheme;

      test('brightness matches', () {
        expect(
          s.brightness,
          name == 'light' ? Brightness.light : Brightness.dark,
        );
      });

      test('text pairs meet WCAG AA (4.5:1)', () {
        final pairs = <String, (Color, Color)>{
          'ink/background': (s.onSurface, background),
          'ink/surface': (s.onSurface, s.surface),
          'muted/background': (s.onSurfaceVariant, background),
          'muted/surface': (s.onSurfaceVariant, s.surface),
          'muted/muted-surface': (
            s.onSurfaceVariant,
            s.surfaceContainerHighest,
          ),
          'accent/surface': (s.primary, s.surface),
          'accent/background': (s.primary, background),
          'onAccent/accent': (s.onPrimary, s.primary),
          'onAccentContainer/container': (
            s.onPrimaryContainer,
            s.primaryContainer,
          ),
          'error/surface': (s.error, s.surface),
          'error/background': (s.error, background),
          'onError/error': (s.onError, s.error),
          'onErrorContainer/container': (s.onErrorContainer, s.errorContainer),
        };
        for (final e in pairs.entries) {
          expect(
            _contrast(e.value.$1, e.value.$2),
            greaterThanOrEqualTo(4.5),
            reason: e.key,
          );
        }
      });

      test('input border meets non-text contrast (3:1)', () {
        expect(_contrast(s.outline, s.surface), greaterThanOrEqualTo(3));
        expect(_contrast(s.outline, background), greaterThanOrEqualTo(3));
      });

      test('avatar pairs meet AA', () {
        final colors = theme.extension<MitlioColors>()!;
        expect(colors.avatars, hasLength(8));
        for (final c in colors.avatars) {
          expect(
            _contrast(c.foreground, c.background),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(
          colors.avatars.map((c) => c.background).toSet(),
          hasLength(8),
        );
      });

      test('result figure is tabular and the largest style', () {
        final display = theme.textTheme.displayMedium!;
        expect(
          display.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(
          display.fontSize,
          greaterThan(theme.textTheme.headlineMedium!.fontSize!),
        );
      });

      test('buttons keep a 48 dp tap target', () {
        final size = theme.filledButtonTheme.style!.minimumSize!.resolve({})!;
        expect(size.height, greaterThanOrEqualTo(Sizes.tapTarget));
        expect(size.width, greaterThanOrEqualTo(Sizes.tapTarget));
      });
    });
  }

  test('spacing scale is ascending on a 4 px grid', () {
    const scale = [Spacing.xs, Spacing.sm, Spacing.md, Spacing.lg, Spacing.xl];
    expect([...scale]..sort(), scale);
    expect(scale.every((v) => v % 4 == 0), isTrue);
  });

  test('MitlioColors lerp and copyWith', () {
    expect(MitlioColors.light.lerp(MitlioColors.dark, 0), MitlioColors.light);
    expect(MitlioColors.light.lerp(MitlioColors.dark, 1), MitlioColors.dark);
    expect(MitlioColors.light.lerp(null, 1), MitlioColors.light);
    expect(
      MitlioColors.light.copyWith(avatars: const []).avatars,
      isEmpty,
    );
    expect(MitlioColors.light.copyWith().avatars, MitlioColors.light.avatars);
  });

  testWidgets('MitlioColors.of reads the ambient theme', (tester) async {
    late MitlioColors found;
    await tester.pumpWidget(
      MaterialApp(
        theme: MitlioTheme.dark,
        home: Builder(
          builder: (context) {
            found = MitlioColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(found, MitlioColors.dark);
  });

  test('MitlioTypography.tabular keeps the base style', () {
    final style = MitlioTypography.tabular(const TextStyle(fontSize: 20));
    expect(style.fontSize, 20);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(MitlioTypography.tabular(null).fontFeatures, isNotEmpty);
  });
}
