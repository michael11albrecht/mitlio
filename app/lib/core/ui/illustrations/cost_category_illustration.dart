import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/illustrations/illustration.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// One picture per car cost category (ADR-25 §3), drawn on a soft disc.
class CostCategoryIllustration extends StatelessWidget {
  const CostCategoryIllustration({
    required this.category,
    required this.semanticLabel,
    this.size = 72,
    super.key,
  });

  final CostCategory category;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) => Illustration(
    semanticLabel: semanticLabel,
    width: size,
    painterBuilder: (p) => _CategoryPainter(p, category),
  );
}

class _CategoryPainter extends UnitPainter {
  const _CategoryPainter(super.p, this.category);

  final CostCategory category;

  @override
  bool shouldRepaint(covariant _CategoryPainter old) =>
      old.p != p || old.category != category;

  @override
  void paintUnits(Canvas canvas) {
    canvas.drawCircle(const Offset(50, 50), 48, fillPaint(p.accentSoft));
    switch (category) {
      case CostCategory.insurance:
        _shield(canvas);
      case CostCategory.vehicleTax:
        _document(canvas);
      case CostCategory.maintenance:
        _wrench(canvas);
      case CostCategory.tyres:
        _tyre(canvas);
      case CostCategory.repairs:
        _spanners(canvas);
      case CostCategory.loan:
        _coins(canvas);
      case CostCategory.depreciation:
        _trendDown(canvas);
      case CostCategory.parking:
        _parking(canvas);
      case CostCategory.other:
        _dots(canvas);
    }
  }

  void _shield(Canvas c) {
    final shield = Path()
      ..moveTo(50, 20)
      ..lineTo(74, 28)
      ..quadraticBezierTo(74, 62, 50, 80)
      ..quadraticBezierTo(26, 62, 26, 28)
      ..close();
    c
      ..drawPath(shield, fillPaint(p.accent))
      ..drawPath(
        Path()
          ..moveTo(38, 49)
          ..lineTo(47, 58)
          ..lineTo(62, 40),
        strokePaint(p.onAccent, 5),
      );
  }

  void _document(Canvas c) {
    c
      ..drawRRect(unitRRect(30, 20, 40, 58, 5), fillPaint(p.surface))
      ..drawRRect(unitRRect(30, 20, 40, 58, 5), strokePaint(p.accent, 3))
      ..drawRRect(unitRRect(37, 30, 26, 4, 2), fillPaint(p.line))
      ..drawRRect(unitRRect(37, 40, 20, 4, 2), fillPaint(p.lineSoft))
      // Stamp.
      ..drawCircle(const Offset(56, 62), 9, strokePaint(p.warm, 3.2))
      ..drawCircle(const Offset(56, 62), 3, fillPaint(p.warm));
  }

  void _wrench(Canvas c) {
    c
      ..save()
      ..translate(50, 50)
      ..rotate(-0.78)
      ..drawLine(
        const Offset(0, -6),
        const Offset(0, 28),
        strokePaint(p.accent, 9),
      )
      ..drawCircle(const Offset(0, -20), 13, fillPaint(p.accent))
      ..drawRRect(unitRRect(-5, -36, 10, 18, 2), fillPaint(p.accentSoft))
      ..restore();
  }

  void _tyre(Canvas c) {
    const centre = Offset(50, 50);
    c
      ..drawCircle(centre, 28, fillPaint(p.ink))
      ..drawCircle(centre, 14, fillPaint(p.surfaceMuted))
      ..drawCircle(centre, 4, fillPaint(p.line));
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        centre + Offset.fromDirection(i * 1.2566, 5),
        centre + Offset.fromDirection(i * 1.2566, 13),
        strokePaint(p.line, 2.4),
      );
    }
  }

  void _spanners(Canvas c) {
    for (final angle in const [0.7, -0.7]) {
      c
        ..save()
        ..translate(50, 50)
        ..rotate(angle)
        ..drawRRect(unitRRect(-3.5, -26, 7, 52, 3.5), fillPaint(p.accent))
        ..drawCircle(const Offset(0, -26), 8, fillPaint(p.accent))
        ..drawCircle(const Offset(0, -28), 3.5, fillPaint(p.accentSoft))
        ..restore();
    }
  }

  void _coins(Canvas c) {
    for (var i = 0; i < 3; i++) {
      final y = 64.0 - i * 11;
      c
        ..drawOval(Rect.fromLTWH(26, y, 48, 16), fillPaint(p.warm))
        ..drawOval(Rect.fromLTWH(26, y, 48, 16), strokePaint(p.ink, 2.2));
    }
  }

  void _trendDown(Canvas c) {
    c
      ..drawLine(
        const Offset(26, 24),
        const Offset(26, 74),
        strokePaint(p.line, 3),
      )
      ..drawLine(
        const Offset(26, 74),
        const Offset(76, 74),
        strokePaint(p.line, 3),
      )
      ..drawPath(
        Path()
          ..moveTo(32, 32)
          ..lineTo(48, 48)
          ..lineTo(56, 42)
          ..lineTo(72, 62),
        strokePaint(p.accent, 5),
      )
      ..drawPath(
        Path()
          ..moveTo(60, 64)
          ..lineTo(73, 63)
          ..lineTo(72, 50),
        strokePaint(p.accent, 5),
      );
  }

  void _parking(Canvas c) {
    c
      ..drawRRect(unitRRect(28, 24, 44, 52, 8), fillPaint(p.accent))
      ..drawPath(
        Path()
          ..moveTo(43, 64)
          ..lineTo(43, 36)
          ..lineTo(53, 36)
          ..quadraticBezierTo(62, 36, 62, 44)
          ..quadraticBezierTo(62, 52, 53, 52)
          ..lineTo(43, 52),
        strokePaint(p.onAccent, 5.5),
      );
  }

  void _dots(Canvas c) {
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
        Offset(33 + i * 17.0, 50),
        6.5,
        fillPaint(i == 1 ? p.accent : p.line),
      );
    }
  }
}
