import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';

/// Centre square crop, scaled down step by step until the PNG fits
/// [maxBytes]. Runs on the Flutter engine only: nothing is uploaded.
class SquareCropPhotoProcessor implements PhotoProcessor {
  const SquareCropPhotoProcessor({
    this.maxBytes = profilePhotoMaxBytes,
    this.sides = const [512, 384, 256, 192, 128, 96, 64],
  });

  final int maxBytes;

  /// Edge lengths to try, largest first.
  final List<int> sides;

  @override
  Future<Uint8List?> process(Uint8List raw) async {
    final ui.Image source;
    try {
      final codec = await ui.instantiateImageCodec(raw);
      source = (await codec.getNextFrame()).image;
      codec.dispose();
    } on Exception {
      // Not a picture: the caller tells the user, nothing is lost here.
      return null;
    }
    try {
      final edge = source.width < source.height ? source.width : source.height;
      final crop = Rect.fromLTWH(
        (source.width - edge) / 2,
        (source.height - edge) / 2,
        edge.toDouble(),
        edge.toDouble(),
      );
      // Never enlarge: start at the picture's own edge if it is smaller.
      final tries = [
        if (edge <= sides.first) edge,
        ...sides.where((side) => side < edge),
      ];
      for (final side in tries) {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawImageRect(
          source,
          crop,
          Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
          Paint()..filterQuality = FilterQuality.high,
        );
        final picture = recorder.endRecording();
        final scaled = await picture.toImage(side, side);
        final data = await scaled.toByteData(format: ui.ImageByteFormat.png);
        scaled.dispose();
        picture.dispose();
        if (data != null && data.lengthInBytes <= maxBytes) {
          return data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
        }
      }
      return null;
    } finally {
      source.dispose();
    }
  }
}
