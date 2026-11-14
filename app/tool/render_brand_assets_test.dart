// Renders the launcher icon and splash source PNGs from the brand mark
// painter (same geometry as assets/brand/icon.svg). Not part of `make test`;
// run by hand after changing the mark:
//
//   cd app && flutter test tool/render_brand_assets_test.dart
//
// then regenerate the platform files, see docs/brand.md.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/brand_mark.dart';

const _size = 1024;

Future<void> _render(
  String name,
  BrandMarkPainter painter, {
  int size = _size,
}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(
    Canvas(recorder),
    Size.square(size.toDouble()),
  );
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('assets/brand/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// The dev flavor icon: the mark lifted a little, an amber "dev" tag in the
/// opening of the gauge. Letters are strokes (no font in the test binding).
Future<void> _renderDev(String name, {required bool withBackground}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (withBackground) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1024, 1024),
      Paint()..color = MitlioPalette.lightAccent,
    );
  }
  canvas.translate(0, -60);
  const BrandMarkPainter(
    gauge: MitlioPalette.lightOnAccent,
    needle: MitlioPalette.lightAccentContainer,
  ).paint(canvas, const Size.square(1024));
  const tag = Offset(512, 860);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: tag, width: 300, height: 84),
      const Radius.circular(42),
    ),
    Paint()..color = MitlioColors.dark.avatars[1].background,
  );
  final ink = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 12
    ..color = MitlioColors.dark.avatars[1].foreground;
  const half = 21.0; // x-height / 2 of the letters
  // d
  final d = tag + const Offset(-84, 3);
  canvas
    ..drawCircle(d, half, ink)
    ..drawLine(
      d + const Offset(half, -half - 14),
      d + const Offset(half, half),
      ink,
    );
  // e: bar and an arc open at the lower right
  final e = tag + const Offset(0, 3);
  canvas
    ..drawLine(e + const Offset(-half, 0), e + const Offset(half, 0), ink)
    ..drawArc(
      Rect.fromCircle(center: e, radius: half),
      0,
      -math.pi * 7 / 4,
      false,
      ink,
    );
  // v
  final v = tag + const Offset(84, 3);
  canvas.drawPath(
    Path()
      ..moveTo(v.dx - half, v.dy - half)
      ..lineTo(v.dx, v.dy + half)
      ..lineTo(v.dx + half, v.dy - half),
    ink,
  );
  final image = await recorder.endRecording().toImage(_size, _size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('assets/brand/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render brand assets', (tester) async {
    await tester.runAsync(() async {
      // Launcher icon: full-bleed square, the stores round the corners.
      await _render(
        'icon',
        const BrandMarkPainter(
          background: MitlioPalette.lightAccent,
          gauge: MitlioPalette.lightOnAccent,
          needle: MitlioPalette.lightAccentContainer,
          cornerRadius: 0,
        ),
      );
      // Android adaptive icon foreground (background colour in the config).
      await _render(
        'icon_foreground',
        const BrandMarkPainter(
          gauge: MitlioPalette.lightOnAccent,
          needle: MitlioPalette.lightAccentContainer,
        ),
      );
      // Dev flavor: the same, with a "dev" tag.
      await _renderDev('icon_dev', withBackground: true);
      await _renderDev('icon_dev_foreground', withBackground: false);
      // Splash marks on the theme backgrounds.
      await _render(
        'splash_mark',
        const BrandMarkPainter(
          gauge: MitlioPalette.lightAccent,
          needle: MitlioPalette.lightOnAccentContainer,
        ),
      );
      await _render(
        'splash_mark_dark',
        const BrandMarkPainter(
          gauge: MitlioPalette.darkAccent,
          needle: MitlioPalette.darkOnAccentContainer,
        ),
      );
    });
  });
}
