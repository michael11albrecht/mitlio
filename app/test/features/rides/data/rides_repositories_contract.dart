import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

/// Behaviour every vehicles, ride templates and rides repository must show;
/// run against Drift and the in-memory fakes.
void runRidesRepositoriesContract(
  String name,
  Future<Repos> Function() create,
) {
  group('Rides repositories contract ($name)', () {
    late Repos r;
    late String gid;
    late List<GroupMember> m;
    late Vehicle car;

    setUp(() async {
      r = await create();
      final seeded = await seedGroup(r);
      gid = seeded.groupId;
      m = seeded.members;
      car = ok(
        await r.vehicles.add(
          gid,
          name: 'Golf',
          fuelType: FuelType.diesel,
          consumptionMilliPer100km: 5500,
          wearMilliPerKm: 80,
          kmRateMilliPerKm: 300,
        ),
      );
    });

    group('vehicles', () {
      test('add trims, stores every field and reads back', () async {
        final v = ok(
          await r.vehicles.add(
            gid,
            name: '  Zoe ',
            fuelType: FuelType.electric,
            consumptionMilliPer100km: 16000,
          ),
        );
        expect(v.name, 'Zoe');
        expect(v.fuelType, FuelType.electric);
        expect(v.wearMilliPerKm, 0);
        expect(v.kmRateMilliPerKm, isNull);
        expect(ok(await r.vehicles.get(v.id)), v);
        expect(car.kmRateMilliPerKm, 300);
        expect(ok(await r.vehicles.get(car.id)), car);
      });

      test('add validates input and group', () async {
        Future<RepositoryError> add({
          String name = 'x',
          int consumption = 1000,
          int wear = 0,
          String group = 'g',
        }) async => err(
          await r.vehicles.add(
            group == 'g' ? gid : group,
            name: name,
            fuelType: FuelType.petrol,
            consumptionMilliPer100km: consumption,
            wearMilliPerKm: wear,
          ),
        );
        expect(await add(name: ' '), isA<InvalidData>());
        expect(await add(consumption: 0), isA<InvalidData>());
        expect(await add(wear: -1), isA<InvalidData>());
        expect(await add(group: 'nope'), const NotFound('group', 'nope'));
      });

      test('update replaces fields, validates and reports unknown', () async {
        final changed = ok(
          await r.vehicles.update(
            Vehicle(
              id: car.id,
              name: ' Passat ',
              fuelType: FuelType.petrol,
              consumptionMilliPer100km: 7000,
            ),
          ),
        );
        expect(changed.name, 'Passat');
        expect(changed.kmRateMilliPerKm, isNull);
        expect(ok(await r.vehicles.get(car.id)), changed);
        expect(
          err(
            await r.vehicles.update(
              Vehicle(
                id: 'nope',
                name: 'x',
                fuelType: FuelType.other,
                consumptionMilliPer100km: 1,
              ),
            ),
          ),
          isA<NotFound>(),
        );
        expect(
          err(
            await r.vehicles.update(
              Vehicle(
                id: car.id,
                name: '',
                fuelType: FuelType.other,
                consumptionMilliPer100km: 1,
              ),
            ),
          ),
          isA<InvalidData>(),
        );
      });

      test('soft delete, undo, restore errors', () async {
        expect(err(await r.vehicles.get('nope')), isA<NotFound>());
        expect(err(await r.vehicles.softDelete('nope')), isA<NotFound>());
        expect(err(await r.vehicles.restore('nope')), isA<NotFound>());
        expect(err(await r.vehicles.restore(car.id)), isA<Conflict>());
        final undo = ok(await r.vehicles.softDelete(car.id));
        expect(err(await r.vehicles.get(car.id)), isA<NotFound>());
        expect(err(await r.vehicles.softDelete(car.id)), isA<NotFound>());
        ok(await undo());
        expect(ok(await r.vehicles.get(car.id)), car);
      });

      test('watchVehicles emits initial value and every change', () async {
        final probe = StreamProbe(r.vehicles.watchVehicles(gid));
        expect(await probe.next(), [car]);
        final other = ok(
          await r.vehicles.add(
            gid,
            name: 'Zoe',
            fuelType: FuelType.electric,
            consumptionMilliPer100km: 16000,
          ),
        );
        expect(await probe.next(), [car, other]);
        final undo = ok(await r.vehicles.softDelete(car.id));
        expect(await probe.next(), [other]);
        ok(await undo());
        expect(await probe.next(), [car, other]);
      });
    });

    group('ride templates', () {
      RideTemplate template({
        String name = 'Arbeit',
        String? vehicleId,
        String? driver,
        Set<String>? passengers,
        int distance = 12000,
        int tolls = 0,
      }) => RideTemplate(
        id: 'ignored',
        name: name,
        distanceMeters: distance,
        vehicleId: vehicleId ?? car.id,
        roundTrip: true,
        defaultDriverId: driver ?? m[0].id,
        defaultPassengerIds: passengers ?? {m[1].id, m[2].id},
        tollsCents: tolls,
      );

      void expectSame(RideTemplate a, RideTemplate b) {
        expect(a.id, b.id);
        expect(a.name, b.name);
        expect(a.distanceMeters, b.distanceMeters);
        expect(a.roundTrip, b.roundTrip);
        expect(a.vehicleId, b.vehicleId);
        expect(a.defaultDriverId, b.defaultDriverId);
        expect(a.defaultPassengerIds, b.defaultPassengerIds);
        expect(a.tollsCents, b.tollsCents);
      }

      test('add stores a fresh id and round-trips every field', () async {
        final t = ok(
          await r.rideTemplates.add(
            gid,
            template(name: ' Arbeit ', tolls: 250),
          ),
        );
        expect(t.id, isNot('ignored'));
        expect(t.name, 'Arbeit');
        expect(t.tollsCents, 250);
        expect(t.defaultPassengerIds, {m[1].id, m[2].id});
        expectSame(ok(await r.rideTemplates.get(t.id)), t);
        final bare = ok(
          await r.rideTemplates.add(
            gid,
            RideTemplate(
              id: 'x',
              name: 'Bare',
              distanceMeters: 0,
              vehicleId: car.id,
            ),
          ),
        );
        expect(bare.defaultDriverId, isNull);
        expect(bare.defaultPassengerIds, isEmpty);
      });

      test('add validates input and references', () async {
        Future<RepositoryError> add(RideTemplate t, [String? group]) async =>
            err(await r.rideTemplates.add(group ?? gid, t));
        expect(await add(template(name: ' ')), isA<InvalidData>());
        expect(await add(template(distance: -1)), isA<InvalidData>());
        expect(await add(template(tolls: -1)), isA<InvalidData>());
        expect(
          await add(template(), 'nope'),
          const NotFound('group', 'nope'),
        );
        expect(
          await add(template(vehicleId: 'nope')),
          const NotFound('vehicle', 'nope'),
        );
        expect(
          await add(template(driver: 'nope')),
          const NotFound('member', 'nope'),
        );
        expect(
          await add(template(passengers: {'nope'})),
          const NotFound('member', 'nope'),
        );
      });

      test('update replaces fields, validates and reports unknown', () async {
        final t = ok(await r.rideTemplates.add(gid, template()));
        final changed = ok(
          await r.rideTemplates.update(
            RideTemplate(
              id: t.id,
              name: 'Training',
              distanceMeters: 5000,
              vehicleId: car.id,
              defaultPassengerIds: {m[2].id},
            ),
          ),
        );
        expect(changed.name, 'Training');
        expect(changed.defaultDriverId, isNull);
        expectSame(ok(await r.rideTemplates.get(t.id)), changed);
        expect(
          err(await r.rideTemplates.update(template())),
          isA<NotFound>(),
        );
        expect(
          err(
            await r.rideTemplates.update(
              RideTemplate(
                id: t.id,
                name: '',
                distanceMeters: 1,
                vehicleId: car.id,
              ),
            ),
          ),
          isA<InvalidData>(),
        );
        expect(
          err(
            await r.rideTemplates.update(
              RideTemplate(
                id: t.id,
                name: 'x',
                distanceMeters: 1,
                vehicleId: 'nope',
              ),
            ),
          ),
          isA<NotFound>(),
        );
      });

      test('soft delete, undo, restore errors', () async {
        final t = ok(await r.rideTemplates.add(gid, template()));
        expect(err(await r.rideTemplates.get('nope')), isA<NotFound>());
        expect(err(await r.rideTemplates.softDelete('nope')), isA<NotFound>());
        expect(err(await r.rideTemplates.restore('nope')), isA<NotFound>());
        expect(err(await r.rideTemplates.restore(t.id)), isA<Conflict>());
        final undo = ok(await r.rideTemplates.softDelete(t.id));
        expect(err(await r.rideTemplates.get(t.id)), isA<NotFound>());
        ok(await undo());
        expectSame(ok(await r.rideTemplates.get(t.id)), t);
      });

      test('watchTemplates emits initial value and every change', () async {
        final probe = StreamProbe(r.rideTemplates.watchTemplates(gid));
        expect(await probe.next(), isEmpty);
        final t = ok(await r.rideTemplates.add(gid, template()));
        expect((await probe.next()).single.id, t.id);
        final undo = ok(await r.rideTemplates.softDelete(t.id));
        expect(await probe.next(), isEmpty);
        ok(await undo());
        expect((await probe.next()).single.id, t.id);
      });
    });

    group('rides', () {
      Ride ride(
        String id, {
        DateTime? date,
        Set<String>? passengers,
        int distance = 12000,
        int price = 1800,
      }) => Ride(
        id: id,
        date: date ?? DateTime.utc(2026, 3, 2),
        distanceMeters: distance,
        roundTrip: true,
        tollsCents: 150,
        vehicleId: car.id,
        driverId: m[0].id,
        passengerIds: passengers ?? {m[2].id, m[1].id},
        driverCounts: false,
        pricePerUnitMilli: price,
        useKmRate: true,
      );

      Future<RideEntry> log(Ride ride) async =>
          ok(await r.rides.log(gid, ride));

      Future<String> expenseId() async => ok(
        await r.expenses.create(
          gid,
          ExpenseDraft(
            title: 'Rides',
            amountCents: 900,
            currency: eur,
            date: DateTime.utc(2026, 3, 31),
            payers: {m[0].id: 900},
            split: EqualSplit({m[0].id, m[1].id, m[2].id}),
          ),
        ),
      ).expense.id;

      test('log stores every field and keeps only the calendar day', () async {
        final e = await log(ride('r1', date: DateTime(2026, 3, 2, 17, 45)));
        expect(e.groupId, gid);
        expect(e.createdAt, DateTime.utc(2026, 3, 1, 12));
        expect(e.settledExpenseId, isNull);
        expect(e.isSettled, isFalse);
        final x = e.ride;
        expect(x.date, DateTime.utc(2026, 3, 2));
        expect(x.distanceMeters, 12000);
        expect(x.roundTrip, isTrue);
        expect(x.tollsCents, 150);
        expect(x.vehicleId, car.id);
        expect(x.driverId, m[0].id);
        expect(x.passengerIds, {m[1].id, m[2].id});
        expect(x.driverCounts, isFalse);
        expect(x.pricePerUnitMilli, 1800);
        expect(x.useKmRate, isTrue);
        expect(ok(await r.rides.get('r1')), e);
        expect(e.toString(), contains('r1'));
        expect(e.hashCode, ok(await r.rides.get('r1')).hashCode);
      });

      test('log validates input, references and duplicates', () async {
        Future<RepositoryError> bad(Ride x, [String? group]) async =>
            err(await r.rides.log(group ?? gid, x));
        expect(await bad(ride('a', distance: -1)), isA<InvalidData>());
        expect(await bad(ride('a', price: -1)), isA<InvalidData>());
        expect(await bad(ride('a'), 'nope'), const NotFound('group', 'nope'));
        expect(
          await bad(
            Ride(
              id: 'a',
              date: DateTime.utc(2026),
              distanceMeters: 1,
              vehicleId: 'nope',
              driverId: m[0].id,
              pricePerUnitMilli: 1,
              tollsCents: -5,
            ),
          ),
          isA<InvalidData>(),
        );
        expect(
          await bad(
            Ride(
              id: 'a',
              date: DateTime.utc(2026),
              distanceMeters: 1,
              vehicleId: 'nope',
              driverId: m[0].id,
              pricePerUnitMilli: 1,
            ),
          ),
          const NotFound('vehicle', 'nope'),
        );
        expect(
          await bad(ride('a', passengers: {'nope'})),
          const NotFound('member', 'nope'),
        );
        await log(ride('a'));
        expect(await bad(ride('a')), isA<Conflict>());
      });

      test('update replaces fields and validates', () async {
        await log(ride('r1'));
        final changed = ok(
          await r.rides.update(
            Ride(
              id: 'r1',
              date: DateTime.utc(2026, 3, 3),
              distanceMeters: 500,
              vehicleId: car.id,
              driverId: m[1].id,
              pricePerUnitMilli: 1900,
            ),
          ),
        );
        expect(changed.ride.date, DateTime.utc(2026, 3, 3));
        expect(changed.ride.driverId, m[1].id);
        expect(changed.ride.passengerIds, isEmpty);
        expect(changed.ride.driverCounts, isTrue);
        expect(changed.createdAt, DateTime.utc(2026, 3, 1, 12));
        expect(ok(await r.rides.get('r1')), changed);
        expect(
          err(await r.rides.update(ride('r1', price: -1))),
          isA<InvalidData>(),
        );
        expect(err(await r.rides.update(ride('nope'))), isA<NotFound>());
        expect(
          err(await r.rides.update(ride('r1', passengers: {'nope'}))),
          isA<NotFound>(),
        );
      });

      test('soft delete hides, undo restores, errors are typed', () async {
        final e = await log(ride('r1'));
        expect(err(await r.rides.softDelete('nope')), isA<NotFound>());
        expect(err(await r.rides.restore('nope')), isA<NotFound>());
        expect(err(await r.rides.restore('r1')), isA<Conflict>());
        final undo = ok(await r.rides.softDelete('r1'));
        expect(err(await r.rides.get('r1')), isA<NotFound>());
        expect(err(await r.rides.softDelete('r1')), isA<NotFound>());
        expect(err(await r.rides.log(gid, ride('r1'))), isA<Conflict>());
        ok(await undo());
        expect(ok(await r.rides.get('r1')), e);
      });

      test('watchRides filters by period and orders by date then id', () async {
        final probe = StreamProbe(
          r.rides.watchRides(gid, const Month(2026, 3)),
        );
        expect(await probe.next(), isEmpty);
        await log(ride('b', date: DateTime.utc(2026, 3, 10)));
        expect((await probe.next()).map((e) => e.ride.id), ['b']);
        await log(ride('c', date: DateTime.utc(2026, 3, 2)));
        await probe.next();
        await log(ride('a', date: DateTime.utc(2026, 3, 2)));
        expect((await probe.next()).map((e) => e.ride.id), ['a', 'c', 'b']);
        await log(ride('other-day', date: DateTime.utc(2026, 3, 11)));
        final all = await probe.next();
        expect(all.map((e) => e.ride.id), ['a', 'c', 'b', 'other-day']);
        expect(() => all.add(all.first), throwsUnsupportedError);
        await log(ride('apr', date: DateTime.utc(2026, 4)));

        final day = StreamProbe(
          r.rides.watchRides(gid, Day(DateTime.utc(2026, 3, 2))),
        );
        expect((await day.next()).map((e) => e.ride.id), ['a', 'c']);
        final other = StreamProbe(
          r.rides.watchRides('other', const Month(2026, 3)),
        );
        expect(await other.next(), isEmpty);
      });

      test('markSettled locks the rides atomically', () async {
        await log(ride('r1'));
        await log(ride('r2'));
        final x = await expenseId();
        ok(await r.rides.markSettled(['r1', 'r2'], x));
        expect(ok(await r.rides.get('r1')).settledExpenseId, x);
        expect(ok(await r.rides.get('r2')).isSettled, isTrue);

        expect(
          err(await r.rides.update(ride('r1', price: 1))),
          const Locked('ride', 'r1'),
        );
        expect(
          err(await r.rides.softDelete('r2')),
          const Locked('ride', 'r2'),
        );
        expect(ok(await r.rides.get('r1')).ride.pricePerUnitMilli, 1800);
      });

      test(
        'markSettled changes nothing when one ride is not eligible',
        () async {
          await log(ride('r1'));
          await log(ride('r2'));
          await log(ride('gone'));
          ok(await r.rides.softDelete('gone'));
          final x = await expenseId();
          final y = await expenseId();
          ok(await r.rides.markSettled(['r2'], y));

          expect(
            err(await r.rides.markSettled(['r1', 'r2'], x)),
            const Locked('ride', 'r2'),
          );
          expect(
            err(await r.rides.markSettled(['r1', 'gone'], x)),
            const NotFound('ride', 'gone'),
          );
          expect(
            err(await r.rides.markSettled(['r1', 'nope'], x)),
            const NotFound('ride', 'nope'),
          );
          expect(
            err(await r.rides.markSettled(['r1'], 'no-expense')),
            const NotFound('expense', 'no-expense'),
          );
          expect(ok(await r.rides.get('r1')).settledExpenseId, isNull);
        },
      );
    });
  });
}
