import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/illustrations/illustration.dart';

/// The bank-transfer step: a bank card with the IBAN in four groups next to
/// the QR code a friend would scan. Purely a picture: the QR is a fixed
/// pattern, never scannable and never derived from real data.
class IbanQrIllustration extends StatelessWidget {
  const IbanQrIllustration({
    required this.semanticLabel,
    this.width = 200,
    super.key,
  });

  final String semanticLabel;
  final double width;

  @override
  Widget build(BuildContext context) => Illustration(
    semanticLabel: semanticLabel,
    width: width,
    aspectRatio: 1.6,
    painterBuilder: _IbanQrPainter.new,
  );
}

class _IbanQrPainter extends UnitPainter {
  const _IbanQrPainter(super.p);

  // 9 x 9 module pattern, '#' is dark. Three finder patterns plus filler.
  static const _modules = [
    '#######.#',
    '#.....#..',
    '#.###.#.#',
    '#.###.#..',
    '#.###.#.#',
    '#.....#..',
    '#######.#',
    '.#..#.#..',
    '#..#.#.##',
  ];

  @override
  void paintUnits(Canvas canvas) {
    // Card.
    canvas
      ..drawRRect(unitRRect(2, 8, 58, 44, 6), fillPaint(p.accentSoft))
      ..drawRRect(unitRRect(2, 8, 58, 44, 6), strokePaint(p.accent, 1.2))
      ..drawRect(const Rect.fromLTWH(3, 16, 56, 7), fillPaint(p.accent))
      // Chip.
      ..drawRRect(unitRRect(8, 28, 9, 7, 1.8), fillPaint(p.warm));
    // IBAN as four groups of dashes.
    for (var g = 0; g < 4; g++) {
      canvas.drawRRect(
        unitRRect(8 + g * 13.0, 41, 10, 3, 1.5),
        fillPaint(p.onAccentSoft),
      );
    }
    // Arrow card -> QR.
    canvas
      ..drawLine(
        const Offset(62, 30),
        const Offset(68, 30),
        strokePaint(p.accent, 1.6),
      )
      ..drawPath(
        Path()
          ..moveTo(66, 27.5)
          ..lineTo(68.5, 30)
          ..lineTo(66, 32.5),
        strokePaint(p.accent, 1.6),
      )
      // QR tile.
      ..drawRRect(unitRRect(70, 6, 28, 28, 4), fillPaint(p.surface))
      ..drawRRect(unitRRect(70, 6, 28, 28, 4), strokePaint(p.line, 1));
    const cell = 2.4;
    const origin = Offset(73.2, 9.2);
    for (var y = 0; y < _modules.length; y++) {
      for (var x = 0; x < _modules[y].length; x++) {
        if (_modules[y][x] != '#') continue;
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + x * cell,
            origin.dy + y * cell,
            cell + 0.05,
            cell + 0.05,
          ),
          fillPaint(p.ink),
        );
      }
    }
    // Caption bars under the QR.
    canvas
      ..drawRRect(unitRRect(72, 40, 24, 3, 1.5), fillPaint(p.line))
      ..drawRRect(unitRRect(76, 46, 16, 3, 1.5), fillPaint(p.lineSoft));
  }
}
