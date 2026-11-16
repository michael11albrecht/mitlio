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
      'fromCatalog': null,
      'realisticApplied': false,
      'catalogUnavailable': false,
      'noMatch': false,
      'suggestions': <Object?>[],
    });
  });

  group('car catalog', () {
    final golfPetrol = sampleCatalogEntries[0];
    final tesla = sampleCatalogEntries[3];

    Future<void> type(String text) async {
      vm().setName(text);
      await pumpEventQueue();
    }

    test('typing finds cars, fewer than two letters clears them', () async {
      await open();
      await type('G');
      expect(form().suggestions, isEmpty);
      expect(form().noMatch, isFalse);
      await type('Golf');
      expect(form().suggestions.map((e) => e.name), ['VW Golf', 'VW Golf']);
      expect(form().noMatch, isFalse);
      await type(' g ');
      expect(form().suggestions, isEmpty);
    });

    test('no match says so and the form keeps working', () async {
      await open();
      await type('Trabant');
      expect(form().suggestions, isEmpty);
      expect(form().noMatch, isTrue);
      expect(form().catalogUnavailable, isFalse);
      vm()
        ..setConsumption(7000)
        ..setName('Trabant');
      expect(ok(await vm().save()).name, 'Trabant');
    });

    test('picking fills name, fuel and consumption (WLTP)', () async {
      await open();
      await type('golf');
      final undo = vm().applyCatalogEntry(golfPetrol);
      expect(undo, isNull); // Nothing the user typed was replaced.
      expect(form().name, 'VW Golf');
      expect(form().fuelType, FuelType.petrol);
      expect(form().consumptionMilli, 5600);
      expect(form().fromCatalog, golfPetrol);
      expect(form().realisticApplied, isFalse);
      expect(form().suggestions, isEmpty);
      expect(form().noMatch, isFalse);
      expect(form().hasIssues, isFalse);
      expect(form().nameRevision, 1);
      // Cost-per-km fields are never prefilled from the catalog.
      expect(form().wearMilli, isNull);
      expect(form().kmRateMilli, isNull);
      final saved = ok(await vm().save());
      expect(saved.name, 'VW Golf');
      expect(saved.consumptionMilliPer100km, 5600);
      expect(saved.wearMilliPerKm, 0);
      expect(saved.kmRateMilliPerKm, isNull);
    });

    test('an electric pick shows kWh and offers no realistic value', () async {
      await open();
      vm().applyCatalogEntry(tesla);
      expect(form().fuelType, FuelType.electric);
      expect(form().consumptionMilli, 14900);
      expect(form().realisticMilli, isNull);
      vm().useRealisticConsumption();
      expect(form().consumptionMilli, 14900);
      expect(form().realisticApplied, isFalse);
    });

    test('the realistic value is one tap, marked as an estimate', () async {
      await open();
      vm().applyCatalogEntry(golfPetrol);
      expect(form().realisticMilli, 6720);
      vm().useRealisticConsumption();
      expect(form().consumptionMilli, 6720);
      expect(form().realisticApplied, isTrue);
      expect(form().fromCatalog, golfPetrol);
      expect(ok(await vm().save()).consumptionMilliPer100km, 6720);
    });

    test('realistic without a picked car does nothing', () async {
      await open();
      vm()
        ..setConsumption(6000)
        ..useRealisticConsumption();
      expect(form().consumptionMilli, 6000);
      expect(form().realisticApplied, isFalse);
    });

    test('editing consumption or fuel drops the catalog hint', () async {
      await open();
      vm().applyCatalogEntry(golfPetrol);
      vm().setConsumption(5601);
      expect(form().fromCatalog, isNull);
      expect(form().realisticApplied, isFalse);

      vm().applyCatalogEntry(golfPetrol);
      vm().useRealisticConsumption();
      vm().setFuelType(FuelType.diesel);
      expect(form().fromCatalog, isNull);
      expect(form().realisticApplied, isFalse);
    });

    test('setting the same value again keeps the hint', () async {
      await open();
      vm().applyCatalogEntry(golfPetrol);
      vm()
        ..setConsumption(5600)
        ..setFuelType(FuelType.petrol);
      expect(form().fromCatalog, golfPetrol);
    });

    test('editing the name keeps the hint but searches again', () async {
      await open();
      vm().applyCatalogEntry(golfPetrol);
      await type('VW Golf GTI');
      expect(form().fromCatalog, golfPetrol);
      expect(form().noMatch, isTrue);
    });

    test('a pick over typed consumption can be undone', () async {
      await open();
      vm()
        ..setName('go')
        ..setFuelType(FuelType.diesel)
        ..setConsumption(4800);
      await pumpEventQueue();
      final undo = vm().applyCatalogEntry(golfPetrol);
      expect(undo, isNotNull);
      expect(form().consumptionMilli, 5600);
      expect(form().fuelType, FuelType.petrol);
      expect(await undo!(), isA<Ok<void, RepositoryError>>());
      expect(form().name, 'go');
      expect(form().fuelType, FuelType.diesel);
      expect(form().consumptionMilli, 4800);
      expect(form().fromCatalog, isNull);
      expect(form().nameRevision, 2);
    });

    test('picking the value already typed needs no undo', () async {
      await open();
      vm().setConsumption(5600);
      expect(vm().applyCatalogEntry(golfPetrol), isNull);
    });

    test(
      'undo after the form is gone does nothing and does not throw',
      () async {
        await open();
        vm().setConsumption(4800);
        final undo = vm().applyCatalogEntry(golfPetrol)!;
        container.dispose();
        expect(await undo(), isA<Ok<void, RepositoryError>>());
      },
    );

    test('a pick before the form loaded is ignored', () async {
      container.listen(vehicleFormViewModelProvider(key()), (_, _) {});
      expect(vm().applyCatalogEntry(golfPetrol), isNull);
      await pumpEventQueue();
      expect(form().name, '');
      expect(form().fromCatalog, isNull);
    });

    test('a pick drops a lookup that is still running', () async {
      await open();
      vm().setName('golf');
      vm().applyCatalogEntry(golfPetrol);
      await pumpEventQueue();
      expect(form().suggestions, isEmpty);
      expect(form().name, 'VW Golf');
    });

    test('a newer search wins over an older one', () async {
      await open();
      vm()
        ..setName('golf')
        ..setName('polo');
      await pumpEventQueue();
      expect(form().suggestions.map((e) => e.name), ['VW Polo']);
    });

    test('a catalog that cannot load is shown, then tried again', () async {
      app.catalog.failure = const Storage('asset missing');
      await open();
      await type('golf');
      expect(form().catalogUnavailable, isTrue);
      expect(form().suggestions, isEmpty);
      expect(form().noMatch, isFalse);
      // The manual path is unchanged.
      vm()
        ..setFuelType(FuelType.diesel)
        ..setConsumption(5200);
      expect(ok(await vm().save()).name, 'golf');

      app.catalog.failure = null;
      await type('golf');
      expect(form().catalogUnavailable, isFalse);
      expect(form().suggestions, isNotEmpty);
    });

    test('editing a stored vehicle can use the catalog too', () async {
      await open(app.golf.id);
      await type('tesla');
      expect(form().suggestions.single.name, 'Tesla Model 3');
      final undo = vm(app.golf.id).applyCatalogEntry(tesla);
      expect(undo, isNotNull); // The stored 6,5 l was replaced.
      expect(form(app.golf.id).fuelType, FuelType.electric);
    });

    test('a failure to load the form leaves the catalog idle', () async {
      container.listen(
        vehicleFormViewModelProvider((groupId: 'nope', vehicleId: null)),
        (_, _) {},
      );
      await pumpEventQueue();
      expect(app.catalog.loads, 0);
    });

    test('debugSnapshot lists suggestions and the picked car', () async {
      await open();
      await type('model 3');
      var snap = vm().debugSnapshot();
      expect(snap['suggestions'], [
        {
          'name': 'Tesla Model 3',
          'fuelType': 'electric',
          'hybrid': false,
          'engineCc': 0,
          'powerKw': 190,
          'consumptionMilliPer100km': 14900,
        },
      ]);
      vm().applyCatalogEntry(tesla);
      snap = vm().debugSnapshot();
      expect(snap['fromCatalog'], 'Tesla Model 3');
      expect(snap['suggestions'], isEmpty);
    });
  });
}
