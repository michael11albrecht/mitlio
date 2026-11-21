import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

const _members = [
  Member(id: 'A', position: 0),
  Member(id: 'B', position: 1),
  Member(id: 'C', position: 2),
];

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
  Set<String> passengers = const {'B', 'C'},
  bool driverCounts = false,
}) => TripInput(
  distanceMeters: distance,
  roundTrip: roundTrip,
  currency: currency,
  mode: mode,
  tollsCents: tolls,
  ferryCents: ferry,
  driverId: 'A',
  passengerIds: passengers,
  driverCounts: driverCounts,
);

TripCost _cost(TripInput i) =>
    (computeTripCost(i, _members) as Ok<TripCost, TripError>).value;

OperatingCostCheck _check(
  TripInput i, {
  int? runningWear,
  int? operating,
  int implausible = 1000,
}) => operatingCostCheck(
  i,
  _cost(i),
  runningWearMilliPerKm: runningWear,
  operatingMilliPerKm: operating,
  implausibleMilliPerKm: implausible,
);

extension _Gens on Any {
  Generator<int> get meters => simple(
    generate: (random, size) => random.nextIntInRange(1, 2000000),
    shrink: (_) => const [],
  );
  Generator<int> get consumption => simple(
    generate: (random, size) => random.nextIntInRange(1, 40000),
    shrink: (_) => const [],
  );
  Generator<int> get price => simple(
    generate: (random, size) => random.nextIntInRange(0, 3000),
    shrink: (_) => const [],
  );
  Generator<int> get wear => simple(
    generate: (random, size) => random.nextIntInRange(0, 500),
    shrink: (_) => const [],
  );
}

