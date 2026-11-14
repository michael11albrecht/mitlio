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

  group('parseRatePpm', () {
    test('reads comma and dot decimals exactly', () {
      expect(parseRatePpm('0,92'), 920000);
      expect(parseRatePpm('0.92'), 920000);
      expect(parseRatePpm('.92'), 920000);
      expect(parseRatePpm(',5'), 500000);
      expect(parseRatePpm('1'), 1000000);
      expect(parseRatePpm('12,'), 12000000);
      expect(parseRatePpm('160'), 160000000);
      expect(parseRatePpm('0,0062'), 6200);
      expect(parseRatePpm('1,0834'), 1083400);
      expect(parseRatePpm('0,000001'), 1);
      expect(parseRatePpm('007,5'), 7500000);
    });

    test('rounds beyond six decimals half-even', () {
      expect(parseRatePpm('0,9200004'), 920000);
      expect(parseRatePpm('0,9200006'), 920001);
      expect(parseRatePpm('0,9200005'), 920000, reason: 'tie to even');
      expect(parseRatePpm('0,9200015'), 920002, reason: 'tie to even');
      expect(parseRatePpm('0,92000050001'), 920001, reason: 'above the tie');
      expect(parseRatePpm('0,920000500'), 920000, reason: 'zeros are a tie');
      expect(parseRatePpm('0,9999995'), 1000000, reason: 'carry into whole');
    });

    test('rejects blank, malformed, zero and oversized input', () {
      for (final bad in [
        '',
        '  ',
        ',',
        '.',
        'abc',
        '-1',
        '1,2,3',
        '1.234,5',
        '0',
        '0,0000004',
        '1234567890',
        '0,1234567890123',
        '1e3',
      ]) {
        expect(parseRatePpm(bad), isNull, reason: bad);
      }
    });
  });
}
