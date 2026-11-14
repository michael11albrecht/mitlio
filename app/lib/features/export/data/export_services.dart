import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/export/data/pdf_renderer.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with a file. Faked in tests.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class ExportShareService {
  Future<void> shareFile({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  });
}

/// `share_plus`: the native share sheet (or its platform fallback).
class SystemExportShareService implements ExportShareService {
  const SystemExportShareService();

  @override
  Future<void> shareFile({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: name)],
        fileNameOverrides: [name],
      ),
    );
  }
}

/// Loads the report font from the app bundle. Replaced in tests that have no
/// bundle.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class ReportFontLoader {
  Future<ReportFonts> load();
}

class AssetReportFontLoader implements ReportFontLoader {
  const AssetReportFontLoader();

  @override
  Future<ReportFonts> load() async => (
    regular: await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    bold: await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
  );
}

final exportShareServiceProvider = Provider<ExportShareService>(
  (ref) => const SystemExportShareService(),
);

final reportFontLoaderProvider = Provider<ReportFontLoader>(
  (ref) => const AssetReportFontLoader(),
);
