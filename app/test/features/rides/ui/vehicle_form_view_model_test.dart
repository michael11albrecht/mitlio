import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

void main() {
  late RidesApp app;
  late ProviderContainer container;

  VehicleFormKey key([String? vehicleId]) =>
      (groupId: app.group.id, vehicleId: vehicleId);
  VehicleFormViewModel vm([String? vehicleId]) =>
      container.read(vehicleFormViewModelProvider(key(vehicleId)).notifier);
  VehicleFormState state([String? vehicleId]) =>
      container.read(vehicleFormViewModelProvider(key(vehicleId)));
  VehicleFormReady form([String? vehicleId]) =>
      state(vehicleId) as VehicleFormReady;

  Future<void> open([String? vehicleId]) async {
    container.listen(vehicleFormViewModelProvider(key(vehicleId)), (_, _) {});
    await pumpEventQueue();
  }

  setUp(() async {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedVehicle();
  });

  group('new vehicle', () {
    test('loading, then an empty form in the group currency', () async {
      container.listen(vehicleFormViewModelProvider(key()), (_, _) {});
      expect(state(), isA<VehicleFormLoading>());
      await pumpEventQueue();
      final f = form();
      expect(f.editing, isFalse);
      expect(f.currency, Currency.eur);
      expect(f.name, '');
      expect(f.fuelType, FuelType.petrol);
      expect(f.consumptionMilli, isNull);
      expect(f.hasIssues, isTrue);
    });

    test('saving with problems explains them instead of storing', () async {
      await open();
      expect(err(await vm().save()), isA<InvalidData>());
      expect(form().showErrors, isTrue);
      expect(form().nameMissing, isTrue);
      expect(form().consumptionMissing, isTrue);
      vm()
        ..setName('Polo')
        ..setConsumption(0);
      expect(form().consumptionMissing, isTrue);
      expect(err(await vm().save()), isA<InvalidData>());
    });

    test('save stores the vehicle', () async {
      await open();
      vm()
        ..setName('  Polo ')
        ..setFuelType(FuelType.diesel)
        ..setConsumption(5200)
        ..setWear(80)
        ..setKmRate(300);
      final v = ok(await vm().save());
      expect(v.name, 'Polo');
      expect(v.fuelType, FuelType.diesel);
      expect(v.consumptionMilliPer100km, 5200);
      expect(v.wearMilliPerKm, 80);
      expect(v.kmRateMilliPerKm, 300);
      expect(form().saving, isFalse);
      final stored = await app.vehicles.watchVehicles(app.group.id).first;
      expect(stored.map((x) => x.name), ['Golf', 'Polo']);
    });

    test('wear and km rate are optional', () async {
      await open();
      vm()
        ..setName('Zoe')
        ..setFuelType(FuelType.electric)
        ..setConsumption(16000);
      final v = ok(await vm().save());
      expect(v.wearMilliPerKm, 0);
      expect(v.kmRateMilliPerKm, isNull);
    });

    test('repository failure is returned and the form stays', () async {
      await open();
      vm()
        ..setName('Polo')
        ..setConsumption(6000);
      app.vehicles.failWith = const Storage('disk');
      expect(err(await vm().save()), const Storage('disk'));
      expect(form().saving, isFalse);
      expect(form().name, 'Polo');
    });
  });

  group('edit vehicle', () {
    test('adopts the stored values and replaces them on save', () async {
      await open(app.golf.id);
      final f = form(app.golf.id);
      expect(f.editing, isTrue);
      expect(f.name, 'Golf');
      expect(f.consumptionMilli, 6500);
      expect(f.wearMilli, isNull);
      vm(app.golf.id)
        ..setName('Golf 8')
        ..setKmRate(280);
      final v = ok(await vm(app.golf.id).save());
      expect(v.id, app.golf.id);
      expect(v.name, 'Golf 8');
      expect(v.kmRateMilliPerKm, 280);
    });

    test('an unknown vehicle fails with NotFound', () async {
      await open('nope');
      expect(
        (state('nope') as VehicleFormFailure).error,
        isA<NotFound>(),
      );
    });
  });

  group('loading failures', () {
    test('an unknown group fails with NotFound', () async {
      const unknown = (groupId: 'nope', vehicleId: null);
      container.listen(vehicleFormViewModelProvider(unknown), (_, _) {});
      await pumpEventQueue();
      expect(
        (container.read(
          vehicleFormViewModelProvider(unknown),
        ) as VehicleFormFailure).error,
        isA<NotFound>(),
      );
    });

    test('retry reloads', () async {
      const unknown = (groupId: 'nope', vehicleId: null);
      container.listen(vehicleFormViewModelProvider(unknown), (_, _) {});
      await pumpEventQueue();
      final notifier = container.read(
        vehicleFormViewModelProvider(unknown).notifier,
      )..retry();
      expect(
        container.read(vehicleFormViewModelProvider(unknown)),
        isA<VehicleFormLoading>(),
      );
      await pumpEventQueue();
      expect(notifier.debugSnapshot()['status'], 'error');
    });

    test('saving before the form loaded is refused', () async {
      container.listen(vehicleFormViewModelProvider(key()), (_, _) {});
      expect(err(await vm().save()), isA<InvalidData>());
    });
  });

  test('debugSnapshot', () async {
    container.listen(vehicleFormViewModelProvider(key()), (_, _) {});
    expect(vm().debugSnapshot()['status'], 'loading');
    await pumpEventQueue();
    vm().setName('Polo');
    expect(vm().debugSnapshot(), {
      'status': 'ready',
      'editing': false,
      'name': 'Polo',
      'fuelType': 'petrol',
      'consumptionMilliPer100km': null,
      'wearMilliPerKm': null,
      'kmRateMilliPerKm': null,
      'valid': false,
    });
  });
}
