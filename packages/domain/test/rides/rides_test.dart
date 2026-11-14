import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';
import '../support/no_shrink.dart';

const _members = [
  Member(id: 'A', position: 0),
  Member(id: 'B', position: 1),
  Member(id: 'C', position: 2),
  Member(id: 'D', position: 3),
];

final _golf = Vehicle(
  id: 'golf',
  name: 'Golf',
  fuelType: FuelType.petrol,
  consumptionMilliPer100km: 6500,
);

final Map<String, Vehicle> _vehicles = {'golf': _golf};

Ride _ride({
  String id = 'r',
  DateTime? date,
  int distance = 20000,
  bool roundTrip = true,
  int tolls = 0,
  String vehicleId = 'golf',
  String driver = 'A',
  Set<String> passengers = const {'B'},
  bool driverCounts = true,
  int price = 1799,
  bool useKmRate = false,
}) => Ride(
  id: id,
  date: date ?? DateTime(2026, 10, 5),
  distanceMeters: distance,
  roundTrip: roundTrip,
  tollsCents: tolls,
  vehicleId: vehicleId,
  driverId: driver,
  passengerIds: passengers,
  driverCounts: driverCounts,
  pricePerUnitMilli: price,
  useKmRate: useKmRate,
);

TripCost _cost(Ride r, [Vehicle? v]) => (rideCost(
  r,
  v ?? _golf,
  Currency.eur,
  _members,
) as Ok<TripCost, TripError>).value;

TripError _costErr(Ride r, [Vehicle? v]) => (rideCost(
  r,
  v ?? _golf,
  Currency.eur,
  _members,
) as Err<TripCost, TripError>).error;

Result<List<RideAggregate>, TripError> _agg(
  Iterable<Ride> rides,
  RidePeriod period, {
  Map<String, Vehicle>? vehicles,
}) => aggregateRides(
  rides: rides,
  vehicles: vehicles ?? _vehicles,
  currency: Currency.eur,
  members: _members,
  period: period,
);

List<RideAggregate> _aggOk(Iterable<Ride> rides, RidePeriod period) =>
    (_agg(rides, period) as Ok<List<RideAggregate>, TripError>).value;

DateTime _d(String iso) => DateTime.parse(iso);

RidePeriod _periodOf(Map<String, dynamic> p) {
  if (p['month'] != null) {
    final m = (p['month'] as List).cast<int>();
    return Month(m[0], m[1]);
  }
  if (p['week'] != null) {
    final w = (p['week'] as List).cast<int>();
    return Week(w[0], w[1]);
  }
  if (p['day'] != null) return Day(_d(p['day'] as String));
  final c = (p['custom'] as List).cast<String>();
  return Custom(_d(c[0]), _d(c[1]));
}

/// Random rides around October 2026 (some outside it), from [seed].
List<Ride> _randomRides(int seed) {
  final rnd = Random(seed);
  final ids = ['A', 'B', 'C', 'D'];
  return [
    for (var i = 0; i < 1 + rnd.nextInt(14); i++)
      () {
        final driver = ids[rnd.nextInt(4)];
        final passengers = {
          for (final id in ids)
            if (id != driver && rnd.nextBool()) id,
        };
        final km = rnd.nextBool();
        return _ride(
          id: 'r${rnd.nextInt(1 << 20)}-$i',
          date: DateTime(
            2026,
            9 + rnd.nextInt(3),
            1 + rnd.nextInt(30),
            rnd.nextInt(24),
          ),
          distance: 1 + rnd.nextInt(300000),
          roundTrip: rnd.nextBool(),
          tolls: rnd.nextInt(2000),
          driver: driver,
          passengers: passengers,
          driverCounts: passengers.isEmpty || rnd.nextBool(),
          price: rnd.nextInt(3000),
          useKmRate: km,
        );
      }(),
  ];
}

final _carWithKmRate = Vehicle(
  id: 'golf',
  name: 'Golf',
  fuelType: FuelType.petrol,
  consumptionMilliPer100km: 6500,
  kmRateMilliPerKm: 300,
);

