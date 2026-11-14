import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

const _members = [
  Member(id: 'A', position: 0),
  Member(id: 'B', position: 1),
  Member(id: 'C', position: 2),
  Member(id: 'D', position: 3),
];
final _date = DateTime.utc(2026, 1, 2);

TripInput _input({
  int distance = 250000,
  bool roundTrip = false,
  Currency currency = Currency.eur,
  TripCostMode mode = const Consumption(
    consumptionMilliPer100km: 6500,
    pricePerUnitMilli: 1799,
  ),
  int tolls = 0,
  int ferry = 0,
  String driver = 'A',
  Set<String> passengers = const {'B', 'C'},
  bool driverCounts = true,
}) => TripInput(
  distanceMeters: distance,
  roundTrip: roundTrip,
  currency: currency,
  mode: mode,
  tollsCents: tolls,
  ferryCents: ferry,
  driverId: driver,
  passengerIds: passengers,
  driverCounts: driverCounts,
);

Result<TripCost, TripError> _compute(TripInput i) =>
    computeTripCost(i, _members);
TripCost _ok(TripInput i) => (_compute(i) as Ok<TripCost, TripError>).value;
TripError _err(TripInput i) => (_compute(i) as Err<TripCost, TripError>).error;

/// No shrinking, so mutation runs stay fast.
extension _Gens on Any {
  Generator<int> get meters => simple(
    generate: (random, size) => random.nextIntInRange(1, 2000000000),
    shrink: (_) => const [],
  );
  Generator<int> get consumption => simple(
    generate: (random, size) => random.nextIntInRange(0, 30000),
    shrink: (_) => const [],
  );
  Generator<int> get price => simple(
    generate: (random, size) => random.nextIntInRange(0, 5000),
    shrink: (_) => const [],
  );
}

