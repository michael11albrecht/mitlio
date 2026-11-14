import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/export/data/export_services.dart';
import 'package:mitlio/features/export/data/pdf_renderer.dart';
import 'package:mitlio/features/export/data/report_builder.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The side effects of exporting: rendering the PDF and handing a file to
/// the share sheet.
abstract interface class ExportActionsRepository {
  Future<RepoResult<Uint8List>> renderPdf(ReportModel report);

  Future<RepoResult<void>> shareFile({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  });
}

/// Bundled font + `pdf` + share sheet.
class PlatformExportActionsRepository implements ExportActionsRepository {
  PlatformExportActionsRepository({
    required this._fonts,
    required this._share,
  });

  final ReportFontLoader _fonts;
  final ExportShareService _share;

  @override
  Future<RepoResult<Uint8List>> renderPdf(ReportModel report) => guardStorage(
    () async => Ok(await renderReportPdf(report, await _fonts.load())),
  );

  @override
  Future<RepoResult<void>> shareFile({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) => guardStorage(() async {
    await _share.shareFile(name: name, mimeType: mimeType, bytes: bytes);
    return const Ok(null);
  });
}

/// Real platform actions by default; override with a fake in tests.
final exportActionsRepositoryProvider = Provider<ExportActionsRepository>(
  (ref) => PlatformExportActionsRepository(
    fonts: ref.watch(reportFontLoaderProvider),
    share: ref.watch(exportShareServiceProvider),
  ),
);
