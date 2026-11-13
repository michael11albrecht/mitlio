import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

extension MoneyAny on Any {
  /// Money in EUR within ±maxAbsCents/4 so sums of three never overflow.
  Generator<Money> get money => any
      .intInRange(-Money.maxAbsCents ~/ 4, Money.maxAbsCents ~/ 4 + 1)
      .map((c) => Money(c, Currency.eur));
}

void main() {
  group('Money examples', () {
    test('stores cents and currency', () {
      final m = Money(1234, Currency.eur);
      expect(m.cents, 1234);
      expect(m.currency, Currency.eur);
    });

    test('arithmetic', () {
      final a = Money(500, Currency.eur);
      final b = Money(120, Currency.eur);
      expect(a + b, Money(620, Currency.eur));
      expect(a - b, Money(380, Currency.eur));
      expect(b - a, Money(-380, Currency.eur));
      expect(-a, Money(-500, Currency.eur));
    });

    test('sign predicates', () {
      expect(Money(0, Currency.eur).isZero, isTrue);
      expect(Money(0, Currency.eur).isPositive, isFalse);
      expect(Money(0, Currency.eur).isNegative, isFalse);
      expect(Money(1, Currency.eur).isPositive, isTrue);
      expect(Money(1, Currency.eur).isZero, isFalse);
      expect(Money(1, Currency.eur).isNegative, isFalse);
      expect(Money(-1, Currency.eur).isNegative, isTrue);
      expect(Money(-1, Currency.eur).isPositive, isFalse);
      expect(Money(-1, Currency.eur).isZero, isFalse);
    });

    test('compareTo', () {
      final a = Money(1, Currency.eur);
      final b = Money(2, Currency.eur);
      expect(a.compareTo(b), isNegative);
      expect(b.compareTo(a), isPositive);
      expect(a.compareTo(Money(1, Currency.eur)), 0);
    });

    test('value equality and hashCode', () {
      expect(Money(5, Currency.eur), Money(5, Currency.eur));
      expect(Money(5, Currency.eur).hashCode, Money(5, Currency.eur).hashCode);
      expect(Money(5, Currency.eur) == Money(6, Currency.eur), isFalse);
      expect(Money(5, Currency.eur) == Money(5, Currency.usd), isFalse);
      // ignore: unrelated_type_equality_checks, intentional comparison with a non-Money
      expect(Money(5, Currency.eur) == 5, isFalse);
    });

    test('toString', () {
      expect(Money(5, Currency.jpy).toString(), 'Money(5 JPY)');
    });

    test('JPY (0) and KWD (3) minor units are plain cents', () {
      expect(
        Money(100, Currency.jpy) + Money(1, Currency.jpy),
        Money(101, Currency.jpy),
      );
      expect(
        Money(1500, Currency.kwd) - Money(500, Currency.kwd),
        Money(1000, Currency.kwd),
      );
    });
  });

  group('Money overflow', () {
    const max = Money.maxAbsCents;

    test('maxAbsCents value', () {
      expect(max, 999999999999999);
    });

    test('boundaries are accepted', () {
      expect(Money(max, Currency.eur).cents, max);
      expect(Money(-max, Currency.eur).cents, -max);
    });

    test('constructor beyond boundary throws', () {
      expect(() => Money(max + 1, Currency.eur), throwsA(isA<MoneyOverflow>()));
      expect(
        () => Money(-max - 1, Currency.eur),
        throwsA(isA<MoneyOverflow>()),
      );
    });

    test('addition overflow throws', () {
      expect(
        () => Money(max, Currency.eur) + Money(1, Currency.eur),
        throwsA(isA<MoneyOverflow>()),
      );
      expect(
        () => Money(-max, Currency.eur) + Money(-1, Currency.eur),
        throwsA(isA<MoneyOverflow>()),
      );
      expect(
        Money(max, Currency.eur) + Money(-1, Currency.eur),
        Money(max - 1, Currency.eur),
      );
    });

    test('subtraction overflow throws', () {
      expect(
        () => Money(max, Currency.eur) - Money(-1, Currency.eur),
        throwsA(isA<MoneyOverflow>()),
      );
      expect(
        () => Money(-max, Currency.eur) - Money(1, Currency.eur),
        throwsA(isA<MoneyOverflow>()),
      );
    });

    test('negation at boundary is fine', () {
      expect(-Money(max, Currency.eur), Money(-max, Currency.eur));
    });

    test('toString of MoneyOverflow', () {
      expect(const MoneyOverflow(7).toString(), 'MoneyOverflow(7)');
      expect(const MoneyOverflow(7).cents, 7);
    });
  });

  group('Money currency mismatch', () {
    final e = Money(1, Currency.eur);
    final u = Money(1, Currency.usd);

    test('+ - compareTo throw ArgumentError', () {
      expect(() => e + u, throwsA(isA<ArgumentError>()));
      expect(() => e - u, throwsA(isA<ArgumentError>()));
      expect(() => e.compareTo(u), throwsA(isA<ArgumentError>()));
    });
  });

  group('Money properties', () {
    Glados<Money>(any.money).test('-(-a) == a', (a) {
      final negated = -a;
      expect(-negated, equals(a));
    });

    Glados2<Money, Money>(any.money, any.money).test('a + b - b == a', (a, b) {
      expect(a + b - b, equals(a));
    });

    Glados2<Money, Money>(any.money, any.money).test('commutative', (a, b) {
      expect(a + b, equals(b + a));
    });

    Glados3<Money, Money, Money>(any.money, any.money, any.money).test(
      'associative',
      (a, b, c) {
        expect((a + b) + c, equals(a + (b + c)));
      },
    );

    Glados2<Money, Money>(any.money, any.money).test(
      'compareTo antisymmetric and consistent with ==',
      (a, b) {
        expect(a.compareTo(b), equals(-b.compareTo(a)));
        expect(a.compareTo(b) == 0, equals(a == b));
      },
    );

    Glados<Money>(any.money).test('sign predicates are exclusive', (a) {
      final flags = [a.isZero, a.isNegative, a.isPositive];
      expect(flags.where((f) => f).length, 1);
    });
  });
}
