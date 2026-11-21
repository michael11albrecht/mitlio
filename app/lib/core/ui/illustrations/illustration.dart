import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';

/// Colours every illustration paints with, all taken from the ambient theme
/// (light and dark follow automatically). No raw colours in the painters.
@immutable
class IllustrationPalette {
  const IllustrationPalette({
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.lineSoft,
    required this.warm,
    required this.avatars,
  });

  factory IllustrationPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatars = MitlioColors.of(context).avatars;
    return IllustrationPalette(
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      accentSoft: scheme.primaryContainer,
      onAccentSoft: scheme.onPrimaryContainer,
      surface: scheme.surface,
      surfaceMuted: scheme.surfaceContainerHighest,
      ink: scheme.onSurface,
      inkMuted: scheme.onSurfaceVariant,
      line: scheme.outline,
      lineSoft: scheme.outlineVariant,
      warm: avatars[1].background,
      avatars: avatars,
    );
  }

  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color lineSoft;

  /// Amber accent for small highlights (from the avatar palette).
  final Color warm;
  final List<AvatarColors> avatars;

  @override
  bool operator ==(Object other) =>
      other is IllustrationPalette &&
      other.accent == accent &&
      other.surface == surface &&
      other.ink == ink &&
      other.warm == warm &&
      other.accentSoft == accentSoft &&
      other.surfaceMuted == surfaceMuted;

  @override
  int get hashCode => Object.hash(accent, surface, ink, warm, accentSoft);
}

/// Common shell of all illustrations: a fixed-aspect canvas with a semantics
/// label. Pass an empty [semanticLabel] for purely decorative use (the
/// illustration is then hidden from screen readers).
class Illustration extends StatelessWidget {
  const Illustration({
    required this.semanticLabel,
    required this.painterBuilder,
    this.width = 160,
    this.aspectRatio = 1,
    super.key,
  });

  final String semanticLabel;
  final CustomPainter Function(IllustrationPalette palette) painterBuilder;
  final double width;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final canvas = SizedBox(
      width: width,
      height: width / aspectRatio,
      child: CustomPaint(
        painter: painterBuilder(IllustrationPalette.of(context)),
      ),
    );
    if (semanticLabel.isEmpty) return ExcludeSemantics(child: canvas);
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: canvas,
    );
  }
}

/// A rounded rect from a left/top/width/height in unit space.
RRect unitRRect(double l, double t, double w, double h, double r) =>
    RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r));

/// Stroke paint with round caps and joins.
Paint strokePaint(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = width
  ..color = color;

Paint fillPaint(Color color) => Paint()..color = color;

/// Base painter: draws in a 100 unit wide space (height follows the aspect
/// ratio) so the geometry reads like an SVG and scales to any width.
abstract class UnitPainter extends CustomPainter {
  const UnitPainter(this.p);

  final IllustrationPalette p;

  void paintUnits(Canvas canvas);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 100);
    paintUnits(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant UnitPainter old) => old.p != p;
}
