import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/decimal_parser.dart';

void main() {
  group('parseDecimal', () {
    test('reads comma and dot decimals', () {
      expect(parseDecimal('250'), 250);
      expect(parseDecimal('6,5'), 6.5);
      expect(parseDecimal('1.799'), 1.799);
      expect(parseDecimal(',5'), 0.5);
      expect(parseDecimal('.5'), 0.5);
      expect(parseDecimal('12,'), 12);
      expect(parseDecimal('0'), 0);
    });

    test('ignores spaces, also no-break', () {
      expect(parseDecimal(' 1 000 '), 1000);
      expect(parseDecimal('6 5'), 65);
    });

    test('rejects blank, grouping, signs and letters', () {
      for (final bad in ['', '  ', ',', '.', '1.234,5', '1,2,3', '1..2']) {
        expect(parseDecimal(bad), isNull, reason: bad);
      }
      for (final bad in ['-1', '+1', '1e3', 'abc', '1 a', '0x10', '１２']) {
        expect(parseDecimal(bad), isNull, reason: bad);
      }
    });

    test('caps the number of digits', () {
      expect(parseDecimal('123456789'), 123456789);
      expect(parseDecimal('1234567890'), isNull);
      expect(parseDecimal('12345,6789'), 12345.6789);
      expect(parseDecimal('12345,67890'), isNull);
    });
  });
}
