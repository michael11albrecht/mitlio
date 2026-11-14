import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/rides/ui/ride_settlement.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

const _members = [
  Member(id: 'a', position: 0),
  Member(id: 'b', position: 1),
  Member(id: 'c', position: 2),
];

final _golf = Vehicle(
  id: 'v',
  name: 'Golf',
  fuelType: FuelType.petrol,
  consumptionMilliPer100km: 6500,
);

Ride _ride(
  String id, {
  String driver = 'a',
  Set<String> passengers = const {'b'},
  String vehicle = 'v',
  bool driverCounts = true,
  bool useKmRate = false,
  int day = 5,
  int month = 10,
}) => Ride(
  id: id,
  date: DateTime.utc(2026, month, day),
  distanceMeters: 20000,
  roundTrip: true,
  vehicleId: vehicle,
  driverId: driver,
  passengerIds: passengers,
  driverCounts: driverCounts,
  pricePerUnitMilli: 1799,
  useKmRate: useKmRate,
);

SettlementPlan? _plan(List<Ride> rides) => planSettlement(
  unsettled: rides,
  month: const Month(2026, 10),
  vehicles: {'v': _golf},
  currency: Currency.eur,
  members: _members,
);

void main() {
  group('planSettlement', () {
    test('groups the month per driver and ignores other months', () {
      final plan = _plan([
        _ride('r1'),
        _ride('r2', driver: 'b', passengers: {'a', 'c'}),
        _ride('r3', month: 11),
      ])!;
      expect(plan.drivers.map((d) => d.driverId), ['a', 'b']);
      expect(plan.rideCount, 2);
      expect(plan.totalCents, 468 + 468);
      expect(plan.isEmpty, isFalse);
    });

    test('nothing to settle is an empty plan', () {
      expect(_plan(const [])!.isEmpty, isTrue);
      expect(_plan([_ride('r3', month: 11)])!.isEmpty, isTrue);
    });

    test('an unknown vehicle or a rejected ride gives no plan', () {
      expect(_plan([_ride('r1', vehicle: 'gone')]), isNull);
      expect(_plan([_ride('r1', useKmRate: true)]), isNull);
    });

    test('sharesOf lists the passengers that owe something', () {
      final d = _plan([
        _ride('r1', passengers: {'b', 'c'}),
      ])!.drivers.single;
      expect(
        [
          for (final s in d.sharesOf(['c', 'b', 'a'])) s.memberId,
        ],
        ['c', 'b'],
      );
      expect(d.sharesOf(['a']), isEmpty);
    });
  });

  group('computeFairness', () {
    List<FairnessRow> fairness(List<Ride> rides) => computeFairness(
      rides: rides,
      vehicles: {'v': _golf},
      currency: Currency.eur,
      members: _members,
    );

    test('km and net add up, the net sums to zero', () {
      final rows = fairness([
        _ride('r1'),
        _ride('r2', driver: 'b', passengers: {'a', 'c'}),
      ]);
      expect(rows.map((r) => r.memberId), ['a', 'b', 'c']);
      expect(rows[0].metersDriven, 40000);
      expect(rows[0].metersRidden, 40000);
      expect(rows[2].metersDriven, 0);
      expect(rows.fold(0, (n, r) => n + r.netCents), 0);
      expect(rows[2].netCents, lessThan(0));
    });

    test('a driver who does not count owes nothing for the ride', () {
      final rows = fairness([_ride('r1', driverCounts: false)]);
      expect(rows[0].netCents, 468);
      expect(rows[1].netCents, -468);
    });

    test('skips rides it cannot cost', () {
      final rows = fairness([
        _ride('r1', vehicle: 'gone'),
        _ride('r2', useKmRate: true),
        _ride('r3', driver: 'x', passengers: {'y', 'a', 'x'}),
      ]);
      expect(rows.fold(0, (n, r) => n + r.metersDriven), 0);
      expect(rows.fold(0, (n, r) => n + r.metersRidden), 0);
      expect(rows.fold(0, (n, r) => n + r.netCents), 0);
    });
  });
}
