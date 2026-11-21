import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Turns QR text into a PNG picture. Faked in tests.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class QrPngRenderer {
  Future<Uint8List> render(String data);
}

/// Black on white with a quiet zone, the way banking apps scan reliably (like
/// the QR on screen). Throws if the data does not fit a QR code or the image
/// cannot be encoded; callers turn that into an error message.
class PaintedQrPngRenderer implements QrPngRenderer {
  const PaintedQrPngRenderer();

  static const _qrSize = 768.0;
  static const _margin = 64.0;

  @override
  Future<Uint8List> render(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      eyeStyle: const QrEyeStyle(color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
    );
    const total = _qrSize + 2 * _margin;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        const Rect.fromLTWH(0, 0, total, total),
        Paint()..color = Colors.white,
      )
      ..translate(_margin, _margin);
    painter.paint(canvas, const Size(_qrSize, _qrSize));
    final image = await recorder.endRecording().toImage(
      total.toInt(),
      total.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('PNG encoding returned no data');
    return bytes.buffer.asUint8List();
  }
}

final qrPngRendererProvider = Provider<QrPngRenderer>(
  (ref) => const PaintedQrPngRenderer(),
);
