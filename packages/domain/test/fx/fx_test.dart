import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

Currency _c(String code) => Currency.tryParse(code)!;

void main() {
  group('FxRate', () {
    test('stores ppm', () => expect(FxRate(920000).ppm, 920000));

    test('accepts the smallest positive rate', () {
      expect(FxRate(1).ppm, 1);
    });

    test('rejects zero and negative ppm', () {
      for (final bad in [0, -1, -1000000]) {
        expect(
          () => FxRate(bad),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, 'name', 'ppm')
                .having((e) => e.invalidValue, 'invalidValue', bad)
                .having((e) => e.message, 'message', 'must be > 0'),
          ),
        );
      }
    });

    test('value equality and hashCode', () {
      expect(FxRate(5), FxRate(5));
      expect(FxRate(5).hashCode, FxRate(5).hashCode);
      expect(FxRate(5) == FxRate(6), isFalse);
      // ignore: unrelated_type_equality_checks, intentional comparison with a non-FxRate
      expect(FxRate(5) == 5, isFalse);
    });

    test('toString', () => expect(FxRate(5).toString(), 'FxRate(5)'));
  });

  group('convert examples (docs/domain-rules.md examples:fx)', () {
    for (final e in domainRulesRows('fx')) {
      final (cents, from, to, ppm, result) = (
        e['cents'] as int,
        e['from'] as String,
        e['to'] as String,
        e['ppm'] as int,
        e['result'] as int,
      );
      test('$cents $from -> $to @ $ppm = $result', () {
        expect(
          convert(Money(cents, _c(from)), _c(to), FxRate(ppm)),
          Money(result, _c(to)),
        );
      });
    }
  });

  group('convert edge cases', () {
    Money usd(int c) => Money(c, Currency.usd);

    test('zero stays zero', () {
      expect(
        convert(usd(0), Currency.eur, FxRate(920000)),
        Money(0, Currency.eur),
      );
    });

    test('negative amounts round half-even symmetrically', () {
      final r = FxRate(1100000);
      expect(convert(usd(-15), Currency.eur, r).cents, -16);
      expect(convert(usd(-25), Currency.eur, r).cents, -28);
      expect(convert(usd(-5), Currency.eur, r).cents, -6);
      expect(convert(usd(-10000), Currency.eur, r).cents, -11000);
    });

    test('exact halves round to even, others to nearest', () {
      final half = FxRate(500000);
      expect(convert(usd(1), Currency.eur, half).cents, 0);
      expect(convert(usd(3), Currency.eur, half).cents, 2);
      expect(convert(usd(5), Currency.eur, half).cents, 2);
      expect(convert(usd(1), Currency.eur, FxRate(510000)).cents, 1);
      expect(convert(usd(1), Currency.eur, FxRate(490000)).cents, 0);
      expect(convert(usd(-1), Currency.eur, half).cents, 0);
      expect(convert(usd(-3), Currency.eur, half).cents, -2);
    });

    test('JPY to EUR (0 -> 2 decimals)', () {
      expect(
        convert(Money(100, Currency.jpy), Currency.eur, FxRate(6200)).cents,
        62,
      );
    });

    test('KWD has 3 decimals', () {
      expect(
        convert(Money(1000, Currency.kwd), Currency.eur, FxRate(3250000)),
        Money(325, Currency.eur),
      );
      expect(
        convert(Money(1000, Currency.eur), Currency.kwd, FxRate(307700)),
        Money(3077, Currency.kwd),
      );
    });

    test('overflow throws MoneyOverflow', () {
      expect(
        () => convert(
          Money(Money.maxAbsCents, Currency.jpy),
          Currency.eur,
          FxRate(1000000),
        ),
        throwsA(isA<MoneyOverflow>()),
      );
      expect(
        () => convert(
          Money(-Money.maxAbsCents, Currency.jpy),
          Currency.eur,
          FxRate(1000000),
        ),
        throwsA(isA<MoneyOverflow>()),
      );
    });

    test('overflow reports the first value past the limit, signed', () {
      // 5e14 cents at 2.0 = 1e15 = maxAbsCents + 1 exactly.
      Matcher overflow(int cents) => throwsA(
        isA<MoneyOverflow>().having((e) => e.cents, 'cents', cents),
      );
      expect(
        () => convert(
          Money(500000000000000, Currency.eur),
          Currency.usd,
          FxRate(2000000),
        ),
        overflow(Money.maxAbsCents + 1),
      );
      expect(
        () => convert(
          Money(-500000000000000, Currency.eur),
          Currency.usd,
          FxRate(2000000),
        ),
        overflow(-Money.maxAbsCents - 1),
      );
    });

    test('result exactly at the limit is allowed, one above overflows', () {
      expect(
        convert(
          Money(Money.maxAbsCents, Currency.eur),
          Currency.usd,
          FxRate(1000000),
        ).cents,
        Money.maxAbsCents,
      );
      expect(
        () => convert(
          Money(Money.maxAbsCents, Currency.eur),
          Currency.usd,
          FxRate(1000001),
        ),
        throwsA(isA<MoneyOverflow>()),
      );
    });
  });

  group('convert properties', () {
    // No shrinking: glados shrinks ints by 1, which stalls failing runs.
    Generator<int> range(int lo, int hi) => any.simple(
      generate: (random, size) => random.nextIntInRange(lo, hi + 1),
      shrink: (_) => const [],
    );
    final amounts = range(-1000000000, 1000000000);
    final ppms = range(1, 1000000000);
    final currencies = any.choose(Currency.all);

    Glados(amounts).test('identity rate, same minor units: same cents', (c) {
      expect(
        convert(Money(c, Currency.eur), Currency.usd, FxRate(1000000)).cents,
        c,
      );
    });

    Glados3(amounts, amounts, ppms).test('monotonic in amount', (a, b, ppm) {
      final lo = a < b ? a : b;
      final hi = a < b ? b : a;
      final r = FxRate(ppm);
      expect(
        convert(Money(lo, Currency.usd), Currency.jpy, r).cents <=
            convert(Money(hi, Currency.usd), Currency.jpy, r).cents,
        isTrue,
      );
    });

    Glados3(amounts, ppms, currencies).test('within half a unit of exact', (
      cents,
      ppm,
      to,
    ) {
      const from = Currency.eur;
      final result = convert(Money(cents, from), to, FxRate(ppm)).cents;
      final num =
          BigInt.from(cents) *
          BigInt.from(ppm) *
          BigInt.from(10).pow(to.minorUnits);
      final den = BigInt.from(10).pow(6 + from.minorUnits);
      final diff = (BigInt.from(result) * den - num).abs();
      expect(diff * BigInt.two <= den, isTrue);
    });
  });
}
