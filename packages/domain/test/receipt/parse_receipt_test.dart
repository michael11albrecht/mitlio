import 'dart:math';

import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/no_shrink.dart';

ReceiptDraft parse(List<String> lines) =>
    parseReceipt([for (final l in lines) ReceiptLine(l)]);

int? total(List<String> lines) => parse(lines).totalCents.value;

void main() {
  group('amount formats (via SUMME)', () {
    const cases = <String, int>{
      'SUMME 12,34': 1234,
      'SUMME 12.34': 1234,
      'SUMME EUR 0,99': 99,
      'SUMME 1.234,56': 123456,
      'SUMME 1,234.56': 123456,
      "SUMME 1'234.56": 123456,
      'SUMME 1 234,56': 123456,
      'SUMME 12.345.678,90': 1234567890,
      'SUMME 12,34 EUR': 1234,
      'SUMME 12,34€': 1234,
      'SUMME € 12,34': 1234,
      'SUMME 3 x 2,00 6,00': 600,
      'SUMME 5,00 A': 500,
    };
    cases.forEach((line, cents) {
      test(line, () => expect(total([line]), cents));
    });

    const rejected = [
      'SUMME 12', // no decimals
      'SUMME 1,5', // one decimal
      'SUMME 1,234', // three decimals: not money
      'SUMME 1.234.56', // separator reused as decimal
      "SUMME 1.234'567,89", // mixed thousands separators
      'SUMME 0,00', // zero is never a total
      'SUMME -5,00', // negative
      'SUMME 5,00-', // trailing minus
      'SUMME 19,00 %', // percentage
      'SUMME 45,32 l', // litres
      'SUMME 3,00 kg',
      'SUMME 1234567890,00', // implausibly large
      'SUMME 12.03.2024', // a date, not an amount
    ];
    for (final line in rejected) {
      test('rejects "$line"', () => expect(total([line]), isNull));
    }
  });

  group('total keywords', () {
    for (final kw in [
      'SUMME',
      'Gesamt',
      'GESAMTBETRAG',
      'Gesamtsumme',
      'zu zahlen',
      'Zahlbetrag',
      'Endbetrag',
      'TOTAL',
      'Grand Total',
      'Amount due',
      'Balance due',
      'To pay',
    ]) {
      test(kw, () => expect(total(['$kw 7,50']), 750));
    }

    test('keyword and amount on separate lines', () {
      expect(total(['zu zahlen', '9,99']), 999);
      expect(total(['SUMME', 'EUR 9,99']), 999);
    });

    test('keyword followed by a text row takes no amount from it', () {
      expect(total(['SUMME', 'Vielen Dank 9,99']), isNull);
    });

    test('amount-only row must not hold other words', () {
      expect(total(['SUMME', 'Brot 9,99']), isNull);
    });

    test('rightmost amount on the row wins', () {
      expect(total(['SUMME 3 Artikel 2,00 6,00']), 600);
    });

    test('excluded rows are never the total', () {
      for (final bad in [
        'Zwischensumme 10,00',
        'Teilsumme 10,00',
        'Subtotal 10,00',
        'Netto Gesamt 10,00',
        'Total VAT 10,00',
        'Total tax 10,00',
        'MwSt Summe 10,00',
        'USt Gesamt 10,00',
        'Steuer Summe 10,00',
        'Rückgeld Gesamt 10,00',
        'Rueckgeld Summe 10,00',
        'Change Total 10,00',
        'Gegeben Summe 10,00',
        'Total discount 10,00',
        'Rabatt Summe 10,00',
        'Gesamtersparnis 10,00',
        'Total points 10,00',
        'Bonus Summe 10,00',
      ]) {
        expect(total([bad]), isNull, reason: bad);
      }
    });

    test('keyword matching ignores case and needs word boundaries', () {
      expect(total(['summe 1,00']), 100);
      expect(total(['Obersummen 1,00']), isNull);
      expect(total(['TotalEnergies 1,00']), isNull);
    });

    test('change and tender rows do not disturb the total', () {
      expect(
        total(['Brot 4,00', 'SUMME 4,00', 'Bar 20,00', 'Rückgeld 16,00']),
        400,
      );
      expect(
        total(['Brot 4,00', 'SUMME 4,00', 'Cash 20,00', 'Change 16,00']),
        400,
      );
    });

    test('largest of several strong candidates, with lower confidence', () {
      final d = parse(['Summe 10,00', 'Total 12,00']);
      expect(d.totalCents.value, 1200);
      expect(d.totalCents.confidence, 60);
    });

    test('an amount from a total row above the line items is still found', () {
      expect(total(['GESAMT 5,00', 'Brot 5,00']), 500);
    });
  });

  group('total confidence', () {
    test('strong keyword alone', () {
      expect(parse(['SUMME 5,00']).totalCents, const ReceiptField(500, 85));
    });

    test('confirmed by a card line', () {
      expect(
        parse(['SUMME 5,00', 'EC-Karte 5,00']).totalCents,
        const ReceiptField(500, 95),
      );
    });

    test('card line with another amount does not confirm', () {
      expect(
        parse(['SUMME 5,00', 'Visa 4,00']).totalCents,
        const ReceiptField(500, 85),
      );
    });

    test('confirmed by the sum of line items', () {
      expect(
        parse(['Brot 2,00', 'Milch 3,00', 'SUMME 5,00']).totalCents,
        const ReceiptField(500, 90),
      );
    });

    test('confirmed by items and card', () {
      expect(
        parse(['Brot 2,00', 'Milch 3,00', 'SUMME 5,00', 'Mastercard 5,00'])
            .totalCents,
        const ReceiptField(500, 100),
      );
    });

    test('item larger than the total lowers confidence', () {
      expect(
        parse(['Gutschein 9,00', 'SUMME 5,00']).totalCents,
        const ReceiptField(500, 60),
      );
    });

    test('item larger than total and disagreeing candidates: empty', () {
      expect(
        parse(['Ding 50,00', 'Summe 5,00', 'Total 6,00']).totalCents.value,
        isNull,
      );
    });

    test('item rows with several amounts or excluded words are not items', () {
      expect(
        parse(['2 x 20,00 40,00', 'Netto 90,00', 'SUMME 5,00']).totalCents,
        const ReceiptField(500, 85),
      );
    });

    test('only rows above the first keyword count as items', () {
      expect(
        parse(['SUMME 5,00', 'Brot 9,00']).totalCents,
        const ReceiptField(500, 85),
      );
    });

    test('card keywords', () {
      for (final kw in [
        'EC',
        'EC-Karte',
        'EC-Cash',
        'Girocard',
        'Karte',
        'Kartenzahlung',
        'Visa',
        'Mastercard',
        'Maestro',
        'Card',
      ]) {
        expect(parse(['$kw 5,00']).totalCents, const ReceiptField(500, 60));
      }
    });

    test('weak total confirmed twice', () {
      expect(
        parse(['Visa 5,00', 'Karte 5,00']).totalCents,
        const ReceiptField(500, 70),
      );
    });

    test('weak candidates that disagree: empty', () {
      expect(parse(['Visa 5,00', 'Bar 6,00']).totalCents.value, isNull);
    });

    test('cash is only a hint without a change row', () {
      expect(parse(['Bar 5,00']).totalCents, const ReceiptField(500, 60));
      expect(parse(['Cash 5,00']).totalCents, const ReceiptField(500, 60));
      expect(parse(['Bar 20,00', 'Rückgeld 5,00']).totalCents.value, isNull);
    });

    test('no keyword: never guesses the largest amount', () {
      expect(total(['Zeitung 2,50', 'Kaffee 1,90']), isNull);
    });

    test('keyword without any amount', () {
      expect(total(['SUMME']), isNull);
      expect(total(['SUMME', 'danke']), isNull);
      expect(total(['SUMME']), isNull);
    });
  });

  group('date', () {
    DateTime? date(List<String> lines) => parse(lines).date.value;

    test('dd.MM.yyyy', () {
      expect(date(['12.03.2024']), DateTime.utc(2024, 3, 12));
    });

    test('d.M.yyyy', () {
      expect(date(['2.3.2024']), DateTime.utc(2024, 3, 2));
    });

    test('dd.MM.yy', () {
      expect(date(['12.03.24']), DateTime.utc(2024, 3, 12));
    });

    test('yyyy-MM-dd', () {
      expect(date(['2024-03-12']), DateTime.utc(2024, 3, 12));
    });

    test('date embedded in text with time', () {
      expect(date(['Datum: 01.02.2025 12:30']), DateTime.utc(2025, 2));
      expect(date(['TA 7 01.02.2025 12:30 K1']), DateTime.utc(2025, 2));
    });

    test('leap day', () {
      expect(date(['29.02.2024']), DateTime.utc(2024, 2, 29));
      expect(date(['29.02.2023']), isNull);
    });

    test('invalid calendar dates are empty', () {
      for (final bad in [
        '31.02.2024',
        '00.01.2024',
        '32.01.2024',
        '01.13.2024',
        '01.00.2024',
        '2024-02-30',
        '2024-13-01',
        '1999-12-31',
        '01.01.1999',
        '01.01.2100',
      ]) {
        expect(date([bad]), isNull, reason: bad);
      }
    });

    test('boundaries of the plausible year range', () {
      expect(date(['01.01.2000']), DateTime.utc(2000));
      expect(date(['31.12.2099']), DateTime.utc(2099, 12, 31));
    });

    test('digits around the date are not part of it', () {
      expect(date(['112.03.2024']), isNull);
      expect(date(['12.03.20245']), isNull);
      expect(date(['12.03.202']), isNull);
      expect(date(['02024-03-12']), isNull);
      expect(date(['2024-03-123']), isNull);
    });

    test('same date twice: confident', () {
      final d = parse(['12.03.2024', '2024-03-12']).date;
      expect(d, ReceiptField(DateTime.utc(2024, 3, 12), 90));
    });

    test('different dates: first one, lower confidence', () {
      final d = parse(['12.03.2024', 'MHD 20.03.2024']).date;
      expect(d, ReceiptField(DateTime.utc(2024, 3, 12), 75));
    });

    test('row with a date keyword wins', () {
      for (final kw in ['Datum', 'Date', 'Zeit', 'Time']) {
        final d = parse(['MHD 20.03.2024', '$kw 12.03.2024']).date;
        expect(d, ReceiptField(DateTime.utc(2024, 3, 12), 90));
      }
    });

    test('left to right within a row', () {
      expect(
        date(['2024-03-12 oder 13.04.2024']),
        DateTime.utc(2024, 3, 12),
      );
      expect(
        date(['13.04.2024 oder 2024-03-12']),
        DateTime.utc(2024, 4, 13),
      );
    });

    test('no date', () {
      expect(parse(['Brot']).date.isEmpty, isTrue);
    });
  });

  group('currency', () {
    Currency? cur(List<String> lines) => parse(lines).currency.value;

    test('codes and symbols', () {
      expect(cur(['SUMME 1,00 EUR']), Currency.eur);
      expect(cur(['SUMME 1,00 €']), Currency.eur);
      expect(cur(['Total CHF 1.00']), Currency.chf);
      expect(cur(['Total USD 1.00']), Currency.usd);
      expect(cur(['Total £1.00']), Currency.gbp);
      expect(cur(['Total 1.00 GBP']), Currency.gbp);
      expect(cur(['Total 100 SEK']), Currency.sek);
    });

    test('dollar sign is a weak USD guess', () {
      expect(
        parse([r'Total $ 1.00']).currency,
        const ReceiptField(Currency.usd, 55),
      );
      expect(
        parse([r'Total 1.00$']).currency,
        const ReceiptField(Currency.usd, 55),
      );
      expect(cur([r'$$$']), isNull);
    });

    test('explicit code beats dollar sign', () {
      expect(cur([r'Total CAD $ 1.00']), Currency.cad);
    });

    test('most frequent wins, tie is empty', () {
      expect(cur(['EUR 1,00', 'EUR 2,00', 'CHF 3,00']), Currency.eur);
      expect(cur(['EUR 1,00', 'CHF 3,00']), isNull);
    });

    test('confidence', () {
      expect(parse(['EUR']).currency.confidence, 90);
    });

    test('lowercase and embedded codes are not currencies', () {
      expect(cur(['eur 1,00']), isNull);
      expect(cur(['EURO 1,00']), isNull);
      expect(cur(['XEUR 1,00']), isNull);
      expect(cur(['Brot']), isNull);
    });
  });

  group('merchant and category', () {
    test('known chains, case-insensitive, canonical name', () {
      const cases = {
        'rewe markt': ('REWE', ReceiptCategory.groceries),
        'EDEKA Müller': ('EDEKA', ReceiptCategory.groceries),
        'Aldi Süd': ('ALDI', ReceiptCategory.groceries),
        'LIDL': ('Lidl', ReceiptCategory.groceries),
        'PENNY Markt': ('Penny', ReceiptCategory.groceries),
        'Netto Marken-Discount': ('Netto', ReceiptCategory.groceries),
        'Kaufland': ('Kaufland', ReceiptCategory.groceries),
        'tegut...': ('tegut', ReceiptCategory.groceries),
        "denn's Biomarkt": ("denn's Biomarkt", ReceiptCategory.groceries),
        'dm-drogerie markt': ('dm', ReceiptCategory.drugstore),
        'dm': ('dm', ReceiptCategory.drugstore),
        'Rossmann': ('Rossmann', ReceiptCategory.drugstore),
        'Shell': ('Shell', ReceiptCategory.fuel),
        'ARAL Tankstelle': ('Aral', ReceiptCategory.fuel),
        'Esso': ('Esso', ReceiptCategory.fuel),
        'JET': ('JET', ReceiptCategory.fuel),
        'OMV': ('OMV', ReceiptCategory.fuel),
        'AGIP': ('Agip', ReceiptCategory.fuel),
        'HEM': ('HEM', ReceiptCategory.fuel),
        'TotalEnergies': ('TotalEnergies', ReceiptCategory.fuel),
        'Total Energies': ('TotalEnergies', ReceiptCategory.fuel),
        "McDonald's": ("McDonald's", ReceiptCategory.restaurant),
        'Mc Donalds': ("McDonald's", ReceiptCategory.restaurant),
        'Burger King': ('Burger King', ReceiptCategory.restaurant),
        'Starbucks': ('Starbucks', ReceiptCategory.restaurant),
      };
      cases.forEach((line, expected) {
        final d = parse(['Willkommen', line, 'SUMME 1,00']);
        expect(d.merchant, ReceiptField(expected.$1, 95), reason: line);
        expect(d.category, ReceiptField(expected.$2, 90), reason: line);
      });
    });

    test('chain is only looked for in the first ten rows', () {
      final lines = [for (var i = 0; i < 10; i++) '###', 'REWE'];
      expect(parse(lines).merchant.isEmpty, isTrue);
      final nine = [for (var i = 0; i < 9; i++) '###', 'REWE'];
      expect(parse(nine).merchant.value, 'REWE');
    });

    test('chain name on a row with an amount is not the merchant', () {
      expect(
        parse(['Brot 1,00', 'Netto 10,00', 'SUMME 1,00']).merchant.isEmpty,
        isTrue,
      );
    });

    test('unknown shop: first plausible top row', () {
      final d = parse(['  *** Kiosk am Eck ***  ', 'Brot 1,00']);
      expect(d.merchant, const ReceiptField('Kiosk am Eck', 60));
      expect(d.category.isEmpty, isTrue);
    });

    test('whitespace is collapsed and junk trimmed', () {
      expect(
        parse(['-- Bäcker   Schmidt --']).merchant.value,
        'Bäcker Schmidt',
      );
      expect(parse(['Café Luna (Mitte)']).merchant.value, 'Café Luna (Mitte)');
      expect(parse(['Zum Löwen Inc.']).merchant.value, 'Zum Löwen Inc.');
    });

    test('only the first five rows are candidates', () {
      final lines = [for (var i = 0; i < 5; i++) '###', 'Bäcker Schmidt'];
      expect(parse(lines).merchant.isEmpty, isTrue);
      final four = [for (var i = 0; i < 4; i++) '###', 'Bäcker Schmidt'];
      expect(parse(four).merchant.value, 'Bäcker Schmidt');
    });

    test('implausible rows are skipped', () {
      for (final bad in [
        'ab', // too few letters
        'Kassenbon',
        'Beleg 123',
        'Rechnung',
        'Quittung',
        'Receipt',
        'Invoice',
        'Tel 0123',
        'Telefon',
        'www.shop.de',
        'http://shop.de',
        'info@shop.de',
        'USt-IdNr DE123',
        'Steuernr 12',
        'Hauptstr 5',
        'Hauptstraße 5',
        'Hauptstrasse 5',
        'Marktplatz',
        '12345 Stadt',
        'Willkommen',
        'Welcome',
        'Vielen Dank',
        'Thank you',
        'Musterweg 1 ab 12.03.2024',
        'Zeit 2024-03-12 ab',
        'Brot 1,00',
        'Summe',
        'Girocard',
        '12345 abc 67890 1',
        'A very long shop name that goes beyond forty chars',
      ]) {
        expect(parse([bad]).merchant.isEmpty, isTrue, reason: bad);
      }
    });

    test('plausible row boundary: digits at most half the letters', () {
      expect(parse(['Shop 24 ab']).merchant.value, 'Shop 24 ab');
      expect(parse(['abc 12']).merchant.isEmpty, isTrue);
      expect(parse(['abcd 12']).merchant.value, 'abcd 12');
    });

    test('length boundary', () {
      final ok = 'a' * 40;
      expect(parse([ok]).merchant.value, ok);
      expect(parse(['${ok}a']).merchant.isEmpty, isTrue);
    });

    test('junk-only row gives no merchant', () {
      expect(parse(['…']).merchant.isEmpty, isTrue);
    });

    test('category keywords without a known chain', () {
      const cases = {
        'Rosen-Apotheke': ReceiptCategory.pharmacy,
        'City Pharmacy': ReceiptCategory.pharmacy,
        'Pharmacie Centrale': ReceiptCategory.pharmacy,
        'Restaurant Adler': ReceiptCategory.restaurant,
        'Gasthaus Adler': ReceiptCategory.restaurant,
        'Gasthof Adler': ReceiptCategory.restaurant,
        'Ristorante Roma': ReceiptCategory.restaurant,
        'Pizzeria Roma': ReceiptCategory.restaurant,
        'Trattoria Roma': ReceiptCategory.restaurant,
        'Bistro Roma': ReceiptCategory.restaurant,
        'Imbiss Roma': ReceiptCategory.restaurant,
        'Café Roma': ReceiptCategory.restaurant,
        'Cafe Roma': ReceiptCategory.restaurant,
        'Bewirtungsbeleg': ReceiptCategory.restaurant,
        'Tankstelle Meier': ReceiptCategory.fuel,
        'Diesel 1,799': ReceiptCategory.fuel,
        'Super E10': ReceiptCategory.fuel,
        'Super E5': ReceiptCategory.fuel,
        'Benzin': ReceiptCategory.fuel,
        'Zapfsäule 3': ReceiptCategory.fuel,
        'Zapfsaeule 3': ReceiptCategory.fuel,
      };
      cases.forEach((line, cat) {
        expect(
          parse(['###', line]).category,
          ReceiptField(cat, 70),
          reason: line,
        );
      });
    });

    test('first matching category wins', () {
      expect(
        parse(['Apotheke am Café']).category.value,
        ReceiptCategory.pharmacy,
      );
      expect(
        parse(['Café', 'Diesel']).category.value,
        ReceiptCategory.restaurant,
      );
    });

    test('chain category beats keyword category', () {
      expect(
        parse(['REWE', 'Apotheke']).category,
        const ReceiptField(ReceiptCategory.groceries, 90),
      );
    });

    test('no category for unknown purchases', () {
      expect(parse(['Möbel Frei AG']).category.isEmpty, isTrue);
    });
  });

  group('boxes', () {
    ReceiptLine l(String t, double top, double left, [double h = 0.02]) =>
        ReceiptLine(
          t,
          box: ReceiptBox(
            left: left,
            top: top,
            right: left + 0.3,
            bottom: top + h,
          ),
        );

    test('label and amount on one visual row, input out of order', () {
      final d = parseReceipt([
        l('12,34', 0.5, 0.7),
        l('Brot', 0.3, 0.1),
        l('SUMME', 0.5, 0.1),
        l('Bäcker', 0.1, 0.1),
      ]);
      expect(d.totalCents.value, 1234);
    });

    test('rows are separated when centers do not overlap', () {
      final d = parseReceipt([
        l('SUMME', 0.5, 0.1),
        l('Brot 7,00', 0.52, 0.1),
        l('9,00', 0.52, 0.7),
      ]);
      expect(d.totalCents.value, isNull);
    });

    test('same top sorts by left', () {
      final d = parseReceipt([l('5,00', 0.5, 0.7), l('SUMME', 0.5, 0.1)]);
      expect(d.totalCents.value, 500);
    });

    test('line joining uses the first line of a row as anchor', () {
      final d = parseReceipt([
        l('SUMME', 0.5, 0.1, 0.1),
        l('x 5,00', 0.59, 0.5, 0.01),
      ]);
      expect(d.totalCents.value, 500);
      final e = parseReceipt([
        l('SUMME', 0.5, 0.1, 0.1),
        l('x 5,00', 0.61, 0.5, 0.01),
      ]);
      expect(e.totalCents.value, isNull);
    });

    test('tallest plausible top row is the merchant', () {
      final d = parseReceipt([
        l('Kleine Zeile', 0, 0.1),
        l('Grosser Laden', 0.1, 0.1, 0.06),
        l('Noch kleiner', 0.2, 0.1, 0.01),
      ]);
      expect(d.merchant, const ReceiptField('Grosser Laden', 70));
    });

    test('equal heights: first one', () {
      final d = parseReceipt([
        l('Erster', 0, 0.1, 0.25),
        l('Zweiter', 0.5, 0.1, 0.25),
      ]);
      expect(d.merchant.value, 'Erster');
    });

    test('mixed boxes fall back to input order', () {
      final d = parseReceipt([
        l('5,00', 0.1, 0.1),
        const ReceiptLine('SUMME'),
      ]);
      expect(d.totalCents.value, isNull);
      final e = parseReceipt([
        const ReceiptLine('Erster'),
        l('Hoher Zweiter', 0.1, 0.1, 0.5),
      ]);
      expect(e.merchant, const ReceiptField('Erster', 60));
    });

    test('box geometry', () {
      const b = ReceiptBox(left: 0, top: 0.2, right: 1, bottom: 0.6);
      expect(b.height, closeTo(0.4, 1e-9));
      expect(b.centerY, closeTo(0.4, 1e-9));
    });
  });

  group('robustness', () {
    test('empty input and blank lines', () {
      expect(parseReceipt(const []), const ReceiptDraft());
      expect(parse(['', '   ', '\n']), const ReceiptDraft());
    });

    test('very long lines and many lines are bounded', () {
      final long = 'SUMME ${'x' * 300} 1,00';
      expect(total([long]), isNull);
      expect(total(['SUMME 5,00'.padLeft(300)]), 500);
      final many = [for (var i = 0; i < 400; i++) 'Brot', 'SUMME 5,00'];
      expect(total(many), isNull);
      final fits = [for (var i = 0; i < 399; i++) 'Brot', 'SUMME 5,00'];
      expect(total(fits), 500);
    });

    test('hostile strings do not throw', () {
      for (final s in [
        '\u0000\u0001',
        '99999999999999999999,99',
        '${'9' * 500},99',
        '1.' * 200,
        r'€€€€ $$$ ££££',
        'SUMME ${'1.234' * 100},00',
        '00.00.0000',
        '0000-00-00',
        '\u{1F600} SUMME 1,00 \u{1F600}',
        'Ω≈ç√∫',
      ]) {
        expect(() => parse([s]), returnsNormally, reason: s);
      }
    });

    test('integer overflow guard: nine integer digits at most', () {
      expect(total(['SUMME 999999999,99']), 99999999999);
      expect(total(['SUMME 1000000000,00']), isNull);
    });
  });

  group('value types', () {
    test('ReceiptField equality and empty', () {
      expect(const ReceiptField(1, 80), const ReceiptField(1, 80));
      expect(const ReceiptField(1, 80), isNot(const ReceiptField(1, 81)));
      expect(const ReceiptField(1, 80), isNot(const ReceiptField(2, 80)));
      expect(
        const ReceiptField(1, 80).hashCode,
        const ReceiptField(1, 80).hashCode,
      );
      expect(const ReceiptField<int>.empty().isEmpty, isTrue);
      expect(const ReceiptField<int>.empty().confidence, 0);
      expect(const ReceiptField(1, 80).isEmpty, isFalse);
      expect(const ReceiptField(1, 80).toString(), contains('80'));
    });

    test('ReceiptDraft equality', () {
      const a = ReceiptDraft(totalCents: ReceiptField(1, 80));
      const b = ReceiptDraft(totalCents: ReceiptField(1, 80));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ReceiptDraft()));
      expect(
        a,
        isNot(
          const ReceiptDraft(
            totalCents: ReceiptField(1, 80),
            merchant: ReceiptField('x', 60),
          ),
        ),
      );
      expect(
        a,
        isNot(
          ReceiptDraft(
            totalCents: const ReceiptField(1, 80),
            date: ReceiptField(DateTime.utc(2024), 90),
          ),
        ),
      );
      expect(
        a,
        isNot(
          const ReceiptDraft(
            totalCents: ReceiptField(1, 80),
            currency: ReceiptField(Currency.eur, 90),
          ),
        ),
      );
      expect(
        a,
        isNot(
          const ReceiptDraft(
            totalCents: ReceiptField(1, 80),
            category: ReceiptField(ReceiptCategory.fuel, 90),
          ),
        ),
      );
      expect(a.toString(), contains('total'));
    });
  });

  group('properties', () {
    const words = [
      'SUMME',
      'Gesamt',
      'TOTAL',
      'zu zahlen',
      'Bar',
      'EC-Karte',
      'Rückgeld',
      'MwSt',
      'Brot',
      'REWE',
      'Shell',
      'EUR',
      '€',
      '12.03.2024',
      '2024-03-12',
      '03.11.23',
      '19,00 %',
      'l',
      '###',
      '',
    ];

    String render(int cents, int style) {
      final whole = cents ~/ 100;
      final frac = (cents % 100).toString().padLeft(2, '0');
      final w = whole.toString();
      return switch (style % 4) {
        0 => '$w,$frac',
        1 => '$w.$frac',
        2 => '${_group(w, '.')},$frac',
        _ => "${_group(w, "'")}.$frac",
      };
    }

    /// Random receipt-like noise and the set of cents values printed in it.
    (List<String>, Set<int>) noise(int seed) {
      final r = Random(seed);
      final lines = <String>[];
      final printed = <int>{};
      for (var i = 0; i < r.nextInt(25); i++) {
        final w = words[r.nextInt(words.length)];
        if (r.nextBool()) {
          final cents = 1 + r.nextInt(5000000);
          printed.add(cents);
          lines.add(
            r.nextBool()
                ? '$w ${render(cents, r.nextInt(4))}'
                : '${render(cents, r.nextInt(4))} $w',
          );
        } else {
          lines.add(w);
        }
      }
      return (lines, printed);
    }

    Glados(any.intNoShrink(0, 1 << 30)).test(
      'never throws, deterministic, total is positive and printed',
      (seed) {
        final (lines, printed) = noise(seed);
        final a = parse(lines);
        final b = parse(lines);
        expect(a, b);
        final t = a.totalCents.value;
        if (t != null) {
          expect(t, greaterThan(0));
          expect(printed, contains(t));
          expect(a.totalCents.confidence, inInclusiveRange(50, 100));
        }
        for (final f in [a.merchant, a.date, a.currency, a.category]) {
          expect(f.isEmpty || f.confidence >= 50, isTrue);
          expect(!f.isEmpty || f.confidence == 0, isTrue);
        }
      },
    );

    Glados(any.intNoShrink(0, 1 << 30)).test(
      'total is never larger than the largest printed amount',
      (seed) {
        final (lines, printed) = noise(seed);
        final t = parse(lines).totalCents.value;
        if (t != null) expect(t, lessThanOrEqualTo(printed.reduce(max)));
      },
    );

    Glados(any.intNoShrink(0, 1 << 30)).test(
      'random bytes never throw',
      (seed) {
        final r = Random(seed);
        final lines = [
          for (var i = 0; i < r.nextInt(20); i++)
            String.fromCharCodes([
              for (var j = 0; j < r.nextInt(60); j++) r.nextInt(0x2FF),
            ]),
        ];
        expect(() => parse(lines), returnsNormally);
      },
    );

    Glados2(any.intNoShrink(1, 99999999), any.intNoShrink(0, 4)).test(
      'any printed amount round-trips through every separator style',
      (cents, style) {
        expect(
          parse(['Brot', 'SUMME ${render(cents, style)} EUR']).totalCents.value,
          cents,
        );
        expect(
          parse(['zu zahlen', render(cents, style)]).totalCents.value,
          cents,
        );
      },
    );

    Glados(any.intNoShrink(1, 99999999)).test(
      'line items summing to the total give higher confidence',
      (cents) {
        final a = 1 + cents ~/ 2;
        final b = cents - a;
        if (b <= 0) return;
        final d = parse([
          'Brot ${render(a, 0)}',
          'Milch ${render(b, 0)}',
          'SUMME ${render(cents, 0)}',
        ]);
        expect(d.totalCents.value, cents);
        expect(d.totalCents.confidence, 90);
      },
    );

    Glados3(
      any.intNoShrink(2000, 2100),
      any.intNoShrink(1, 13),
      any.intNoShrink(1, 29),
    ).test('valid dates round-trip in all formats', (y, m, d) {
      final expected = DateTime.utc(y, m, d);
      String p2(int n) => n.toString().padLeft(2, '0');
      for (final s in [
        '${p2(d)}.${p2(m)}.$y',
        '$d.$m.$y',
        if (y < 2100) '${p2(d)}.${p2(m)}.${p2(y % 100)}',
        '$y-${p2(m)}-${p2(d)}',
      ]) {
        if (y == 2100) {
          expect(parse([s]).date.isEmpty, isTrue);
        } else {
          expect(parse([s]).date.value, expected, reason: s);
        }
      }
    });
  });
}

String _group(String digits, String sep) {
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(sep);
    out.write(digits[i]);
  }
  return out.toString();
}