void main() {
  group('computeTripCost examples (examples:trip)', () {
    // The doc's members are A, B, C; the tests' roster adds D (share 0).
    TripInput inputOf(Map<String, dynamic> i) => TripInput(
      distanceMeters: i['distanceMeters'] as int,
      roundTrip: i['roundTrip'] as bool,
      currency: Currency.eur,
      mode: i.containsKey('kmRate')
          ? KmRate(i['kmRate'] as int)
          : Consumption(
              consumptionMilliPer100km: i['consumption'] as int,
              pricePerUnitMilli: i['price'] as int,
              wearMilliPerKm: (i['wear'] as int?) ?? 0,
            ),
      tollsCents: (i['tollsCents'] as int?) ?? 0,
      driverId: i['driver'] as String,
      passengerIds: (i['passengers'] as List).cast<String>().toSet(),
      driverCounts: i['driverCounts'] as bool,
    );
    final rows = domainRulesRows('trip');
    for (final row in rows) {
      test(row['name'] as String, () {
        final c = _ok(inputOf(row['input'] as Map<String, dynamic>));
        expect(c.fuelCents, row['fuel'] ?? 0);
        expect(c.wearCents, row['wear'] ?? 0);
        expect(c.kmRateCents, row['kmRateCents'] ?? 0);
        expect(c.totalCents, row['total']);
        expect(c.shares, {
          for (final m in _members) m.id: 0,
          ...(row['shares'] as Map).cast<String, int>(),
        });
      });
    }

    test('29.23375 EUR rounds to 2923 cents', () {
      expect(_ok(_input()).fuelCents, 2923);
    });

    test('tolls and ferry are not doubled on a round trip', () {
      final c = _ok(
        _input(
          roundTrip: true,
          mode: const KmRate(0),
          tolls: 1000,
          ferry: 500,
        ),
      );
      expect(c.tollsCents, 1000);
      expect(c.ferryCents, 500);
      expect(c.totalCents, 1500);
    });
  });

  group('computeTripCost edge cases', () {
    TripInput km(int rate, int meters, {Currency currency = Currency.eur}) =>
        _input(distance: meters, mode: KmRate(rate), currency: currency);

    test('EUR half-up boundary at exactly .5', () {
      // d * 1 / 10000 cents
      expect(_ok(km(1, 4999)).kmRateCents, 0);
      expect(_ok(km(1, 5000)).kmRateCents, 1); // 0.5 -> 1
      expect(_ok(km(1, 15000)).kmRateCents, 2); // 1.5 -> 2
      expect(_ok(km(1, 25000)).kmRateCents, 3); // 2.5 -> 3 (not banker's)
    });

    test('JPY (minorUnits 0): 1 JPY per km', () {
      expect(_ok(km(1000, 1000, currency: Currency.jpy)).kmRateCents, 1);
      expect(_ok(km(1000, 499, currency: Currency.jpy)).kmRateCents, 0);
      expect(_ok(km(1000, 500, currency: Currency.jpy)).kmRateCents, 1);
      expect(_ok(km(1000, 250000, currency: Currency.jpy)).kmRateCents, 250);
    });

    test('JPY fuel', () {
      final c = _ok(
        _input(
          currency: Currency.jpy,
          // 250 km, 6.5 l/100km, 180.000 JPY/l -> 16.25 l * 180 = 2925
          mode: const Consumption(
            consumptionMilliPer100km: 6500,
            pricePerUnitMilli: 180000,
          ),
        ),
      );
      expect(c.fuelCents, 2925);
    });

    test('KWD (minorUnits 3)', () {
      expect(_ok(km(1, 500, currency: Currency.kwd)).kmRateCents, 1);
      expect(_ok(km(1, 499, currency: Currency.kwd)).kmRateCents, 0);
      final c = _ok(
        _input(currency: Currency.kwd),
      );
      // 29.23375 KWD = 29233.75 fils
      expect(c.fuelCents, 29234);
    });

    test('1 metre', () {
      expect(_ok(km(1000, 1)).kmRateCents, 0);
      expect(_ok(_input(distance: 1)).totalCents, 0);
    });

    test('very long distance stays exact', () {
      final c = _ok(
        _input(
          distance: 100000000, // 100000 km
          mode: const Consumption(
            consumptionMilliPer100km: 100000,
            pricePerUnitMilli: 1000000,
          ),
        ),
      );
      // 100000 km * 100 l/100km = 100000 l * 1000 EUR/l = 1e8 EUR
      expect(c.fuelCents, 10000000000);
      expect(c.shares.values.reduce((a, b) => a + b), 10000000000);
    });

    test('total beyond Money.maxAbsCents throws MoneyOverflow', () {
      expect(
        () => _compute(
          _input(
            distance: 100000000,
            mode: const Consumption(
              consumptionMilliPer100km: 1000000000,
              pricePerUnitMilli: 1000000000,
            ),
          ),
        ),
        throwsA(
          isA<MoneyOverflow>().having(
            (e) => e.cents,
            'cents',
            Money.maxAbsCents + 1,
          ),
        ),
      );
    });

    test('shares contain every member, even non-participants', () {
      expect(_ok(_input()).shares.keys, ['A', 'B', 'C', 'D']);
    });

    test('shares are ordered by tieOrder, not list order', () {
      final shuffled = [
        const Member(id: 'B', position: 0),
        const Member(id: 'A', position: 1),
      ];
      final r = computeTripCost(
        _input(
          distance: 1000,
          mode: const KmRate(1010), // 1 km * 1.010 = 101 ct
          passengers: {'B'},
        ),
        shuffled,
      );
      final c = (r as Ok<TripCost, TripError>).value;
      expect(c.totalCents, 101);
      expect(c.shares, {'B': 51, 'A': 50}); // B is first in tie order
    });

    test('custom ordering of ties uses position then id', () {
      final c = (computeTripCost(
        _input(mode: const KmRate(1)), // 250 km -> 25 ct
        [
          const Member(id: 'A', position: 2),
          const Member(id: 'B', position: 1),
          const Member(id: 'C', position: 0),
        ],
      ) as Ok<TripCost, TripError>).value;
      expect(c.totalCents, 25);
      expect(c.shares, {'C': 9, 'B': 8, 'A': 8});
    });
  });

  group('computeTripCost validation', () {
    test('non-positive distance', () {
      expect(_err(_input(distance: 0)), const NonPositiveDistance());
      expect(_err(_input(distance: -5)), const NonPositiveDistance());
    });

    test('negative values name the field', () {
      TripCostMode cons({int c = 1, int p = 1, int w = 0}) => Consumption(
        consumptionMilliPer100km: c,
        pricePerUnitMilli: p,
        wearMilliPerKm: w,
      );
      expect(
        _err(_input(mode: cons(c: -1))),
        const TripNegativeValue('consumptionMilliPer100km'),
      );
      expect(
        _err(_input(mode: cons(p: -1))),
        const TripNegativeValue('pricePerUnitMilli'),
      );
      expect(
        _err(_input(mode: cons(w: -1))),
        const TripNegativeValue('wearMilliPerKm'),
      );
      expect(
        _err(_input(mode: const KmRate(-1))),
        const TripNegativeValue('kmRateMilliPerKm'),
      );
      expect(
        _err(_input(tolls: -1)),
        const TripNegativeValue('tollsCents'),
      );
      expect(
        _err(_input(ferry: -1)),
        const TripNegativeValue('ferryCents'),
      );
    });

    test('negative value order: consumption before tolls', () {
      expect(
        _err(
          _input(
            mode: const Consumption(
              consumptionMilliPer100km: -1,
              pricePerUnitMilli: -1,
            ),
            tolls: -1,
          ),
        ),
        const TripNegativeValue('consumptionMilliPer100km'),
      );
      expect(
        _err(_input(tolls: -1, ferry: -1)),
        const TripNegativeValue('tollsCents'),
      );
    });

    test('unknown ids: smallest wins, driver included', () {
      expect(_err(_input(driver: 'X')), const TripUnknownMember('X'));
      expect(
        _err(_input(passengers: {'Z', 'Y', 'B'})),
        const TripUnknownMember('Y'),
      );
      expect(
        _err(_input(driver: 'Z', passengers: {'Y'})),
        const TripUnknownMember('Y'),
      );
    });

    test('driver is passenger', () {
      expect(
        _err(_input(passengers: {'A', 'B'})),
        const DriverIsPassenger(),
      );
    });

    test('no participants', () {
      expect(
        _err(_input(passengers: {}, driverCounts: false)),
        const TripNoParticipants(),
      );
    });

    test('driver alone and counting is valid', () {
      final c = _ok(_input(passengers: {}));
      expect(c.shares['A'], c.totalCents);
    });

    test('check order: distance before negative values', () {
      expect(
        _err(_input(distance: 0, tolls: -1, driver: 'X')),
        const NonPositiveDistance(),
      );
    });

    test('check order: negative values before unknown ids', () {
      expect(
        _err(_input(tolls: -1, driver: 'X')),
        const TripNegativeValue('tollsCents'),
      );
    });

    test('check order: unknown ids before driver-is-passenger', () {
      expect(
        _err(_input(driver: 'X', passengers: {'X'})),
        const TripUnknownMember('X'),
      );
    });

    test('check order: driver-is-passenger before no participants', () {
      // Passenger set contains the driver, so it is not empty; with
      // driverCounts false it would otherwise be a valid split.
      expect(
        _err(_input(passengers: {'A'}, driverCounts: false)),
        const DriverIsPassenger(),
      );
    });

    test('UnsupportedCurrency is unreachable via the public API', () {
      // Currency has a private constructor, so minorUnits > 3 cannot be built.
      expect(Currency.all.every((c) => c.minorUnits <= 3), isTrue);
      expect(const UnsupportedCurrency(), const UnsupportedCurrency());
    });
  });

  group('TripError value semantics', () {
    test('equality, hashCode, toString', () {
      expect(
        const NonPositiveDistance().hashCode,
        const NonPositiveDistance().hashCode,
      );
      expect(const NonPositiveDistance().toString(), 'NonPositiveDistance()');
      expect(
        const TripNegativeValue('a') == const TripNegativeValue('b'),
        isFalse,
      );
      expect(
        const TripNegativeValue('a').hashCode,
        const TripNegativeValue('a').hashCode,
      );
      expect(const TripNegativeValue('a').toString(), 'TripNegativeValue(a)');
      expect(
        const TripNoParticipants().hashCode,
        const TripNoParticipants().hashCode,
      );
      expect(const TripNoParticipants().toString(), 'TripNoParticipants()');
      expect(
        const DriverIsPassenger().hashCode,
        const DriverIsPassenger().hashCode,
      );
      expect(const DriverIsPassenger().toString(), 'DriverIsPassenger()');
      expect(
        const TripUnknownMember('a') == const TripUnknownMember('b'),
        isFalse,
      );
      expect(
        const TripUnknownMember('a').hashCode,
        const TripUnknownMember('a').hashCode,
      );
      expect(const TripUnknownMember('a').toString(), 'TripUnknownMember(a)');
      expect(
        const UnsupportedCurrency().hashCode,
        const UnsupportedCurrency().hashCode,
      );
      expect(const UnsupportedCurrency().toString(), 'UnsupportedCurrency()');
      expect(
        const NonPositiveDistance() == const TripNoParticipants(),
        isFalse,
      );
    });
  });

  group('computeTripCost properties', () {
    TripInput gen(int meters, int cons, int price, int flags, {int wear = 0}) {
      return _input(
        distance: meters,
        roundTrip: flags & 1 != 0,
        driverCounts: flags & 2 != 0,
        mode: Consumption(
          consumptionMilliPer100km: cons,
          pricePerUnitMilli: price,
          wearMilliPerKm: wear,
        ),
        passengers: flags & 4 != 0 ? {'B', 'C', 'D'} : {'B'},
        tolls: 7,
        ferry: 3,
      );
    }

    Glados3(any.meters, any.consumption, any.price).test(
      'sum of shares equals total',
      (m, c, p) {
        for (var f = 0; f < 8; f++) {
          final cost = _ok(gen(m, c, p, f));
          expect(
            cost.shares.values.fold<int>(0, (a, b) => a + b),
            cost.totalCents,
          );
        }
      },
    );

    Glados3(any.meters, any.consumption, any.price).test(
      'total equals sum of components',
      (m, c, p) {
        final cost = _ok(gen(m, c, p, 1, wear: 50));
        expect(
          cost.totalCents,
          cost.fuelCents +
              cost.wearCents +
              cost.kmRateCents +
              cost.tollsCents +
              cost.ferryCents,
        );
        final km = _ok(_input(distance: m, mode: KmRate(p), tolls: 7));
        expect(
          km.totalCents,
          km.fuelCents + km.kmRateCents + km.wearCents + 7 + km.ferryCents,
        );
        expect(km.fuelCents, 0);
      },
    );

    Glados3(any.meters, any.consumption, any.price).test(
      'driver gets 0 when driverCounts is false',
      (m, c, p) {
        final cost = _ok(gen(m, c, p, 0));
        expect(cost.shares['A'], 0);
        expect(cost.shares['D'], 0);
      },
    );

    Glados3(any.meters, any.consumption, any.price).test(
      'round trip equals one way of doubled distance',
      (m, c, p) {
        final a = _ok(gen(m, c, p, 1 | 2, wear: 30));
        final b = _ok(gen(2 * m, c, p, 2, wear: 30));
        expect(a.totalCents, b.totalCents);
        expect(a.fuelCents, b.fuelCents);
        expect(a.wearCents, b.wearCents);
        expect(a.shares, b.shares);
      },
    );

    Glados3(any.meters, any.consumption, any.price).test(
      'monotonic in distance and price',
      (m, c, p) {
        final base = _ok(gen(m, c, p, 0)).totalCents;
        expect(
          _ok(gen(m + 1000, c, p, 0)).totalCents,
          greaterThanOrEqualTo(base),
        );
        expect(_ok(gen(m, c, p + 7, 0)).totalCents, greaterThanOrEqualTo(base));
        expect(_ok(gen(m, c + 7, p, 0)).totalCents, greaterThanOrEqualTo(base));
      },
    );

    Glados2(any.meters, any.price).test(
      'km rate: each component rounds within half a cent of exact',
      (m, rate) {
        final cost = _ok(_input(distance: m, mode: KmRate(rate)));
        final exact = BigInt.from(m) * BigInt.from(rate);
        // |kmRate - exact/10000| <= 1/2  <=>  |10000*kmRate - exact| <= 5000
        final diff =
            (BigInt.from(cost.kmRateCents) * BigInt.from(10000) - exact).abs();
        expect(diff <= BigInt.from(5000), isTrue);
      },
    );
  });

  group('tripToExpense', () {
    Expense okExpense(TripInput i) {
      final cost = _ok(i);
      final r = tripToExpense(
        id: 'e1',
        title: 'Trip',
        date: _date,
        input: i,
        cost: cost,
        members: _members,
      );
      return (r as Ok<Expense, ExpenseError>).value;
    }

    test('payer is the driver, split is the computed shares', () {
      final i = _input(tolls: 1150);
      final e = okExpense(i);
      final cost = _ok(i);
      expect(e.payers, {'A': cost.totalCents});
      expect(e.shares, cost.shares);
      expect(e.amountCents, cost.totalCents);
      expect(e.currency, Currency.eur);
      expect(e.title, 'Trip');
      expect(e.date, _date);
      expect(e.id, 'e1');
    });

    test('propagates ExpenseError (empty title)', () {
      final i = _input();
      final r = tripToExpense(
        id: 'e1',
        title: '  ',
        date: _date,
        input: i,
        cost: _ok(i),
        members: _members,
      );
      expect((r as Err<Expense, ExpenseError>).error, const EmptyTitle());
    });

    test('zero total is rejected as AmountNotPositive', () {
      final i = _input(distance: 1);
      final r = tripToExpense(
        id: 'e1',
        title: 'Trip',
        date: _date,
        input: i,
        cost: _ok(i),
        members: _members,
      );
      expect(
        (r as Err<Expense, ExpenseError>).error,
        const InvalidSplit(AmountNotPositive()),
      );
    });

    Glados2(any.meters, any.price).test(
      'payers == {driver: total} and shares == cost.shares',
      (m, p) {
        final i = _input(
          distance: m,
          mode: Consumption(
            consumptionMilliPer100km: 6500,
            pricePerUnitMilli: p + 1,
          ),
          driverCounts: m.isEven,
        );
        final cost = _ok(i);
        final r = tripToExpense(
          id: 'e',
          title: 't',
          date: _date,
          input: i,
          cost: cost,
          members: _members,
        );
        if (cost.totalCents == 0) return;
        final e = (r as Ok<Expense, ExpenseError>).value;
        expect(e.payers, {'A': cost.totalCents});
        expect(e.shares, cost.shares);
      },
    );
  });
}
