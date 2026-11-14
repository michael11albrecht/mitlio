// Renders the launcher icon and splash source PNGs from the brand mark
// painter (same geometry as assets/brand/icon.svg). Not part of `make test`;
// run by hand after changing the mark:
//
//   cd app && flutter test tool/render_brand_assets_test.dart
//
// then regenerate the platform files, see docs/brand.md.
import 'dart:io';
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
