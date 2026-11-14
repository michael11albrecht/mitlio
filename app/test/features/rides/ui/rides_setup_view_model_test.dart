import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

void main() {
  late RidesApp app;
  late ProviderContainer container;

  RidesSetupViewModel vm() =>
      container.read(ridesSetupViewModelProvider(app.group.id).notifier);
  RidesSetupState state() =>
      container.read(ridesSetupViewModelProvider(app.group.id));
  RidesSetupLoaded loaded() => state() as RidesSetupLoaded;

  Future<void> open() async {
    container.listen(ridesSetupViewModelProvider(app.group.id), (_, _) {});
    await pumpEventQueue();
  }

  setUp(() {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  group('state', () {
    test('loading, then loaded with lookups', () async {
      await app.seedCommute();
      container.listen(ridesSetupViewModelProvider(app.group.id), (_, _) {});
      expect(state(), isA<RidesSetupLoading>());
      await pumpEventQueue();
      final s = loaded();
      expect(s.vehicles.single.name, 'Golf');
      expect(s.templates.single.name, 'Arbeit');
      expect(s.vehicle(app.golf.id)?.name, 'Golf');
      expect(s.vehicle('x'), isNull);
      expect(s.member(app.people[0].id)?.name, 'Ann');
      expect(s.member('x'), isNull);
      expect(s.templatesOf(app.golf.id), hasLength(1));
      expect(s.templatesOf('x'), isEmpty);
    });

    test('an unknown group fails with NotFound', () async {
      await app.seedCommute();
      container.listen(ridesSetupViewModelProvider('nope'), (_, _) {});
      await pumpEventQueue();
      expect(
        (container.read(
          ridesSetupViewModelProvider('nope'),
        ) as RidesSetupFailure).error,
        isA<NotFound>(),
      );
    });

    test('a failing stream fails the state, retry reloads', () async {
      await app.seedCommute();
      app.templates.watchError = const Storage('disk');
      await open();
      expect((state() as RidesSetupFailure).error, const Storage('disk'));
      app.templates.watchError = null;
      vm().retry();
      expect(state(), isA<RidesSetupLoading>());
      await pumpEventQueue();
      expect(state(), isA<RidesSetupLoaded>());
    });

    test('a plain error is wrapped in Storage', () async {
      await app.seedCommute();
      app.templates.watchError = StateError('x');
      await open();
      expect((state() as RidesSetupFailure).error, isA<Storage>());
    });
  });

  group('vehicles', () {
    test('add, update, delete with undo', () async {
      await app.seedGroup();
      await open();
      final v = ok(
        await vm().addVehicle(
          name: ' Polo ',
          fuelType: FuelType.diesel,
          consumptionMilliPer100km: 5500,
          wearMilliPerKm: 80,
          kmRateMilliPerKm: 300,
        ),
      );
      expect(v.name, 'Polo');
      expect(v.kmRateMilliPerKm, 300);
      await pumpEventQueue();
      expect(loaded().vehicles, hasLength(1));

      final renamed = ok(
        await vm().updateVehicle(
          Vehicle(
            id: v.id,
            name: 'Polo GTI',
            fuelType: FuelType.petrol,
            consumptionMilliPer100km: 7000,
          ),
        ),
      );
      expect(renamed.name, 'Polo GTI');

      final undo = ok(await vm().deleteVehicle(v.id));
      await pumpEventQueue();
      expect(loaded().vehicles, isEmpty);
      ok(await undo());
      await pumpEventQueue();
      expect(loaded().vehicles, hasLength(1));
    });

    test('validation and repository failures come back as errors', () async {
      await app.seedGroup();
      await open();
      expect(
        err(
          await vm().addVehicle(
            name: ' ',
            fuelType: FuelType.petrol,
            consumptionMilliPer100km: 6000,
          ),
        ),
        isA<InvalidData>(),
      );
      app.vehicles.failWith = const Storage('disk');
      expect(
        err(
          await vm().addVehicle(
            name: 'Golf',
            fuelType: FuelType.petrol,
            consumptionMilliPer100km: 6000,
          ),
        ),
        const Storage('disk'),
      );
    });

    test('a vehicle that a route uses cannot be deleted', () async {
      await app.seedCommute();
      await open();
      expect(err(await vm().deleteVehicle(app.golf.id)), isA<Conflict>());
      await pumpEventQueue();
      expect(loaded().vehicles, hasLength(1));
    });
  });

  group('templates', () {
    test('add, update, delete with undo', () async {
      await app.seedVehicle();
      await open();
      final t = ok(
        await vm().addTemplate(
          RideTemplate(
            id: '',
            name: 'Arbeit',
            distanceMeters: 12500,
            vehicleId: app.golf.id,
            roundTrip: true,
            defaultDriverId: app.people[0].id,
            defaultPassengerIds: {app.people[1].id},
            tollsCents: 150,
          ),
        ),
      );
      expect(t.tollsCents, 150);
      await pumpEventQueue();
      expect(loaded().templates, hasLength(1));

      final changed = ok(
        await vm().updateTemplate(
          RideTemplate(
            id: t.id,
            name: 'Büro',
            distanceMeters: 13000,
            vehicleId: app.golf.id,
          ),
        ),
      );
      expect(changed.name, 'Büro');

      final undo = ok(await vm().deleteTemplate(t.id));
      await pumpEventQueue();
      expect(loaded().templates, isEmpty);
      ok(await undo());
      await pumpEventQueue();
      expect(loaded().templates, hasLength(1));
    });

    test('a template needs a distance', () async {
      await app.seedVehicle();
      await open();
      final empty = RideTemplate(
        id: 'x',
        name: 'Null',
        distanceMeters: 0,
        vehicleId: app.golf.id,
      );
      expect(err(await vm().addTemplate(empty)), isA<InvalidData>());
      expect(err(await vm().updateTemplate(empty)), isA<InvalidData>());
    });

    test('repository failure comes back as an error', () async {
      await app.seedVehicle();
      await open();
      app.templates.failWith = const Storage('disk');
      expect(
        err(
          await vm().addTemplate(
            RideTemplate(
              id: '',
              name: 'A',
              distanceMeters: 1000,
              vehicleId: app.golf.id,
            ),
          ),
        ),
        const Storage('disk'),
      );
    });
  });

  group('debugSnapshot', () {
    test('loading, error, data', () async {
      await app.seedVehicle();
      app.templates.watchError = const Storage('disk');
      container.listen(ridesSetupViewModelProvider(app.group.id), (_, _) {});
      expect(vm().debugSnapshot()['status'], 'loading');
      await pumpEventQueue();
      expect(vm().debugSnapshot()['status'], 'error');
      app.templates.watchError = null;
      vm().retry();
      await pumpEventQueue();
      final snap = vm().debugSnapshot();
      expect(snap['status'], 'data');
      expect((snap['vehicles']! as List).single, containsPair('name', 'Golf'));
    });

    test('empty', () async {
      await app.seedGroup();
      await open();
      expect(vm().debugSnapshot()['status'], 'empty');
    });

    test('shapes', () async {
      await app.seedCommute();
      expect(templateJson(app.work), {
        'id': app.work.id,
        'name': 'Arbeit',
        'distanceMeters': 20000,
        'roundTrip': true,
        'vehicleId': app.golf.id,
        'defaultDriverId': app.people[0].id,
        'defaultPassengerIds': [app.people[1].id],
        'tollsCents': 0,
      });
      expect(vehicleJson(app.golf)['fuelType'], 'petrol');
    });
  });
}
