import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/no_shrink.dart';

int _units(num v, int scale) => scaleDecimal(v, scale).units!;

void main() {
  group('scale constants', () {
    test('match docs/domain-rules.md', () {
      expect(kmToMeters, 1000);
      expect(unitToMilli, 1000);
      expect(eurToCents, 100);
      expect(maxScaledUnits, 1e12);
    });
  });

  group('scaleDecimal', () {
    test('converts the documented examples', () {
      expect(_units(250, kmToMeters), 250000);
      expect(_units(6.5, unitToMilli), 6500);
      expect(_units(1.799, unitToMilli), 1799);
      expect(_units(0.05, unitToMilli), 50);
      expect(_units(11.5, eurToCents), 1150);
    });

    test('zero is valid', () {
      final r = scaleDecimal(0, 1000);
      expect(r.units, 0);
      expect(r.failure, isNull);
    });

    test('rounds half up', () {
      expect(_units(0.0005, 1000), 1);
      expect(_units(0.0004, 1000), 0);
      expect(_units(2.5, 1), 3);
    });

    test('strips binary float noise before rounding', () {
      // 1.005 * 100 == 100.49999999999999 in binary floating point.
      expect(_units(1.005, 100), 101);
      expect(_units(0.285, 100), 29);
    });

    test('accepts the upper bound, rejects above it', () {
      expect(_units(1e12, 1), 1000000000000);
      expect(
        scaleDecimal(1e12 + 1e6, 1).failure,
        ScaleFailure.invalid,
      );
      expect(scaleDecimal(1e10, 1000).failure, ScaleFailure.invalid);
    });

    test('negative values are reported as negative', () {
      final r = scaleDecimal(-0.001, 1000);
      expect(r.failure, ScaleFailure.negative);
      expect(r.units, isNull);
    });

    test('NaN and infinities are invalid', () {
      expect(scaleDecimal(double.nan, 1).failure, ScaleFailure.invalid);
      expect(scaleDecimal(double.infinity, 1).failure, ScaleFailure.invalid);
      expect(
        scaleDecimal(double.negativeInfinity, 1).failure,
        ScaleFailure.invalid,
      );
    });

    test('Scaled carries exactly one of units and failure', () {
      const ok = Scaled.ok(3);
      expect((ok.units, ok.failure), (3, null));
      const bad = Scaled.failed(ScaleFailure.invalid);
      expect((bad.units, bad.failure), (null, ScaleFailure.invalid));
    });

    Glados(any.intNoShrink(0, 100000000)).test(
      'whole thousandths survive the round trip',
      (milli) {
        expect(_units(milli / 1000, 1000), milli);
      },
    );

    Glados(any.intNoShrink(0, 1000000000)).test(
      'whole numbers scale exactly',
      (n) {
        expect(_units(n, 1000), n * 1000);
      },
    );

    Glados(any.intNoShrink(1, 100000)).test('negatives never convert', (n) {
      expect(scaleDecimal(-n / 100, 100).failure, ScaleFailure.negative);
    });
  });
}
