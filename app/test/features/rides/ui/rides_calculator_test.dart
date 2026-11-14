import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

Ride ride(
  String id,
  String date,
  String driver,
  List<String> passengers, {
  int price = 1750,
  bool roundTrip = true,
  String vehicle = 'v',
}) => Ride(
  id: id,
  date: DateTime.parse('${date}T00:00:00Z'),
  distanceMeters: 20000,
  roundTrip: roundTrip,
  vehicleId: vehicle,
  driverId: driver,
  passengerIds: passengers.toSet(),
  pricePerUnitMilli: price,
);

RideTemplate template({String? driver, Set<String> passengers = const {}}) =>
    RideTemplate(
      id: 't',
      name: 'Arbeit',
      distanceMeters: 20000,
      vehicleId: 'v',
      defaultDriverId: driver,
      defaultPassengerIds: passengers,
    );

String? suggest(
  List<String> members,
  RideTemplate t,
  List<Ride> history, {
  List<Ride>? unsettled,
}) => suggestDriver(
  members: members,
  template: t,
  history: history,
  unsettled: unsettled ?? history,
);

void main() {
  group('parseMilli', () {
    test('accepts comma and dot decimals', () {
      expect(parseMilli('6,5'), 6500);
      expect(parseMilli('6.5'), 6500);
      expect(parseMilli('20'), 20000);
      expect(parseMilli('0,08'), 80);
      expect(parseMilli('1,759'), 1759);
      expect(parseMilli(',5'), 500);
      expect(parseMilli(' 12, '), 12000);
    });

    test('rejects blank, signs, too many decimals and junk', () {
      for (final bad in ['', ' ', '-1', '1,2345', '1,2,3', 'a', '1 000']) {
        expect(parseMilli(bad), isNull, reason: bad);
      }
      expect(parseMilli('1234567890123'), isNull);
    });
  });

  group('formatting', () {
    test('formatMilli trims trailing zeros', () {
      expect(formatMilli(6500), '6,5');
      expect(formatMilli(20000), '20');
      expect(formatMilli(80, separator: '.'), '0.08');
      expect(formatMilli(1759), '1,759');
    });

    test('formatPriceMilli keeps two decimals', () {
      expect(formatPriceMilli(1750), '1,75');
      expect(formatPriceMilli(1759), '1,759');
      expect(formatPriceMilli(2000, separator: '.'), '2.00');
    });
  });

  group('prices', () {
    final golf = Vehicle(
      id: 'v',
      name: 'Golf',
      fuelType: FuelType.petrol,
      consumptionMilliPer100km: 6500,
    );

    test('fallbacks per fuel type', () {
      expect(defaultPriceMilli(FuelType.petrol), 1750);
      expect(defaultPriceMilli(FuelType.diesel), 1650);
      expect(defaultPriceMilli(FuelType.electric), 350);
      expect(defaultPriceMilli(FuelType.other), 1750);
    });

    test('the newest ride of the vehicle sets the price', () {
      expect(suggestedPriceMilli(golf, const []), 1750);
      expect(
        suggestedPriceMilli(golf, [
          ride('a', '2026-02-01', 'x', [], price: 1700),
          ride('b', '2026-02-03', 'x', [], price: 1799),
          ride('c', '2026-02-02', 'x', [], price: 1650),
          ride('z', '2026-02-09', 'x', [], price: 999, vehicle: 'other'),
        ]),
        1799,
      );
    });

    test('same day: the greater id wins', () {
      expect(
        suggestedPriceMilli(golf, [
          ride('b', '2026-02-03', 'x', [], price: 1700),
          ride('a', '2026-02-03', 'x', [], price: 1800),
        ]),
        1700,
      );
    });
  });

  test('meterBalances: driven minus ridden, round trips count twice', () {
    final b = meterBalances(
      [
        ride('1', '2026-02-01', 'a', ['b', 'c']),
        ride('2', '2026-02-02', 'b', ['a'], roundTrip: false),
        ride('3', '2026-02-03', 'zz', ['a']),
      ],
      ['a', 'b', 'c'],
    );
    expect(b, {'a': 40000 - 20000 - 40000, 'b': 20000 - 40000, 'c': -40000});
  });

  group('suggestDriver', () {
    test('empty group has nobody', () {
      expect(suggest(const [], template(), const []), isNull);
    });

    test('the default driver while nobody else drove the vehicle', () {
      final history = [
        ride('1', '2026-02-01', 'a', ['b']),
      ];
      expect(
        suggest(
          ['a', 'b', 'c'],
          template(driver: 'a', passengers: {'b'}),
          history,
        ),
        'a',
      );
    });

    test('lowest balance among the people who drove the vehicle', () {
      final history = [
        ride('1', '2026-02-01', 'a', ['b']),
        ride('2', '2026-02-02', 'a', ['b']),
        ride('3', '2026-02-03', 'b', ['a']),
      ];
      expect(
        suggest(
          ['a', 'b', 'c'],
          template(driver: 'a', passengers: {'b'}),
          history,
        ),
        'b',
      );
    });

    test('rides of other vehicles do not make someone eligible', () {
      final history = [
        ride('1', '2026-02-01', 'c', ['b'], vehicle: 'other'),
      ];
      expect(
        suggest(
          ['a', 'b', 'c'],
          template(driver: 'a', passengers: {'b'}),
          history,
        ),
        'a',
      );
    });

    test('equal balance: who drove longest ago, then member order', () {
      final settled = [
        ride('1', '2026-02-01', 'b', ['a']),
        ride('2', '2026-02-02', 'a', ['b']),
      ];
      // Both drove the vehicle, balance 0 each, a drove last: b.
      expect(
        suggest(
          ['a', 'b'],
          template(driver: 'a'),
          settled,
          unsettled: const [],
        ),
        'b',
      );
      // Never drove beats drove.
      expect(
        suggest(
          ['a', 'b'],
          template(driver: 'a', passengers: {'b'}),
          [
            ride('1', '2026-02-02', 'a', ['b']),
          ],
          unsettled: const [],
        ),
        'a',
      );
      // Nothing to tell them apart: member order.
      expect(suggest(['a', 'b'], template(driver: 'b'), const []), 'b');
    });

    test('no driver and no history: the carpool, else everyone', () {
      expect(
        suggest(
          ['a', 'b', 'c'],
          template(passengers: {'c', 'b'}),
          const [],
        ),
        'b',
      );
      expect(suggest(['a', 'b', 'c'], template(), const []), 'a');
    });

    test('ignores people who left the group', () {
      final history = [
        ride('1', '2026-02-01', 'gone', ['a']),
      ];
      expect(suggest(['a', 'b'], template(driver: 'gone'), history), 'a');
    });
  });

  test('defaultPassengers is the carpool without the driver', () {
    final t = template(driver: 'a', passengers: {'b', 'c'});
    expect(defaultPassengers(t, 'a'), {'b', 'c'});
    expect(defaultPassengers(t, 'b'), {'a', 'c'});
    expect(defaultPassengers(t, 'z'), {'a', 'b', 'c'});
  });

  group('summarizeRide', () {
    final golf = Vehicle(
      id: 'v',
      name: 'Golf',
      fuelType: FuelType.petrol,
      consumptionMilliPer100km: 6500,
    );
    const members = [
      Member(id: 'a', position: 0),
      Member(id: 'b', position: 1),
      Member(id: 'c', position: 2),
    ];

    test('total and what the passengers owe, in member order', () {
      final s = summarizeRide(
        ride('1', '2026-02-01', 'a', ['c', 'b']),
        golf,
        Currency.eur,
        members,
      )!;
      expect(s.totalCents, 455);
      expect(
        [for (final o in s.owes) (o.memberId, o.cents)],
        [
          ('b', 152),
          ('c', 151),
        ],
      );
    });

    test('null when the domain refuses', () {
      expect(
        summarizeRide(
          Ride(
            id: '1',
            date: DateTime.utc(2026),
            distanceMeters: 1000,
            vehicleId: 'v',
            driverId: 'a',
            pricePerUnitMilli: 1000,
            useKmRate: true,
          ),
          golf,
          Currency.eur,
          members,
        ),
        isNull,
      );
    });
  });
}
