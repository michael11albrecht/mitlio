import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/illustrations/illustration.dart';

/// Which screen of the generic phone mockup to show in "So findest du deinen
/// Link". The mockups are neutral wireframes: no PayPal logo, name or brand
/// colours, only a highlighted tap target (accent ring) telling where to tap.
enum PayPalStep {
  /// Open the payment app, home with the profile or settings entry.
  openApp,

  /// Inside the profile: the "get paid" or "share" entry is highlighted.
  openSharing,

  /// The personal link page: the link field is highlighted (copy it).
  copyLink,

  /// Back in mitlio: paste the link into the field.
  pasteLink,
}

class PayPalStepIllustration extends StatelessWidget {
  const PayPalStepIllustration({
    required this.step,
    required this.semanticLabel,
    this.width = 160,
    super.key,
  });

  final PayPalStep step;
  final String semanticLabel;
  final double width;

  @override
  Widget build(BuildContext context) => Illustration(
    semanticLabel: semanticLabel,
    width: width,
    aspectRatio: 0.8,
    painterBuilder: (p) => _PayPalStepPainter(p, step),
  );
}

class _PayPalStepPainter extends UnitPainter {
  const _PayPalStepPainter(super.p, this.step);

  final PayPalStep step;

  // Screen area inside the phone, unit space (width 100, height 125).
  static const _screen = Rect.fromLTWH(27, 12, 46, 101);

  @override
  bool shouldRepaint(covariant _PayPalStepPainter old) =>
      old.p != p || old.step != step;

  @override
  void paintUnits(Canvas canvas) {
    // Soft backdrop.
    canvas
      ..drawRRect(unitRRect(4, 6, 92, 113, 14), fillPaint(p.accentSoft))
      // Phone body and screen.
      ..drawRRect(unitRRect(23, 8, 54, 109, 8), fillPaint(p.ink))
      ..drawRRect(
        RRect.fromRectAndRadius(_screen, const Radius.circular(4.5)),
        fillPaint(p.surface),
      )
      ..drawRRect(unitRRect(43, 9.5, 14, 2, 1), fillPaint(p.inkMuted))
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(_screen, const Radius.circular(4.5)));
    final tap = switch (step) {
      PayPalStep.openApp => _home(canvas),
      PayPalStep.openSharing => _profile(canvas),
      PayPalStep.copyLink => _linkPage(canvas),
      PayPalStep.pasteLink => _paste(canvas),
    };
    canvas.restore();
    _tap(canvas, tap);
  }

  void _bar(Canvas c, double l, double t, double w, {bool strong = false}) =>
      c.drawRRect(
        unitRRect(l, t, w, 3.4, 1.7),
        fillPaint(strong ? p.line : p.lineSoft),
      );

  Offset _home(Canvas c) {
    c.drawRect(
      const Rect.fromLTWH(27, 12, 46, 16),
      fillPaint(p.surfaceMuted),
    );
    _bar(c, 32, 33, 24, strong: true);
    _bar(c, 32, 40, 34);
    // App grid: 3 x 3 rounded tiles; the profile tile is the tap target.
    for (var i = 0; i < 9; i++) {
      final x = 32 + (i % 3) * 14.0;
      final y = 52 + (i ~/ 3) * 15.0;
      c.drawRRect(
        unitRRect(x, y, 11, 11, 3),
        fillPaint(i == 2 ? p.accentSoft : p.surfaceMuted),
      );
    }
    c.drawCircle(const Offset(65.5, 57.5), 3, fillPaint(p.accent));
    return const Offset(65.5, 57.5);
  }

  Offset _profile(Canvas c) {
    c.drawCircle(const Offset(50, 26), 7, fillPaint(p.accentSoft));
    _bar(c, 38, 38, 24, strong: true);
    for (var i = 0; i < 4; i++) {
      final y = 50 + i * 14.0;
      final hot = i == 1;
      c.drawRRect(
        unitRRect(31, y, 38, 10, 3),
        fillPaint(hot ? p.accentSoft : p.surfaceMuted),
      );
      _bar(c, 35, y + 3.3, hot ? 22 : 16, strong: hot);
    }
    return const Offset(50, 69);
  }

  Offset _linkPage(Canvas c) {
    _bar(c, 33, 22, 22, strong: true);
    _bar(c, 33, 30, 32);
    // The link field.
    c
      ..drawRRect(unitRRect(31, 48, 38, 12, 3), fillPaint(p.surfaceMuted))
      ..drawRRect(unitRRect(31, 48, 38, 12, 3), strokePaint(p.line, 0.8));
    _bar(c, 34, 52.3, 24, strong: true);
    // Copy glyph: two overlapping squares.
    c
      ..drawRRect(unitRRect(60, 51, 5, 5, 1), strokePaint(p.ink, 0.9))
      ..drawRRect(unitRRect(61.8, 52.8, 5, 5, 1), fillPaint(p.surfaceMuted))
      ..drawRRect(unitRRect(61.8, 52.8, 5, 5, 1), strokePaint(p.ink, 0.9));
    _bar(c, 33, 72, 34);
    _bar(c, 33, 79, 26);
    return const Offset(62, 56);
  }

  Offset _paste(Canvas c) {
    _bar(c, 33, 22, 22, strong: true);
    c
      ..drawRRect(unitRRect(31, 40, 38, 12, 3), fillPaint(p.surface))
      ..drawRRect(unitRRect(31, 40, 38, 12, 3), strokePaint(p.accent, 1.4));
    _bar(c, 34, 44.3, 26, strong: true);
    // Check mark: the link landed.
    c
      ..drawCircle(const Offset(62, 46), 3, fillPaint(p.accent))
      ..drawPath(
        Path()
          ..moveTo(60.6, 46)
          ..lineTo(61.7, 47.2)
          ..lineTo(63.6, 44.8),
        strokePaint(p.onAccent, 0.9),
      )
      // Primary button.
      ..drawRRect(unitRRect(31, 92, 38, 11, 5.5), fillPaint(p.accent))
      ..drawRRect(unitRRect(40, 95.3, 20, 3.4, 1.7), fillPaint(p.onAccent));
    return const Offset(50, 97.5);
  }

  /// Highlighted tap: soft halo, ring and a finger-dot with a ripple.
  void _tap(Canvas c, Offset at) {
    c
      ..drawCircle(at, 11, fillPaint(p.accent.withValues(alpha: 0.18)))
      ..drawCircle(at, 7.5, strokePaint(p.accent, 1.8))
      ..drawCircle(at, 2.6, fillPaint(p.accent));
  }
}
