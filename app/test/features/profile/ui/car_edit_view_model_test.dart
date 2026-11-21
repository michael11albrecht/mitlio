import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/fake_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/ui/car_edit_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer c;
  late String gA;
  late String gB;
  late Vehicle golf;

  setUp(() async {
    app = FakeApp();
    c = app.container();
    addTearDown(c.dispose);
    gA = ok(
      await app.groups.create(name: 'A', currency: eur, createdBy: 'dev'),
    ).id;
    gB = ok(
      await app.groups.create(name: 'B', currency: eur, createdBy: 'dev'),
    ).id;
    golf = ok(
      await app.userVehicles.add(
        name: 'Golf',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: 6500,
        wearMilliPerKm: 80,
      ),
    );
  });

  Future<void> settle() => pumpEventQueue();

  group('CarEditViewModel', () {
    CarEditViewModel vm() => c.read(carEditViewModelProvider(golf.id).notifier);

    Future<CarEditReady> open() async {
      c.listen(carEditViewModelProvider(golf.id), (_, _) {});
      await settle();
      return c.read(carEditViewModelProvider(golf.id)) as CarEditReady;
    }

    test('loads the stored values', () async {
      final form = await open();
      expect(
        [form.name, form.fuelType, form.consumptionMilli, form.wearMilli],
        ['Golf', FuelType.petrol, 6500, 80],
      );
    });

    test('an unknown car is a failure that retry can leave', () async {
      c.listen(carEditViewModelProvider('nope'), (_, _) {});
      await settle();
      expect(
        c.read(carEditViewModelProvider('nope')),
        isA<CarEditFailure>().having(
          (f) => f.error,
          'error',
          isA<NotFound>(),
        ),
      );
    });

    test('save updates the car and every group, undo restores', () async {
      final copyA = ok(
        await c
            .read(personalCarLinksRepositoryProvider)
            .useInGroup(gA, golf.id),
      );
      ok(
        await c
            .read(personalCarLinksRepositoryProvider)
            .useInGroup(gB, golf.id),
      );
      await open();
      vm()
        ..setName(' Golf GTI ')
        ..setConsumption(7200)
        ..setWear(120);
      final done = ok(await vm().save());
      expect(done.groups, 2);
      expect(ok(await app.userVehicles.get(golf.id)).name, 'Golf GTI');
      expect(
        ok(await app.vehicles.get(copyA.id)).consumptionMilliPer100km,
        7200,
      );
      ok(await done.undo());
      expect(ok(await app.userVehicles.get(golf.id)), golf);
      expect(ok(await app.vehicles.get(copyA.id)).name, 'Golf');
    });

    test('a car used nowhere saves with zero groups', () async {
      await open();
      vm().setName('Polo');
      expect(ok(await vm().save()).groups, 0);
    });

    test('missing name or consumption is InvalidData and shown', () async {
      await open();
      vm()
        ..setName('  ')
        ..setConsumption(null);
      expect(err(await vm().save()), isA<InvalidData>());
      final form = c.read(carEditViewModelProvider(golf.id)) as CarEditReady;
      expect(
        [form.showErrors, form.nameMissing, form.consumptionMissing],
        [
          true,
          true,
          true,
        ],
      );
      expect(ok(await app.userVehicles.get(golf.id)), golf);
    });

    test('a failing repository is returned, nothing changes', () async {
      final flaky = _FailingUpdate(ids: SequentialIdGenerator());
      final car = ok(
        await flaky.add(
          name: 'Golf',
          fuelType: FuelType.petrol,
          consumptionMilliPer100km: 6500,
        ),
      );
      app.userVehicles = flaky;
      final failing = app.container();
      addTearDown(failing.dispose);
      failing.listen(carEditViewModelProvider(car.id), (_, _) {});
      await settle();
      final n = failing.read(carEditViewModelProvider(car.id).notifier)
        ..setName('Golf GTI');
      expect(err(await n.save()), const Storage('disk full'));
      expect(ok(await flaky.get(car.id)), car);
      final form =
          failing.read(carEditViewModelProvider(car.id)) as CarEditReady;
      expect(form.saving, isFalse);
    });
  });
}

/// Personal vehicles whose `update` fails.
class _FailingUpdate extends FakeUserVehiclesRepository {
  _FailingUpdate({required super.ids});

  @override
  Future<RepoResult<Vehicle>> update(Vehicle vehicle) async =>
      const Err(Storage('disk full'));
}
