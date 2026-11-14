import 'dart:typed_data';

import 'package:mitlio/core/theme/pdf_theme.dart';
import 'package:mitlio/features/export/data/report_builder.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// TTF bytes of the report font. The built-in PDF fonts lack `€` and `→`.
typedef ReportFonts = ({ByteData regular, ByteData bold});

/// Lays out [report] as an A4 PDF.
Future<Uint8List> renderReportPdf(
  ReportModel report,
  ReportFonts fonts, {
  bool compress = true,
}) {
  final doc = pw.Document(
    compress: compress,
    title: '${report.title}: ${report.groupName}',
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(fonts.regular),
      bold: pw.Font.ttf(fonts.bold),
    ),
  );

  pw.Widget heading(String text) => pw.Padding(
    padding: PdfTheme.headingGap,
    child: pw.Text(text, style: PdfTheme.heading),
  );

  // "Ben -> Anna 12,40 €" with a drawn arrow: the font has no U+2192.
  pw.Widget transfer(ReportTransfer t) => pw.Row(
    children: [
      pw.Text(t.from, style: PdfTheme.body),
      pw.Padding(
        padding: PdfTheme.arrowGap,
        child: pw.CustomPaint(
          size: const PdfPoint(14, 8),
          painter: (canvas, size) => canvas
            ..setLineWidth(1)
            ..moveTo(0, size.y / 2)
            ..lineTo(size.x, size.y / 2)
            ..moveTo(size.x - 4, size.y)
            ..lineTo(size.x, size.y / 2)
            ..lineTo(size.x - 4, 0)
            ..strokePath(),
        ),
      ),
      pw.Text('${t.to}  ${t.amount}', style: PdfTheme.body),
    ],
  );

  pw.Widget table(
    List<String> header,
    List<List<String>> rows, {
    required Set<int> rightAligned,
  }) => pw.TableHelper.fromTextArray(
    headers: header,
    data: rows,
    cellStyle: PdfTheme.small,
    headerStyle: PdfTheme.tableHeader,
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    cellAlignments: {
      for (final i in rightAligned) i: pw.Alignment.centerRight,
    },
    headerAlignments: {
      for (final i in rightAligned) i: pw.Alignment.centerRight,
    },
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: PdfTheme.page,
      build: (_) => [
        pw.Text(report.title, style: PdfTheme.title),
        pw.Text(report.groupName, style: PdfTheme.subtitle),
        pw.Text(report.period, style: PdfTheme.small),
        heading(report.membersHeading),
        for (final line in report.members) pw.Text(line, style: PdfTheme.small),
        heading(report.totalsHeading),
        table(report.totalsHeader, report.totals, rightAligned: {1, 2, 3}),
        heading(report.transfersHeading),
        if (report.transfers.isEmpty)
          pw.Text(report.settledNote, style: PdfTheme.body),
        for (final t in report.transfers) transfer(t),
        heading(report.expensesHeading),
        table(report.expensesHeader, report.expenses, rightAligned: {3}),
      ],
    ),
  );
  return doc.save();
}
