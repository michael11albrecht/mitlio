import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

void main() {
  group('Currency', () {
    test('minor units', () {
      expect(Currency.eur.minorUnits, 2);
      expect(Currency.jpy.minorUnits, 0);
      expect(Currency.isk.minorUnits, 0);
      expect(Currency.kwd.minorUnits, 3);
    });

    test('codes of the required constants', () {
      expect(Currency.all.map((c) => c.code).toSet(), {
        'EUR', 'USD', 'GBP', 'CHF', 'JPY', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK', //
        'HUF', 'RON', 'BGN', 'TRY', 'ISK', 'KWD', 'CAD', 'AUD', 'NZD',
      });
      expect(Currency.all.length, 19);
      expect(Currency.try_.code, 'TRY');
    });

    test('tryParse known', () {
      expect(Currency.tryParse('EUR'), Currency.eur);
      expect(Currency.tryParse('JPY'), Currency.jpy);
      expect(Currency.tryParse('KWD')?.minorUnits, 3);
    });

    test('tryParse unknown, lowercase, empty, padded', () {
      expect(Currency.tryParse('XXX'), isNull);
      expect(Currency.tryParse('eur'), isNull);
      expect(Currency.tryParse(''), isNull);
      expect(Currency.tryParse(' EUR'), isNull);
    });

    test('equality, hashCode, toString', () {
      expect(Currency.eur, Currency.tryParse('EUR'));
      expect(Currency.eur.hashCode, Currency.tryParse('EUR').hashCode);
      expect(Currency.eur == Currency.usd, isFalse);
      // ignore: unrelated_type_equality_checks, intentional comparison with a non-Currency
      expect(Currency.eur == 'EUR', isFalse);
      expect(Currency.eur.toString(), 'EUR');
    });

    Glados(any.choose(Currency.all)).test('tryParse(code) round-trips', (c) {
      expect(Currency.tryParse(c.code), equals(c));
    });
  });
}