void main() {
  group('operatingCostCheck examples (examples:operating_cost)', () {
    for (final row in domainRulesRows('operating_cost')) {
      test(row['name'] as String, () {
        final i = row['input'] as Map<String, dynamic>;
        final input = TripInput(
          distanceMeters: i['distanceMeters'] as int,
          roundTrip: false,
          currency: Currency.eur,
          mode: i.containsKey('kmRate')
              ? KmRate(i['kmRate'] as int)
              : Consumption(
                  consumptionMilliPer100km: i['consumption'] as int,
                  pricePerUnitMilli: i['price'] as int,
                  wearMilliPerKm: (i['wear'] as int?) ?? 0,
                ),
          tollsCents: (i['tolls'] as int?) ?? 0,
          driverId: i['driver'] as String,
          passengerIds: (i['passengers'] as List).cast<String>().toSet(),
          driverCounts: i['driverCounts'] as bool,
        );
        final r = _check(
          input,
          runningWear: i['runningWear'] as int?,
          operating: i['operatingMilliPerKm'] as int?,
        );
        expect(r.passengersPayCents, row['pay']);
        expect(r.operatingCostCents, row['operating']);
        expect(r.exceedsOperatingCost, row['exceeds']);
        expect(r.plausibility.map((p) => p.name), row['plausibility']);
        expect(
          r.hasHint,
          row['exceeds'] == true || (row['plausibility'] as List).isNotEmpty,
        );
      });
    }
  });

  group('operatingCostCheck edge cases', () {
    const wearMode = Consumption(
      consumptionMilliPer100km: 6500,
      pricePerUnitMilli: 1799,
      wearMilliPerKm: 50,
    );
    test('equal is not exceeding', () {
      final r = _check(_input(mode: wearMode));
      expect(r.passengersPayCents, r.operatingCostCents);
      expect(r.exceedsOperatingCost, isFalse);
      expect(r.hasHint, isFalse);
    });
    test('one cent more exceeds', () {
      // Running wear 49 instead of 50: 250 km -> 1225 vs 1250 ct (25 ct less).
      final r = _check(_input(mode: wearMode), runningWear: 49);
      expect(r.operatingCostCents, r.passengersPayCents - 25);
      expect(r.exceedsOperatingCost, isTrue);
    });
    test('running wear above the trip wear is capped', () {
      final r = _check(_input(mode: wearMode), runningWear: 9999);
      expect(r.exceedsOperatingCost, isFalse);
      expect(r.operatingCostCents, 4173);
    });
    test('running wear 0 leaves only fuel', () {
      expect(
        _check(_input(mode: wearMode), runningWear: 0).operatingCostCents,
        2923,
      );
    });
    test('round trip doubles the distance for the operating cost', () {
      final r = _check(_input(mode: wearMode, roundTrip: true));
      expect(r.operatingCostCents, r.passengersPayCents);
      expect(r.operatingCostCents, 8347);
    });
    test('driver share is not passenger pay', () {
      final r = _check(_input(mode: wearMode, driverCounts: true));
      expect(r.passengersPayCents, 2782);
    });
    test('passenger not in the trip counts as 0', () {
      final r = _check(_input(passengers: {'B'}));
      expect(r.passengersPayCents, 2923);
    });
    test('ferry counts like tolls', () {
      expect(_check(_input(ferry: 1)).exceedsOperatingCost, isTrue);
    });
    test('cost per km: exactly the limit is fine, one more ct is not', () {
      TripInput km(int rate, int meters) =>
          _input(distance: meters, mode: KmRate(rate), passengers: {'B'});
      expect(_check(km(1000, 10000)).plausibility, isEmpty);
      expect(
        _check(km(1100, 10000)).plausibility,
        [PlausibilityIssue.costPerKmTooHigh],
      );
      expect(_check(km(1000, 10000), implausible: 900).plausibility, [
        PlausibilityIssue.costPerKmTooHigh,
      ]);
    });
    test('cost per km counts the round trip distance', () {
      // 1.2 EUR/km one way, 10 km round trip: total 24 EUR for 20 km = 1.2.
      final r = _check(
        _input(distance: 10000, roundTrip: true, mode: const KmRate(1200)),
      );
      expect(r.plausibility, [PlausibilityIssue.costPerKmTooHigh]);
    });
    test('consumption: 30 is fine, 30.001 is a typo', () {
      TripInput c(int milli) => _input(
        mode: Consumption(
          consumptionMilliPer100km: milli,
          pricePerUnitMilli: 1000,
        ),
      );
      expect(_check(c(30000)).plausibility, isEmpty);
      expect(
        _check(c(30001)).plausibility,
        [PlausibilityIssue.consumptionTooHigh],
      );
    });
    test('both plausibility issues, in enum order', () {
      final r = _check(
        _input(
          distance: 1000,
          mode: const Consumption(
            consumptionMilliPer100km: 40000,
            pricePerUnitMilli: 3000,
          ),
          passengers: {'B'},
        ),
      );
      // 1 km: 0.4 l x 3 = 1.20 -> total 1.20 per km.
      expect(r.plausibility, PlausibilityIssue.values);
    });
    test('km-rate mode: reference given gives a limit, none gives null', () {
      final i = _input(mode: const KmRate(300), passengers: {'B'});
      expect(_check(i).operatingCostCents, isNull);
      expect(_check(i).exceedsOperatingCost, isFalse);
      expect(_check(i, operating: 100).operatingCostCents, 2500);
      expect(_check(i, operating: 100).exceedsOperatingCost, isTrue);
      expect(_check(i, operating: 300).exceedsOperatingCost, isFalse);
    });
    test('non-euro currency scales with minor units', () {
      final i = _input(
        currency: Currency.jpy,
        distance: 100000,
        mode: const Consumption(
          consumptionMilliPer100km: 6000,
          pricePerUnitMilli: 170000,
          wearMilliPerKm: 10000,
        ),
        passengers: {'B'},
      );
      // 6 l x 170 = 1020 JPY fuel + 100 km x 10 = 1000 JPY wear.
      final r = _check(i);
      expect(r.passengersPayCents, 2020);
      expect(r.operatingCostCents, r.passengersPayCents);
    });
  });

  group('operatingCostCheck properties', () {
    Glados3(any.meters, any.consumption, any.price).test(
      'never fires with running-basis wear and no extras',
      (m, c, p) {
        for (final counts in [true, false]) {
          for (final round in [true, false]) {
            final i = _input(
              distance: m,
              roundTrip: round,
              driverCounts: counts,
              mode: Consumption(
                consumptionMilliPer100km: c,
                pricePerUnitMilli: p,
                wearMilliPerKm: 37,
              ),
            );
            expect(_check(i).exceedsOperatingCost, isFalse);
            expect(_check(i, runningWear: 37).exceedsOperatingCost, isFalse);
          }
        }
      },
    );
    Glados3(any.meters, any.consumption, any.wear).test(
      'less running wear never lowers the exceed flag',
      (m, c, w) {
        final i = _input(
          distance: m,
          mode: Consumption(
            consumptionMilliPer100km: c,
            pricePerUnitMilli: 1799,
            wearMilliPerKm: w,
          ),
        );
        final a = _check(i, runningWear: w ~/ 2);
        final b = _check(i, runningWear: w ~/ 4);
        expect(
          a.operatingCostCents,
          lessThanOrEqualTo(_check(i).operatingCostCents!),
        );
        expect(b.operatingCostCents, lessThanOrEqualTo(a.operatingCostCents!));
        if (a.exceedsOperatingCost) expect(b.exceedsOperatingCost, isTrue);
      },
    );
    Glados3(any.meters, any.consumption, any.price).test(
      'passengers pay at most the total',
      (m, c, p) {
        final i = _input(
          distance: m,
          tolls: 100,
          mode: Consumption(consumptionMilliPer100km: c, pricePerUnitMilli: p),
        );
        expect(
          _check(i).passengersPayCents,
          lessThanOrEqualTo(_cost(i).totalCents),
        );
      },
    );
  });

  group('operatingCostCheck hints never block', () {
    test('the check is a pure value, computeTripCost is unaffected', () {
      final i = _input(tolls: 5000);
      final before = _cost(i);
      _check(i);
      expect(_cost(i).totalCents, before.totalCents);
    });
  });
}
