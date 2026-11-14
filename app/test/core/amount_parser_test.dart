import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/amount_parser.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

void main() {
  int? eur(String s) => parseAmountCents(s, Currency.eur);

  group('valid', () {
    test('comma and dot decimals', () {
      expect(eur('12,34'), 1234);
      expect(eur('12.34'), 1234);
    });
    test('short and partial fractions', () {
      expect(eur('12'), 1200);
      expect(eur('12,3'), 1230);
      expect(eur('12,'), 1200);
      expect(eur(',5'), 50);
      expect(eur('0,05'), 5);
      expect(eur('0'), 0);
    });
    test('grouping with the other separator', () {
      expect(eur('1.234,56'), 123456);
      expect(eur('1,234.56'), 123456);
      expect(eur('12.345.678,90'), 1234567890);
    });
    test('ignores spaces and no-break spaces', () {
      expect(eur(' 1 234,5 '), 123450);
      expect(eur('12,34 '), 1234);
    });
    test('no float rounding: classic 0.1 + 0.2 and big values', () {
      expect(eur('0,29'), 29);
      expect(eur('1.15'), 115);
      expect(eur('9999999999999,99'), 999999999999999);
    });
    test('zero- and three-decimal currencies', () {
      expect(parseAmountCents('1500', Currency.jpy), 1500);
      expect(parseAmountCents('1,234', Currency.kwd), 1234);
      expect(parseAmountCents('1,2', Currency.kwd), 1200);
    });
  });

  group('invalid', () {
    test('blank', () {
      expect(eur(''), isNull);
      expect(eur('  '), isNull);
      expect(eur(','), isNull);
      expect(eur('.'), isNull);
    });
    test('letters, signs, symbols', () {
      expect(eur('abc'), isNull);
      expect(eur('-5'), isNull);
      expect(eur('+5'), isNull);
      expect(eur('5€'), isNull);
      expect(eur('1e5'), isNull);
    });
    test('too many fraction digits is rejected, not guessed', () {
      expect(eur('1,234'), isNull);
      expect(eur('1.234'), isNull);
      expect(parseAmountCents('1,5', Currency.jpy), isNull);
    });
    test('malformed grouping', () {
      expect(eur('1,234,56'), isNull);
      expect(eur('1.23,45'), isNull);
      expect(eur('12.3456,7'), isNull);
      expect(eur('1.234.567'), isNull);
    });
    test('overflow', () {
      expect(eur('10000000000000,00'), isNull);
      expect(eur('99999999999999999999'), isNull);
      expect(eur('9999999999999,99'), isNotNull);
    });
  });
}
