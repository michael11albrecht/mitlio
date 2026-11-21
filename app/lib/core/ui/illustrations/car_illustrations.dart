import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/illustrations/illustration.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Body shapes offered in the car setup. UI only: the domain does not know
/// about body types, it only needs consumption and fuel.
enum CarBodyType { compact, sedan, suv, van }

class CarTypeIllustration extends StatelessWidget {
  const CarTypeIllustration({
    required this.type,
    required this.semanticLabel,
    this.width = 120,
    super.key,
  });

  final CarBodyType type;
  final String semanticLabel;
  final double width;

  @override
  Widget build(BuildContext context) => Illustration(
    semanticLabel: semanticLabel,
    width: width,
    aspectRatio: 1.6,
    painterBuilder: (p) => _CarPainter(p, type),
  );
}

typedef _Shape = ({Path body, Path window, Offset light, List<double> wheels});

class _CarPainter extends UnitPainter {
  const _CarPainter(super.p, this.type);

  final CarBodyType type;

  @override
  bool shouldRepaint(covariant _CarPainter old) =>
      old.p != p || old.type != type;

  @override
  void paintUnits(Canvas canvas) {
    // Ground shadow.
    canvas.drawOval(
      const Rect.fromLTWH(8, 56, 84, 7),
      fillPaint(p.lineSoft.withValues(alpha: 0.6)),
    );
    final shape = switch (type) {
      CarBodyType.compact => _compact(),
      CarBodyType.sedan => _sedan(),
      CarBodyType.suv => _suv(),
      CarBodyType.van => _van(),
    };
    canvas
      ..drawPath(shape.body, fillPaint(p.accent))
      ..drawPath(shape.window, fillPaint(p.accentSoft))
      ..drawCircle(shape.light, 2.2, fillPaint(p.warm));
    for (final x in shape.wheels) {
      canvas
        ..drawCircle(Offset(x, 55), 8, fillPaint(p.ink))
        ..drawCircle(Offset(x, 55), 3.4, fillPaint(p.surfaceMuted));
    }
  }

  static _Shape _compact() => (
    body: _rr(10, 28, 80, 26, 8)..addRRect(unitRRect(24, 14, 46, 22, 10)),
    window: _rr(29, 19, 36, 14, 5),
    light: const Offset(86, 40),
    wheels: const [28, 72],
  );

  static _Shape _sedan() => (
    body: _rr(6, 34, 88, 20, 7)..addRRect(unitRRect(26, 20, 44, 22, 9)),
    window: _rr(31, 25, 34, 12, 4),
    light: const Offset(90, 42),
    wheels: const [26, 76],
  );

  static _Shape _suv() => (
    body: _rr(8, 26, 84, 30, 7)..addRRect(unitRRect(16, 11, 62, 24, 8)),
    window: _rr(22, 16, 50, 14, 4),
    light: const Offset(88, 40),
    wheels: const [27, 73],
  );

  static _Shape _van() => (
    body: _rr(8, 14, 84, 42, 8),
    window: _rr(14, 20, 62, 14, 4),
    light: const Offset(88, 46),
    wheels: const [27, 73],
  );

  static Path _rr(double l, double t, double w, double h, double r) =>
      Path()..addRRect(unitRRect(l, t, w, h, r));
}

/// Fuel type icon for the fuel grid: pump with a petrol/diesel drop, an
/// electric bolt or a generic can.
class FuelIllustration extends StatelessWidget {
  const FuelIllustration({
    required this.fuel,
    required this.semanticLabel,
    this.size = 72,
    super.key,
  });

  final FuelType fuel;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) => Illustration(
    semanticLabel: semanticLabel,
    width: size,
    painterBuilder: (p) => _FuelPainter(p, fuel),
  );
}

class _FuelPainter extends UnitPainter {
  const _FuelPainter(super.p, this.fuel);

  final FuelType fuel;

  @override
  bool shouldRepaint(covariant _FuelPainter old) =>
      old.p != p || old.fuel != fuel;

  @override
  void paintUnits(Canvas canvas) {
    canvas.drawCircle(const Offset(50, 50), 48, fillPaint(p.accentSoft));
    switch (fuel) {
      case FuelType.petrol:
        _pump(canvas, p.accent);
      case FuelType.diesel:
        _pump(canvas, p.ink);
      case FuelType.electric:
        _bolt(canvas);
      case FuelType.other:
        _can(canvas);
    }
  }

  void _pump(Canvas c, Color tone) {
    c
      ..drawRRect(unitRRect(28, 24, 28, 52, 4), fillPaint(tone))
      ..drawRRect(unitRRect(33, 30, 18, 12, 2), fillPaint(p.surface))
      ..drawRRect(unitRRect(24, 74, 36, 5, 2), fillPaint(tone))
      // Hose and nozzle.
      ..drawPath(
        Path()
          ..moveTo(56, 40)
          ..lineTo(66, 40)
          ..lineTo(66, 62)
          ..lineTo(72, 62)
          ..lineTo(72, 36)
          ..lineTo(66, 28),
        strokePaint(tone, 3.2),
      )
      // Drop on the display.
      ..drawPath(
        Path()
          ..moveTo(42, 32)
          ..quadraticBezierTo(46, 38, 42, 40)
          ..quadraticBezierTo(38, 38, 42, 32),
        fillPaint(tone),
      );
  }

  void _bolt(Canvas c) {
    final bolt = Path()
      ..moveTo(56, 16)
      ..lineTo(30, 54)
      ..lineTo(47, 54)
      ..lineTo(42, 84)
      ..lineTo(70, 44)
      ..lineTo(52, 44)
      ..close();
    c
      ..drawPath(bolt, fillPaint(p.warm))
      ..drawPath(bolt, strokePaint(p.ink, 2.4));
  }

  void _can(Canvas c) {
    c
      ..drawRRect(unitRRect(30, 32, 38, 46, 6), fillPaint(p.accent))
      ..drawRRect(unitRRect(40, 22, 18, 10, 3), fillPaint(p.accent))
      ..drawPath(
        Path()
          ..moveTo(58, 26)
          ..lineTo(76, 20)
          ..lineTo(76, 30),
        strokePaint(p.accent, 3.2),
      )
      ..drawCircle(const Offset(49, 56), 9, fillPaint(p.onAccent));
  }
}
