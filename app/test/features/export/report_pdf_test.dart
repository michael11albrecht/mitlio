import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/export/data/export_data.dart';
import 'package:mitlio/features/export/data/pdf_renderer.dart';
import 'package:mitlio/features/export/data/report_builder.dart';

import 'export_support.dart';

ByteData _font(String name) {
  final bytes = File('assets/fonts/$name').readAsBytesSync();
  return ByteData.sublistView(bytes);
}

void main() {
  group('report model', () {
    test('German: sections, totals, transfers, expenses', () {
      final r = buildReportModel(sampleData(), l10nOf('de'));
      expect(r.title, 'Abrechnung');
      expect(r.groupName, 'Rom');
      expect(r.period, 'Zeitraum: 05.03.2026 – 07.03.2026');
      expect(r.members, [
        'Anna · PayPal: anna',
        'Ben · IBAN DE89 •••• 3000',
      ]);
      expect(r.totalsHeader, ['Person', 'Bezahlt', 'Anteil', 'Saldo']);
      expect(r.totals, [
        ['Anna', '42,51 €', '26,26 €', '16,25 €'],
        ['Ben', '10,00 €', '26,25 €', '-16,25 €'],
      ]);
      expect(r.transfers.single.text, 'Ben → Anna 16,25 €');
      expect(r.expensesHeader, ['Datum', 'Titel', 'Bezahlt von', 'Betrag']);
      expect(r.expenses.first, [
        '05.03.2026',
        'Abendessen',
        'Anna',
        '40,01 €',
      ]);
      expect(r.expenses.last[2], 'Anna, Ben');
    });

    test('English labels', () {
      final r = buildReportModel(sampleData(), l10nOf('en'));
      expect(r.title, 'Settlement report');
      expect(r.period, 'Period: 2026-03-05 – 2026-03-07');
      expect(r.transfers.single.text, 'Ben → Anna €16.25');
    });

    test('settled group says so', () {
      final data = sampleData();
      final r = buildReportModel(
        ExportData(
          group: data.group,
          members: data.members,
          expenses: const [],
          balances: const {},
          transfers: const [],
        ),
        l10nOf('en'),
      );
      expect(r.transfers, isEmpty);
      expect(r.settledNote, 'All settled');
      expect(r.period, 'No expenses yet');
      expect(r.expenses, isEmpty);
    });

    test('shows the masked IBAN hint and never a full IBAN', () {
      final r = buildReportModel(sampleData(), l10nOf('en'));
      final text = [
        ...r.members,
        for (final row in r.totals) ...row,
        for (final t in r.transfers) t.text,
      ].join('\n');
      expect(text, contains('DE89 •••• 3000'));
      expect(text, isNot(matches(RegExp(r'[A-Z]{2}\d{2}\s?\d{4}\s?\d{4}'))));
    });
  });

  group('pdf', () {
    // The PDF text is glyph-encoded (embedded TTF) and rasterising needs a
    // native engine (`printing`/pdfium) that is not available headless, so
    // this is a structural test; the text itself is covered by the report
    // model tests above.
    final fonts = (
      regular: _font('Roboto-Regular.ttf'),
      bold: _font('Roboto-Bold.ttf'),
    );

    test('is a well-formed one page A4 document', () async {
      final report = buildReportModel(sampleData(), l10nOf('de'));
      final bytes = await renderReportPdf(report, fonts, compress: false);
      final text = String.fromCharCodes(bytes);
      expect(text, startsWith('%PDF-'));
      expect(text.trimRight(), endsWith('%%EOF'));
      expect(RegExp(r'/Type\s*/Page\b').allMatches(text), hasLength(1));
      expect(text, matches(RegExp(r'/MediaBox\s*\[0 0 595')));
      expect(text, contains('/Title'));
      expect(text, contains('Roboto-Regular'));
    });

    test('a long expense list flows onto more pages', () async {
      final data = sampleData();
      final long = buildReportModel(
        ExportData(
          group: data.group,
          members: data.members,
          expenses: [for (var i = 0; i < 120; i++) ...data.expenses],
          balances: data.balances,
          transfers: data.transfers,
        ),
        l10nOf('en'),
      );
      final bytes = await renderReportPdf(long, fonts, compress: false);
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(String.fromCharCodes(bytes)),
        hasLength(greaterThan(1)),
      );
    });

    test('full IBANs cannot reach the file', () async {
      final report = buildReportModel(sampleData(), l10nOf('de'));
      final bytes = await renderReportPdf(report, fonts, compress: false);
      expect(
        String.fromCharCodes(bytes),
        isNot(contains('DE89370400440532013000')),
      );
    });
  });
}
