import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

void main() {
  final de = MoneyFormat('de');
  final en = MoneyFormat('en');

  group('de', () {
    test('formats euro with trailing symbol', () {
      expect(de.format(1234, Currency.eur), '12,34 €');
    });
    test('groups thousands', () {
      expect(de.format(123456789, Currency.eur), '1.234.567,89 €');
    });
    test('pads fraction and handles zero', () {
      expect(de.format(5, Currency.eur), '0,05 €');
      expect(de.format(0, Currency.eur), '0,00 €');
      expect(de.format(1200, Currency.eur), '12,00 €');
    });
    test('negative', () {
      expect(de.format(-2340, Currency.eur), '-23,40 €');
    });
    test('decimal separator', () => expect(de.decimalSeparator, ','));
  });

  group('en', () {
    test('formats euro with leading symbol', () {
      expect(en.format(1234, Currency.eur), '€12.34');
      expect(en.format(123456789, Currency.eur), '€1,234,567.89');
      expect(en.format(-2340, Currency.eur), '-€23.40');
    });
    test('other currencies', () {
      expect(en.format(1999, Currency.usd), r'$19.99');
    });
  });

  group('minor units', () {
    test('zero-digit currency has no fraction', () {
      expect(en.format(1500, Currency.jpy), '¥1,500');
    });
    test('three-digit currency', () {
      expect(en.format(1234, Currency.kwd), contains('1.234'));
    });
  });

  test('no double rounding at the int limit', () {
    expect(
      en.format(Money.maxAbsCents, Currency.eur),
      '€9,999,999,999,999.99',
    );
  });

  test('formatPlain has no grouping or symbol', () {
    expect(de.formatPlain(123456, Currency.eur), '1234,56');
    expect(en.formatPlain(-5, Currency.eur), '-0.05');
    expect(en.formatPlain(1500, Currency.jpy), '1500');
  });

  test('currencySymbol and split', () {
    expect(de.currencySymbol(Currency.eur), '€');
    final parts = MoneyFormat.split(-1205, Currency.eur);
    expect((parts.negative, parts.whole, parts.fraction), (true, 12, '05'));
  });

  test('formatRate drops trailing zeros and uses the locale separator', () {
    expect(de.formatRate(920000), '0,92');
    expect(en.formatRate(920000), '0.92');
    expect(de.formatRate(1083400), '1,0834');
    expect(de.formatRate(160000000), '160');
    expect(de.formatRate(1), '0,000001');
    expect(de.formatRate(1000000), '1');
  });

  test('formatMoney delegates', () {
    expect(de.formatMoney(Money(1240, Currency.eur)), '12,40 €');
  });

  test('unknown locale falls back to en, regional locale resolves', () {
    expect(MoneyFormat('xx').format(100, Currency.eur), '€1.00');
    expect(MoneyFormat('de_AT').locale, startsWith('de'));
  });
}