void main() {
  group('examples:rides', () {
    final ex = domainRulesExamples('rides')! as Map<String, dynamic>;
    final v = ex['vehicle'] as Map<String, dynamic>;
    final vehicle = Vehicle(
      id: v['id'] as String,
      name: 'doc',
      fuelType: FuelType.petrol,
      consumptionMilliPer100km: v['consumption'] as int,
      wearMilliPerKm: v['wear'] as int,
    );
    final members = [
      for (final (i, id) in (ex['members'] as List).cast<String>().indexed)
        Member(id: id, position: i),
    ];
    final rides = [
      for (final r in (ex['rides'] as List).cast<Map<String, dynamic>>())
        Ride(
          id: r['id'] as String,
          date: _d(r['date'] as String),
          distanceMeters: r['distanceMeters'] as int,
          roundTrip: r['roundTrip'] as bool,
          vehicleId: vehicle.id,
          driverId: r['driver'] as String,
          passengerIds: (r['passengers'] as List).cast<String>().toSet(),
          driverCounts: r['driverCounts'] as bool,
          pricePerUnitMilli: r['price'] as int,
        ),
    ];

    test('ride costs', () {
      final costs = ex['rideCosts'] as Map<String, dynamic>;
      for (final r in rides) {
        final c = rideCost(r, vehicle, Currency.eur, members);
        expect((c as Ok<TripCost, TripError>).value.totalCents, costs[r.id]);
      }
    });

    test('aggregates', () {
      final got = aggregateRides(
        rides: rides,
        vehicles: {vehicle.id: vehicle},
        currency: Currency.eur,
        members: members,
        period: _periodOf(ex['period'] as Map<String, dynamic>),
      );
      final aggs = (got as Ok<List<RideAggregate>, TripError>).value;
      final want = (ex['aggregates'] as List).cast<Map<String, dynamic>>();
      expect(aggs, hasLength(want.length));
      for (final (i, w) in want.indexed) {
        expect(aggs[i].driverId, w['driver']);
        expect(aggs[i].rideIds, w['rideIds']);
        expect(aggs[i].totalCents, w['total']);
        expect(aggs[i].shares, w['shares']);
      }
    });
  });

  group('Vehicle', () {
    test('value equality', () {
      Vehicle mk({
        String id = 'v',
        String name = 'n',
        FuelType f = FuelType.diesel,
        int c = 5000,
        int w = 10,
        int? k = 200,
      }) => Vehicle(
        id: id,
        name: name,
        fuelType: f,
        consumptionMilliPer100km: c,
        wearMilliPerKm: w,
        kmRateMilliPerKm: k,
      );
      expect(mk(), mk());
      expect(mk().hashCode, mk().hashCode);
      expect(mk(id: 'x'), isNot(mk()));
      expect(mk(name: 'x'), isNot(mk()));
      expect(mk(f: FuelType.electric), isNot(mk()));
      expect(mk(c: 1), isNot(mk()));
      expect(mk(w: 1), isNot(mk()));
      expect(mk(k: 1), isNot(mk()));
      expect(mk(k: null), isNot(mk()));
      expect(mk(), isNot('v'));
      expect(mk().toString(), 'Vehicle(v, n)');
    });

    test('validation', () {
      Vehicle mk(int c, int w, int? k) => Vehicle(
        id: 'v',
        name: 'n',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: c,
        wearMilliPerKm: w,
        kmRateMilliPerKm: k,
      );
      expect(() => mk(0, 0, null), throwsArgumentError);
      expect(() => mk(-1, 0, null), throwsArgumentError);
      expect(() => mk(1, -1, null), throwsArgumentError);
      expect(() => mk(1, 0, -1), throwsArgumentError);
      expect(mk(1, 0, 0).kmRateMilliPerKm, 0);
    });

    test('validation errors name the offending field, value and reason', () {
      Vehicle mk(int c, int w, int? k) => Vehicle(
        id: 'v',
        name: 'n',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: c,
        wearMilliPerKm: w,
        kmRateMilliPerKm: k,
      );
      Matcher rejects(String name, Object? value, String message) => throwsA(
        isA<ArgumentError>()
            .having((e) => e.name, 'name', name)
            .having((e) => e.invalidValue, 'invalidValue', value)
            .having((e) => e.message, 'message', message),
      );
      expect(
        () => mk(0, 0, null),
        rejects('consumptionMilliPer100km', 0, 'must be > 0'),
      );
      expect(
        () => mk(1, -1, null),
        rejects('wearMilliPerKm', -1, 'must be >= 0'),
      );
      expect(
        () => mk(1, 0, -1),
        rejects('kmRateMilliPerKm', -1, 'must be >= 0'),
      );
    });
  });

  group('rideCost', () {
    test('matches the equivalent trip', () {
      final r = _ride(tolls: 100, passengers: {'B', 'C'});
      final trip = computeTripCost(
        const TripInput(
          distanceMeters: 20000,
          roundTrip: true,
          currency: Currency.eur,
          mode: Consumption(
            consumptionMilliPer100km: 6500,
            pricePerUnitMilli: 1799,
          ),
          tollsCents: 100,
          driverId: 'A',
          passengerIds: {'B', 'C'},
          driverCounts: true,
        ),
        _members,
      );
      final c = _cost(r);
      final t = (trip as Ok<TripCost, TripError>).value;
      expect(c.totalCents, t.totalCents);
      expect(c.shares, t.shares);
    });

    test('vehicle wear is included', () {
      final v = Vehicle(
        id: 'golf',
        name: 'Golf',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: 6500,
        wearMilliPerKm: 50,
      );
      // fuel 468 + wear 40 km * 0.05 = 200
      expect(_cost(_ride(), v).wearCents, 200);
      expect(_cost(_ride(), v).totalCents, 668);
    });

    test('electric vehicles use kWh the same way', () {
      final ev = Vehicle(
        id: 'golf',
        name: 'ID.3',
        fuelType: FuelType.electric,
        consumptionMilliPer100km: 16000,
      );
      // 40 km * 16 kWh/100 km = 6.4 kWh * 0.30 = 1.92
      expect(_cost(_ride(price: 300), ev).totalCents, 192);
    });

    test('km-rate mode replaces fuel and ignores the ride price', () {
      final c = _cost(_ride(useKmRate: true, price: 0), _carWithKmRate);
      // 40 km * 0.30 = 12.00
      expect(c.kmRateCents, 1200);
      expect(c.fuelCents, 0);
      expect(c.totalCents, 1200);
    });

    test('useKmRate without a vehicle km rate is MissingKmRate', () {
      expect(_costErr(_ride(useKmRate: true)), const MissingKmRate());
    });

    test('a km rate on the vehicle is not used unless requested', () {
      expect(_cost(_ride(), _carWithKmRate).totalCents, 468);
    });

    test('vehicleId mismatch throws ArgumentError', () {
      expect(() => _cost(_ride(vehicleId: 'other')), throwsArgumentError);
      expect(
        () => rideCost(
          _ride(useKmRate: true, vehicleId: 'other'),
          _golf,
          Currency.eur,
          _members,
        ),
        throwsArgumentError,
      );
    });

    test('trip errors pass through', () {
      expect(_costErr(_ride(distance: 0)), const NonPositiveDistance());
      expect(_costErr(_ride(passengers: {'Z'})), const TripUnknownMember('Z'));
      expect(_costErr(_ride(passengers: {'A'})), const DriverIsPassenger());
      expect(
        _costErr(_ride(passengers: {}, driverCounts: false)),
        const TripNoParticipants(),
      );
      expect(
        _costErr(_ride(tolls: -1)),
        const TripNegativeValue('tollsCents'),
      );
    });
  });

  group('RideTemplate', () {
    test('defaults', () {
      const t = RideTemplate(
        id: 't',
        name: 'Arbeit',
        distanceMeters: 1000,
        vehicleId: 'golf',
      );
      expect(t.roundTrip, isFalse);
      expect(t.defaultDriverId, isNull);
      expect(t.defaultPassengerIds, isEmpty);
      expect(t.tollsCents, 0);
    });
  });

  group('RidePeriod', () {
    bool inWeek(int y, int w, String iso) => Week(y, w).contains(_d(iso));

    test('ISO week: Monday starts, Sunday ends', () {
      // 2026-10-05 is a Monday and starts W41.
      expect(inWeek(2026, 40, '2026-10-04'), isTrue);
      expect(inWeek(2026, 41, '2026-10-04'), isFalse);
      expect(inWeek(2026, 40, '2026-09-28'), isTrue);
      expect(inWeek(2026, 41, '2026-09-28'), isFalse);
      expect(inWeek(2026, 41, '2026-10-05'), isTrue);
      expect(inWeek(2026, 41, '2026-10-11'), isTrue);
      expect(inWeek(2026, 41, '2026-10-12'), isFalse);
      expect(inWeek(2026, 42, '2026-10-12'), isTrue);
      expect(inWeek(2025, 41, '2026-10-05'), isFalse);
    });

    test('week 53 spans the year boundary (2026-12-31 and 2027-01-01)', () {
      // 2026 has 53 ISO weeks; W53 is Mon 2026-12-28 .. Sun 2027-01-03.
      for (final d in [
        '2026-12-28',
        '2026-12-31',
        '2027-01-01',
        '2027-01-03',
      ]) {
        expect(inWeek(2026, 53, d), isTrue, reason: d);
        expect(inWeek(2027, 1, d), isFalse, reason: d);
        expect(inWeek(2026, 52, d), isFalse, reason: d);
      }
      expect(inWeek(2027, 1, '2027-01-04'), isTrue);
      expect(inWeek(2026, 53, '2027-01-04'), isFalse);
      expect(inWeek(2026, 53, '2026-12-27'), isFalse);
      expect(inWeek(2026, 52, '2026-12-27'), isTrue);
    });

    test('early January can belong to the previous ISO year', () {
      // 2021-01-01 (Friday) is in 2020-W53.
      expect(inWeek(2020, 53, '2021-01-01'), isTrue);
      expect(inWeek(2021, 1, '2021-01-01'), isFalse);
      expect(inWeek(2021, 1, '2021-01-04'), isTrue);
    });

    test('late December can belong to the next ISO year', () {
      // 2024-12-30 (Monday) is in 2025-W01.
      expect(inWeek(2025, 1, '2024-12-30'), isTrue);
      expect(inWeek(2024, 52, '2024-12-30'), isFalse);
      expect(inWeek(2024, 1, '2024-12-30'), isFalse);
    });

    test('week 1 contains the first Thursday', () {
      // 2026-01-01 is a Thursday: W1 is Mon 2025-12-29 .. Sun 2026-01-04.
      expect(inWeek(2026, 1, '2025-12-29'), isTrue);
      expect(inWeek(2026, 1, '2026-01-04'), isTrue);
      expect(inWeek(2026, 2, '2026-01-04'), isFalse);
      expect(inWeek(2026, 2, '2026-01-05'), isTrue);
      expect(inWeek(2026, 2, '2026-01-11'), isTrue);
      expect(inWeek(2026, 3, '2026-01-12'), isTrue);
    });

    test('time of day is ignored', () {
      expect(
        Day(DateTime(2026, 10, 5, 23, 59)).contains(DateTime(2026, 10, 5)),
        isTrue,
      );
      expect(
        Day(DateTime(2026, 10, 5)).contains(DateTime(2026, 10, 6, 0, 1)),
        isFalse,
      );
      expect(
        Day(DateTime(2026, 10, 5)).contains(DateTime(2026, 10, 4, 23, 59)),
        isFalse,
      );
    });

    test('Month', () {
      expect(const Month(2026, 10).contains(_d('2026-10-01')), isTrue);
      expect(const Month(2026, 10).contains(_d('2026-10-31')), isTrue);
      expect(const Month(2026, 10).contains(_d('2026-09-30')), isFalse);
      expect(const Month(2026, 10).contains(_d('2026-11-01')), isFalse);
      expect(const Month(2026, 10).contains(_d('2025-10-15')), isFalse);
    });

    test('Custom is inclusive on both ends and ignores time', () {
      final p = Custom(DateTime(2026, 10, 5, 18), DateTime(2026, 10, 9, 6));
      expect(p.contains(DateTime(2026, 10, 5)), isTrue);
      expect(p.contains(DateTime(2026, 10, 9, 23)), isTrue);
      expect(p.contains(DateTime(2026, 10, 7)), isTrue);
      expect(p.contains(DateTime(2026, 10, 4, 23, 59)), isFalse);
      expect(p.contains(DateTime(2026, 10, 10)), isFalse);
      // A single-day range.
      final one = Custom(_d('2026-10-05'), _d('2026-10-05'));
      expect(one.contains(_d('2026-10-05')), isTrue);
      expect(one.contains(_d('2026-10-06')), isFalse);
      // Reversed bounds match nothing.
      expect(
        Custom(_d('2026-10-09'), _d('2026-10-05')).contains(_d('2026-10-07')),
        isFalse,
      );
    });

    test('value equality', () {
      expect(Day(DateTime(2026, 10, 5, 8)), Day(DateTime(2026, 10, 5, 9)));
      expect(Day(_d('2026-10-05')), isNot(Day(_d('2026-10-06'))));
      expect(Day(_d('2026-10-05')).hashCode, Day(_d('2026-10-05')).hashCode);
      expect(const Week(2026, 1), const Week(2026, 1));
      expect(const Week(2026, 1), isNot(const Week(2026, 2)));
      expect(const Week(2026, 1), isNot(const Week(2027, 1)));
      expect(const Week(2026, 1).hashCode, const Week(2026, 1).hashCode);
      expect(const Month(2026, 1), const Month(2026, 1));
      expect(const Month(2026, 1), isNot(const Month(2026, 2)));
      expect(const Month(2026, 1), isNot(const Month(2027, 1)));
      expect(const Month(2026, 1).hashCode, const Month(2026, 1).hashCode);
      final c = Custom(_d('2026-01-01'), _d('2026-01-05'));
      expect(c, Custom(_d('2026-01-01'), _d('2026-01-05')));
      expect(c, isNot(Custom(_d('2026-01-02'), _d('2026-01-05'))));
      expect(c, isNot(Custom(_d('2026-01-01'), _d('2026-01-06'))));
      expect(c.hashCode, Custom(_d('2026-01-01'), _d('2026-01-05')).hashCode);
      expect(const Month(2026, 1), isNot(const Week(2026, 1)));
      expect(const Week(2026, 1), isNot(const Month(2026, 1)));
      expect(c, isNot(const Month(2026, 1)));
      expect(Day(_d('2026-01-01')), isNot(const Month(2026, 1)));
    });

    test('toString', () {
      expect(const Week(2026, 53).toString(), 'Week(2026-W53)');
      expect(const Month(2026, 10).toString(), 'Month(2026-10)');
      expect(Day(_d('1970-01-02')).toString(), 'Day(1)');
      expect(
        Custom(_d('1970-01-02'), _d('1970-01-04')).toString(),
        'Custom(1..3)',
      );
    });
  });

  group('aggregateRides', () {
    test('empty and out-of-period rides give no aggregates', () {
      expect(_aggOk(const [], const Month(2026, 10)), isEmpty);
      expect(
        _aggOk([_ride(date: _d('2026-09-30'))], const Month(2026, 10)),
        isEmpty,
      );
    });

    test('filters by period, time ignored, sorts by (date, id)', () {
      final rides = [
        _ride(id: 'b', date: DateTime(2026, 10, 6, 7)),
        _ride(id: 'z', date: DateTime(2026, 10, 5, 23)),
        _ride(id: 'a', date: DateTime(2026, 10, 6, 22)),
        _ride(id: 'out', date: DateTime(2026, 11)),
      ];
      final aggs = _aggOk(rides, const Month(2026, 10));
      expect(aggs, hasLength(1));
      expect(aggs.single.rideIds, ['z', 'a', 'b']);
      expect(aggs.single.driverId, 'A');
      expect(aggs.single.period, const Month(2026, 10));
    });

    test('one aggregate per driver, ordered by tieOrder', () {
      final rides = [
        _ride(id: '1', driver: 'C', passengers: {'A'}),
        _ride(id: '2', driver: 'B', passengers: {'A'}),
        _ride(id: '3', passengers: {'B'}),
      ];
      final aggs = _aggOk(rides, const Month(2026, 10));
      expect(aggs.map((a) => a.driverId), ['A', 'B', 'C']);
      final reordered = aggregateRides(
        rides: rides,
        vehicles: _vehicles,
        currency: Currency.eur,
        members: const [
          Member(id: 'A', position: 2),
          Member(id: 'B', position: 1),
          Member(id: 'C', position: 0),
          Member(id: 'D', position: 3),
        ],
        period: const Month(2026, 10),
      );
      expect(
        (reordered as Ok<List<RideAggregate>, TripError>).value.map(
          (a) => a.driverId,
        ),
        ['C', 'B', 'A'],
      );
    });

    test('shares have every member as a key and are unmodifiable', () {
      final a = _aggOk([_ride()], const Month(2026, 10)).single;
      expect(a.shares.keys, ['A', 'B', 'C', 'D']);
      expect(a.shares['D'], 0);
      expect(() => a.shares['A'] = 1, throwsUnsupportedError);
      expect(() => a.rideIds.add('x'), throwsUnsupportedError);
    });

    test('shares are summed per ride, never re-allocated', () {
      // Each ride splits 468 as 234/234 (A, B) and 156 x 3 (A, B, C).
      final aggs = _aggOk([
        _ride(id: 'r1'),
        _ride(id: 'r3', passengers: {'B', 'C'}, date: DateTime(2026, 10, 7)),
      ], const Month(2026, 10));
      expect(aggs.single.totalCents, 936);
      expect(aggs.single.shares, {'A': 390, 'B': 390, 'C': 156, 'D': 0});
    });

    test('first error wins in (date, id) order', () {
      final rides = [
        _ride(id: 'c', date: _d('2026-10-03'), distance: 0),
        _ride(id: 'b', date: _d('2026-10-02'), passengers: {'Z'}),
        _ride(id: 'a', date: _d('2026-10-02'), passengers: {'A'}),
        _ride(
          id: 'd',
          date: _d('2026-10-01'),
          driverCounts: false,
        ).withNoPassengers(),
      ];
      final r = _agg(rides, const Month(2026, 10));
      expect(
        (r as Err<List<RideAggregate>, TripError>).error,
        const TripNoParticipants(),
      );
      expect(
        (_agg(
          rides.take(3),
          const Month(2026, 10),
        ) as Err<List<RideAggregate>, TripError>).error,
        const DriverIsPassenger(),
      );
      expect(
        (_agg(
          rides.take(1),
          const Month(2026, 10),
        ) as Err<List<RideAggregate>, TripError>).error,
        const NonPositiveDistance(),
      );
    });

    test('errors in rides outside the period are ignored', () {
      final rides = [_ride(id: 'bad', date: _d('2026-11-01'), distance: 0)];
      expect(_aggOk(rides, const Month(2026, 10)), isEmpty);
    });

    test('MissingKmRate is reported', () {
      final r = _agg([_ride(useKmRate: true)], const Month(2026, 10));
      expect(
        (r as Err<List<RideAggregate>, TripError>).error,
        const MissingKmRate(),
      );
    });

    test('unknown vehicle throws ArgumentError', () {
      expect(
        () => _agg([_ride(vehicleId: 'nope')], const Month(2026, 10)),
        throwsArgumentError,
      );
      // Not in the period: never looked up.
      expect(
        _aggOk([
          _ride(vehicleId: 'nope', date: _d('2026-01-01')),
        ], const Month(2026, 10)),
        isEmpty,
      );
    });

    test('vehicleId mismatch in the map throws ArgumentError', () {
      expect(
        () => _agg(
          [_ride()],
          const Month(2026, 10),
          vehicles: {'golf': _carWithKmRate.copyWithId('other')},
        ),
        throwsArgumentError,
      );
    });

    test('Week and Custom periods filter', () {
      final rides = [
        _ride(id: 'sun', date: _d('2026-10-04')),
        _ride(id: 'mon', date: _d('2026-10-05')),
        _ride(id: 'sun2', date: _d('2026-10-11')),
        _ride(id: 'mon2', date: _d('2026-10-12')),
      ];
      expect(_aggOk(rides, const Week(2026, 41)).single.rideIds, [
        'mon',
        'sun2',
      ]);
      expect(
        _aggOk(
          rides,
          Custom(_d('2026-10-05'), _d('2026-10-11')),
        ).single.rideIds,
        ['mon', 'sun2'],
      );
      expect(_aggOk(rides, Day(_d('2026-10-12'))).single.rideIds, ['mon2']);
    });
  });

  group('rideAggregateToExpense', () {
    test('driver pays the total, split is the summed shares', () {
      final agg = _aggOk([
        _ride(id: 'r1'),
        _ride(id: 'r3', passengers: {'B', 'C'}, date: DateTime(2026, 10, 7)),
      ], const Month(2026, 10)).single;
      final e = (rideAggregateToExpense(
        id: 'e1',
        title: 'Oktober',
        date: _d('2026-10-31'),
        aggregate: agg,
        currency: Currency.eur,
        members: _members,
      ) as Ok<Expense, ExpenseError>).value;
      expect(e.amountCents, 936);
      expect(e.payers, {'A': 936});
      expect(e.shares, agg.shares);
      expect(e.title, 'Oktober');
    });

    test('a zero total is an expense error', () {
      final agg = _aggOk([_ride(price: 0)], const Month(2026, 10)).single;
      expect(agg.totalCents, 0);
      final r = rideAggregateToExpense(
        id: 'e1',
        title: 'x',
        date: _d('2026-10-31'),
        aggregate: agg,
        currency: Currency.eur,
        members: _members,
      );
      expect(r, isA<Err<Expense, ExpenseError>>());
    });
  });

  group('properties', () {
    const period = Month(2026, 10);

    Glados(any.intNoShrink(0, 1 << 30)).test(
      'sum of aggregates equals sum of ride costs; shares sum to total',
      (seed) {
        final rides = _randomRides(seed);
        final inOct = rides.where((r) => r.date.month == 10);
        final vs = {'golf': _carWithKmRate};
        final r = aggregateRides(
          rides: rides,
          vehicles: vs,
          currency: Currency.eur,
          members: _members,
          period: period,
        );
        final aggs = (r as Ok<List<RideAggregate>, TripError>).value;
        final expected = inOct.fold<int>(
          0,
          (s, ride) =>
              s +
              ((rideCost(
                ride,
                _carWithKmRate,
                Currency.eur,
                _members,
              ) as Ok<TripCost, TripError>).value.totalCents),
        );
        expect(aggs.fold<int>(0, (s, a) => s + a.totalCents), expected);
        for (final a in aggs) {
          expect(a.shares.values.fold<int>(0, (s, c) => s + c), a.totalCents);
        }
        expect(
          aggs.fold<int>(0, (s, a) => s + a.rideIds.length),
          inOct.length,
        );
      },
    );

    Glados(any.intNoShrink(0, 1 << 30)).test(
      'day by day summed equals the month',
      (seed) {
        final rides = _randomRides(seed);
        final vs = {'golf': _carWithKmRate};
        List<RideAggregate> agg(RidePeriod p) => (aggregateRides(
          rides: rides,
          vehicles: vs,
          currency: Currency.eur,
          members: _members,
          period: p,
        ) as Ok<List<RideAggregate>, TripError>).value;
        final totals = <String, int>{};
        final shares = <String, Map<String, int>>{};
        for (var day = 1; day <= 31; day++) {
          for (final a in agg(Day(DateTime(2026, 10, day)))) {
            totals[a.driverId] = (totals[a.driverId] ?? 0) + a.totalCents;
            final s = shares.putIfAbsent(
              a.driverId,
              () => {for (final m in _members) m.id: 0},
            );
            a.shares.forEach((k, v) => s[k] = s[k]! + v);
          }
        }
        final month = agg(period);
        expect({for (final a in month) a.driverId: a.totalCents}, totals);
        expect({for (final a in month) a.driverId: a.shares}, shares);
      },
    );

    Glados2(
      any.intNoShrink(0, 1 << 30),
      any.intNoShrink(0, 1 << 30),
    ).test('deterministic under input reordering', (seed, shuffleSeed) {
      final rides = _randomRides(seed);
      final vs = {'golf': _carWithKmRate};
      List<String> run(
        List<Ride> input,
      ) => [
        for (final a in (aggregateRides(
          rides: input,
          vehicles: vs,
          currency: Currency.eur,
          members: _members,
          period: period,
        ) as Ok<List<RideAggregate>, TripError>).value)
          '${a.driverId} ${a.rideIds} ${a.totalCents} ${a.shares}',
      ];
      final shuffled = [...rides]..shuffle(Random(shuffleSeed));
      expect(run(shuffled), run(rides));
    });
  });
}

extension on Ride {
  Ride withNoPassengers() => Ride(
    id: id,
    date: date,
    distanceMeters: distanceMeters,
    roundTrip: roundTrip,
    tollsCents: tollsCents,
    vehicleId: vehicleId,
    driverId: driverId,
    driverCounts: driverCounts,
    pricePerUnitMilli: pricePerUnitMilli,
    useKmRate: useKmRate,
  );
}

extension on Vehicle {
  Vehicle copyWithId(String newId) => Vehicle(
    id: newId,
    name: name,
    fuelType: fuelType,
    consumptionMilliPer100km: consumptionMilliPer100km,
    wearMilliPerKm: wearMilliPerKm,
    kmRateMilliPerKm: kmRateMilliPerKm,
  );
}
