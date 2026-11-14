import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/export/data/csv_builder.dart';
import 'package:mitlio/features/export/data/export_data.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'export_support.dart';

const _deShares = 'Anteil Anna;Anteil Ben';
const _deTaxi = 'Anna (2,50) / Ben (10,00);6,25;6,25';
const _enTaxi = 'Anna (2.50) / Ben (10.00),6.25,6.25';

void main() {
  test('German: ; separator, decimal comma, dd.MM.yyyy', () {
    expect(
      buildExpensesCsv(sampleData(), l10nOf('de')),
      [
        'Datum;Titel;Kategorie;Betrag;Währung;Bezahlt von;$_deShares',
        '05.03.2026;Abendessen;Essen;40,01;EUR;Anna (40,01);20,01;20,00',
        '07.03.2026;"\'=Taxi, ""Flughafen""";;12,50;EUR;$_deTaxi',
        '',
        'Salden',
        'Person;Saldo;Währung',
        'Anna;16,25;EUR',
        'Ben;-16,25;EUR',
        '',
      ].join('\r\n'),
    );
  });

  test('English: , separator, decimal point, ISO dates', () {
    expect(
      buildExpensesCsv(sampleData(), l10nOf('en')),
      [
        'Date,Title,Category,Amount,Currency,Paid by,Share Anna,Share Ben',
        '2026-03-05,Abendessen,Food,40.01,EUR,Anna (40.01),20.01,20.00',
        '2026-03-07,"\'=Taxi, ""Flughafen""",,12.50,EUR,$_enTaxi',
        '',
        'Balances',
        'Person,Balance,Currency',
        'Anna,16.25,EUR',
        'Ben,-16.25,EUR',
        '',
      ].join('\r\n'),
    );
  });

  test('quotes cells with the separator, quotes and line breaks', () {
    final csv = buildExpensesCsv(
      sampleData(annaName: 'A;nna\nX'),
      l10nOf('de'),
    );
    expect(csv, contains('"Anteil A;nna\nX"'));
    expect(csv, contains('"A;nna\nX (40,01)"'));
  });

  test('neutralises formula starts in names too', () {
    final csv = buildExpensesCsv(sampleData(annaName: '@anna'), l10nOf('en'));
    expect(csv, contains("Share '@anna"));
  });

  test('zero-decimal currency has no fraction', () {
    final csv = buildExpensesCsv(
      sampleData(currency: Currency.jpy),
      l10nOf('en'),
    );
    expect(csv, contains('2026-03-05,Abendessen,Food,4001,JPY,'));
  });

  test('no expenses: header and balances only', () {
    final data = sampleData();
    final empty = buildExpensesCsv(
      ExportData(
        group: data.group,
        members: data.members,
        expenses: const [],
        balances: data.balances,
        transfers: data.transfers,
      ),
      l10nOf('en'),
    );
    expect(empty.split('\r\n').first, startsWith('Date,Title'));
    expect(empty, isNot(contains('Abendessen')));
    expect(empty, contains('Anna,16.25,EUR'));
  });
}
