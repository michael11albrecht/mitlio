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
  int distance = 20000,
}) => Ride(
  id: id,
  date: DateTime.parse('${date}T00:00:00Z'),
  distanceMeters: distance,
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
  List<Ride> history, {
  List<Ride>? unsettled,
  Set<String> nonDrivers = const {},
}) => suggestDriver(
  members: members,
  history: history,
  unsettled: unsettled ?? history,
  nonDrivers: nonDrivers,
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
      expect(suggest(const [], const []), isNull);
    });

    test('owner case: the one who only rode along is next', () {
      // Peter drove Johanna and Lars, then Johanna drove Peter and Lars,
      // 70 km round trips.
      final history = [
        ride('1', '2026-11-12', 'peter', ['johanna', 'lars'], distance: 70000),
        ride('2', '2026-11-14', 'johanna', ['peter', 'lars'], distance: 70000),
      ];
      final members = ['peter', 'johanna', 'lars'];
      expect(meterBalances(history, members), {
        'peter': 0,
        'johanna': 0,
        'lars': -280000,
      });
      expect(suggest(members, history), 'lars');
    });

    test('everybody is a candidate without a mark', () {
      final history = [
        ride('1', '2026-02-01', 'a', ['b']),
      ];
      expect(suggest(['a', 'b', 'c'], history), 'b');
    });

    test('a driver with a lower balance beats one who drove longer ago', () {
      final history = [
        ride('1', '2026-02-01', 'a', ['b']),
        ride('2', '2026-02-02', 'a', ['b']),
        ride('3', '2026-02-03', 'b', ['a']),
      ];
      expect(suggest(['a', 'b'], history), 'b');
    });

    test('a non-driver is never suggested, even with the lowest balance', () {
      final history = [
        ride('1', '2026-02-01', 'a', ['b', 'c']),
      ];
      expect(suggest(['a', 'b', 'c'], history), 'b');
      expect(suggest(['a', 'b', 'c'], history, nonDrivers: {'b'}), 'c');
      expect(suggest(['a', 'b', 'c'], history, nonDrivers: {'b', 'c'}), 'a');
    });

    test('a non-driver who drove before is excluded too', () {
      final history = [
        ride('1', '2026-02-01', 'b', ['a']),
      ];
      expect(suggest(['a', 'b'], history, nonDrivers: {'b'}), 'a');
    });

    test('nobody drives: falls back to everyone', () {
      expect(suggest(['a', 'b'], const [], nonDrivers: {'a', 'b'}), 'a');
    });

    test('equal balance: who drove longest ago, then member order', () {
      final settled = [
        ride('1', '2026-02-01', 'b', ['a']),
        ride('2', '2026-02-02', 'a', ['b']),
      ];
      // Both drove, balance 0 each, a drove last: b.
      expect(suggest(['a', 'b'], settled, unsettled: const []), 'b');
      // Never drove beats drove.
      expect(
        suggest(
          ['a', 'b'],
          [
            ride('1', '2026-02-02', 'a', ['b']),
          ],
          unsettled: const [],
        ),
        'b',
      );
      // Nothing to tell them apart: member order.
      expect(suggest(['b', 'a'], const []), 'b');
    });

    test('two people alternate: a, b, a, b', () {
      final history = <Ride>[];
      final seen = <String?>[];
      for (var i = 0; i < 6; i++) {
        final next = suggest(['a', 'b'], history);
        seen.add(next);
        history.add(
          ride('$i', '2026-02-0${i + 1}', next!, next == 'a' ? ['b'] : ['a']),
        );
      }
      expect(seen, ['a', 'b', 'a', 'b', 'a', 'b']);
    });

    test('ignores people who left the group', () {
      final history = [
        ride('1', '2026-02-01', 'a', ['gone']),
      ];
      expect(suggest(['a', 'b'], history), 'b');
    });
  });

  group('driverCandidates', () {
    test('everyone except the non-drivers', () {
      expect(
        driverCandidates(members: ['a', 'b', 'c'], nonDrivers: {'b'}),
        {'a', 'c'},
      );
    });

    test('everyone if nobody is left', () {
      expect(
        driverCandidates(members: ['a', 'b'], nonDrivers: {'a', 'b', 'x'}),
        {'a', 'b'},
      );
    });
  });

  group('shouldAskNonDriver', () {
    // a drives b (and c) over and over; b rides along.
    List<Ride> rides(int n, {List<String> passengers = const ['b']}) => [
      for (var i = 0; i < n; i++) ride('r$i', '2026-02-01', 'a', passengers),
    ];

    int? ask(
      List<Ride> rs, {
      String member = 'b',
      bool canDrive = true,
      bool asked = false,
    }) => shouldAskNonDriver(
      memberId: member,
      canDrive: canDrive,
      alreadyAsked: asked,
      rides: rs,
    );

    test('a pair needs max(4, 2 x 2) = 4 rides', () {
      expect(ask(rides(3)), isNull);
      expect(ask(rides(4)), 4);
      expect(ask(rides(7)), 7);
    });

    test('a bigger carpool needs 2 x its size', () {
      final three = rides(5, passengers: ['b', 'c', 'd']);
      // a, b, c, d: 4 people -> 8.
      expect(ask(three), isNull);
      expect(ask(rides(8, passengers: ['b', 'c', 'd'])), 8);
      // a, b, c, d, e: 5 people -> 10.
      expect(
        ask([
          ...rides(8, passengers: ['b', 'c', 'd']),
          ride('x', '2026-02-02', 'e', ['b']),
        ]),
        isNull,
      );
    });

    test('never when they drove once, asked before or are marked', () {
      expect(
        ask([
          ...rides(8),
          ride('d', '2026-02-02', 'b', ['a']),
        ]),
        isNull,
      );
      expect(ask(rides(8), asked: true), isNull);
      expect(ask(rides(8), canDrive: false), isNull);
    });

    test('only rides they rode along count', () {
      expect(
        ask(
          rides(8, passengers: ['c']),
        ),
        isNull,
      );
      expect(ask(rides(8), member: 'a'), isNull);
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
