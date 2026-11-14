import 'package:pdf/widgets.dart' as pw;

/// Text styles and spacing of the PDF settlement report (points, A4). The
/// report is paper, not a screen, so it has its own small set instead of the
/// screen tokens.
abstract final class PdfTheme {
  static const title = pw.TextStyle(
    fontSize: 22,
    fontWeight: pw.FontWeight.bold,
  );
  static const subtitle = pw.TextStyle(fontSize: 14);
  static const heading = pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
  );
  static const body = pw.TextStyle(fontSize: 12);
  static const small = pw.TextStyle(fontSize: 10);
  static const tableHeader = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  );

  static const page = pw.EdgeInsets.all(40);
  static const headingGap = pw.EdgeInsets.only(top: 16, bottom: 6);
  static const arrowGap = pw.EdgeInsets.symmetric(horizontal: 6);
}
