import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/export/data/export_services.dart';
import 'package:mitlio/features/profile/data/services/qr_png_renderer.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Hands a QR code to the share sheet as a picture.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class QrShareRepository {
  /// Renders [payload] as PNG and opens the share sheet with it. Fails with
  /// [Storage] if the image cannot be made or the sheet cannot open.
  Future<RepoResult<void>> sharePng(String payload);
}

/// `QrPainter` + `share_plus`.
class PlatformQrShareRepository implements QrShareRepository {
  PlatformQrShareRepository({required this._renderer, required this._share});

  final QrPngRenderer _renderer;
  final ExportShareService _share;

  @override
  Future<RepoResult<void>> sharePng(String payload) => guardStorage(() async {
    final png = await _renderer.render(payload);
    await _share.shareFile(
      name: 'mitlio-qr.png',
      mimeType: 'image/png',
      bytes: png,
    );
    return const Ok(null);
  });
}

final qrShareRepositoryProvider = Provider<QrShareRepository>(
  (ref) => PlatformQrShareRepository(
    renderer: ref.watch(qrPngRendererProvider),
    share: ref.watch(exportShareServiceProvider),
  ),
);
