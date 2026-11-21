import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/profile/data/repositories/drift_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/repositories/fake_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/repositories/personal_car_links_repository.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

/// A group vehicles fake whose `update` fails for one vehicle.
class _FailingUpdate extends FakeVehiclesRepository {
  _FailingUpdate({required super.groups, required super.ids});

  String? failFor;

  @override
  Future<RepoResult<Vehicle>> update(Vehicle vehicle) async =>
      vehicle.id == failFor
      ? const Err(Storage('disk full'))
      : super.update(vehicle);
}

void main() {
  for (final variant in ['drift', 'fake']) {
    group('PersonalCarLinksRepository ($variant)', () {
      late Repos r;
      late UserVehiclesRepository personal;
      late PersonalCarLinksRepository links;
      late VehiclesRepository groupVehicles;
      late String gA;
      late String gB;
      late Vehicle golf;

      setUp(() async {
        r = variant == 'drift' ? await driftRepos() : await fakeRepos();
        personal = variant == 'drift'
            ? DriftUserVehiclesRepository(
                db: r.db!,
                clock: r.clock,
                ids: SequentialIdGenerator(),
              )
            : FakeUserVehiclesRepository(ids: SequentialIdGenerator());
        groupVehicles = r.vehicles;
        links = PersonalCarLinksRepository(
          personal: personal,
          groupVehicles: groupVehicles,
        );
        gA = (await seedGroup(r)).groupId;
        gB = (await seedGroup(r)).groupId;
        golf = ok(
          await personal.add(
            name: 'Golf',
            fuelType: FuelType.petrol,
            consumptionMilliPer100km: 6500,
            wearMilliPerKm: 80,
          ),
        );
      });

      test('useInGroup creates a linked copy once per group', () async {
        final copy = ok(await links.useInGroup(gA, golf.id));
        expect(
          [copy.name, copy.consumptionMilliPer100km, copy.wearMilliPerKm],
          ['Golf', 6500, 80],
        );
        expect(ok(await groupVehicles.sourceOf(copy.id)), golf.id);
        expect(ok(await links.useInGroup(gA, golf.id)).id, copy.id);
        final other = ok(await links.useInGroup(gB, golf.id));
        expect(other.id, isNot(copy.id));
        expect(ok(await groupVehicles.linkedCopies(golf.id)), hasLength(2));
      });

      test('useInGroup of an unknown car or group is NotFound', () async {
        expect(err(await links.useInGroup(gA, 'nope')), isA<NotFound>());
        expect(err(await links.useInGroup('nope', golf.id)), isA<NotFound>());
      });

      Vehicle edited() => Vehicle(
        id: golf.id,
        name: 'Golf GTI',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: 7200,
        wearMilliPerKm: 120,
      );

      test(
        'editing the personal car updates both groups, undo restores',
        () async {
          final a = ok(await links.useInGroup(gA, golf.id));
          final b = ok(await links.useInGroup(gB, golf.id));
          final done = ok(await links.update(edited()));
          expect(done.groups, 2);
          expect(done.car.name, 'Golf GTI');
          for (final id in [a.id, b.id]) {
            final v = ok(await groupVehicles.get(id));
            expect(
              [v.name, v.consumptionMilliPer100km, v.wearMilliPerKm],
              [
                'Golf GTI',
                7200,
                120,
              ],
            );
          }
          ok(await done.undo());
          expect(ok(await personal.get(golf.id)), golf);
          for (final id in [a.id, b.id]) {
            final v = ok(await groupVehicles.get(id));
            expect(
              [v.name, v.consumptionMilliPer100km, v.wearMilliPerKm],
              [
                'Golf',
                6500,
                80,
              ],
            );
          }
        },
      );

      test(
        'an unlinked copy and an unrelated vehicle stay as they are',
        () async {
          final a = ok(await links.useInGroup(gA, golf.id));
          final b = ok(await links.useInGroup(gB, golf.id));
          final plain = ok(
            await groupVehicles.add(
              gA,
              name: 'Bus',
              fuelType: FuelType.diesel,
              consumptionMilliPer100km: 9000,
            ),
          );
          ok(await groupVehicles.unlink(b.id));
          final done = ok(await links.update(edited()));
          expect(done.groups, 1);
          expect(ok(await groupVehicles.get(a.id)).name, 'Golf GTI');
          expect(ok(await groupVehicles.get(b.id)).name, 'Golf');
          expect(ok(await groupVehicles.get(plain.id)), plain);
        },
      );

      test('a car used nowhere updates alone, with zero groups', () async {
        final done = ok(await links.update(edited()));
        expect(done.groups, 0);
        expect(ok(await personal.get(golf.id)).name, 'Golf GTI');
      });

      test('an unknown car changes nothing', () async {
        ok(await links.useInGroup(gA, golf.id));
        expect(
          err(await links.update(edited().copyWithId('nope'))),
          isA<NotFound>(),
        );
      });

      test('closed periods keep their expenses', () async {
        final seeded = await seedGroup(r);
        final copy = ok(await links.useInGroup(seeded.groupId, golf.id));
        final m = seeded.members;
        ok(
          await r.rides.log(
            seeded.groupId,
            Ride(
              id: 'r1',
              date: DateTime.utc(2026, 3, 2),
              distanceMeters: 12000,
              roundTrip: true,
              vehicleId: copy.id,
              driverId: m[0].id,
              passengerIds: {m[1].id, m[2].id},
              driverCounts: false,
              pricePerUnitMilli: 1800,
            ),
          ),
        );
        final made = ok(
          await r.rides.settlePeriod(seeded.groupId, [
            PeriodSettlement(
              rideIds: const ['r1'],
              draft: ExpenseDraft(
                title: 'Maerz',
                amountCents: 600,
                currency: eur,
                date: DateTime.utc(2026, 3, 31),
                payers: {m[0].id: 600},
                split: ExactSplit({m[0].id: 200, m[1].id: 200, m[2].id: 200}),
              ),
            ),
          ]),
        );
        ok(await links.update(edited()));
        final after = await StreamProbe(
          r.expenses.watchExpenses(seeded.groupId),
        ).next();
        expect(after, made);
        expect(after.single.expense.amountCents, 600);
      });

      // The failure is injected into the in-memory vehicles only.
      if (variant == 'fake') {
        test(
          'a failing copy rolls everything back and reports the error',
          () async {
            final groups = r.groups;
            final failing = _FailingUpdate(
              groups: groups,
              ids: SequentialIdGenerator(),
            );
            final l = PersonalCarLinksRepository(
              personal: personal,
              groupVehicles: failing,
            );
            final a = ok(await l.useInGroup(gA, golf.id));
            final b = ok(await l.useInGroup(gB, golf.id));
            failing.failFor = b.id;
            expect(err(await l.update(edited())), const Storage('disk full'));
            failing.failFor = null;
            expect(ok(await personal.get(golf.id)), golf);
            expect(ok(await failing.get(a.id)).name, 'Golf');
            expect(ok(await failing.get(b.id)).name, 'Golf');
          },
        );
      }
    });
  }
}

extension on Vehicle {
  Vehicle copyWithId(String id) => Vehicle(
    id: id,
    name: name,
    fuelType: fuelType,
    consumptionMilliPer100km: consumptionMilliPer100km,
  );
}
