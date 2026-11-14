import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';

/// The mitlio mark: an open gauge (the taxometer) with its needle. Geometry
/// is that of `assets/brand/icon.svg` (1024 units); keep both in step. v1
/// placeholder, see `docs/brand.md`.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = Sizes.brandMark, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: BrandMarkPainter(
          background: scheme.primary,
          gauge: scheme.onPrimary,
          needle: scheme.primaryContainer,
        ),
      ),
    );
  }
}

/// Paints the icon on a rounded square, or, with a null [background], only
/// the mark (launcher foreground, splash).
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({
    required this.gauge,
    required this.needle,
    this.background,
    this.cornerRadius = _corner,
  });

  final Color? background;

  /// In 1024 units; 0 for the full-bleed square the app stores want.
  final double cornerRadius;
  final Color gauge;
  final Color needle;

  static const _units = 1024.0;
  static const _centre = Offset(512, 560);
  static const _radius = 262.0;
  static const _gaugeStroke = 86.0;
  static const _needleStroke = 66.0;
  static const _needleLength = 200.0;
  static const _hubRadius = 64.0;
  static const _corner = 228.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _units, size.height / _units);
    final bg = background;
    if (bg != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, _units, _units),
          Radius.circular(cornerRadius),
        ),
        Paint()..color = bg,
      );
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // 270 degrees, open at the bottom, clockwise from the lower left.
    canvas.drawArc(
      Rect.fromCircle(center: _centre, radius: _radius),
      math.pi * 3 / 4,
      math.pi * 3 / 2,
      false,
      stroke
        ..color = gauge
        ..strokeWidth = _gaugeStroke,
    );
    final tip =
        _centre + Offset.fromDirection(-50 * math.pi / 180, _needleLength);
    canvas
      ..drawLine(
        _centre,
        tip,
        stroke
          ..color = needle
          ..strokeWidth = _needleStroke,
      )
      ..drawCircle(_centre, _hubRadius, Paint()..color = gauge);
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.background != background ||
      old.cornerRadius != cornerRadius ||
      old.gauge != gauge ||
      old.needle != needle;
}
