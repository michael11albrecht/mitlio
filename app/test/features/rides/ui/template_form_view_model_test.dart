import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/template_form_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

void main() {
  late RidesApp app;
  late ProviderContainer container;

  TemplateFormKey key([String? templateId]) =>
      (groupId: app.group.id, templateId: templateId);
  TemplateFormViewModel vm([String? templateId]) =>
      container.read(templateFormViewModelProvider(key(templateId)).notifier);
  TemplateFormState state([String? templateId]) =>
      container.read(templateFormViewModelProvider(key(templateId)));
  TemplateFormReady form([String? templateId]) =>
      state(templateId) as TemplateFormReady;

  Future<void> open([String? templateId]) async {
    container.listen(templateFormViewModelProvider(key(templateId)), (_, _) {});
    await pumpEventQueue();
  }

  String id(int i) => app.people[i].id;

  setUp(() {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  group('new template', () {
    test('loading, then a form with the smart defaults', () async {
      await app.seedVehicle();
      container.listen(templateFormViewModelProvider(key()), (_, _) {});
      expect(state(), isA<TemplateFormLoading>());
      await pumpEventQueue();
      final f = form();
      expect(f.editing, isFalse);
      expect(f.members.map((m) => m.name), ['Ann', 'Ben', 'Cy']);
      // The only car is pre-selected, round trip is the commuter default.
      expect(f.vehicleId, app.golf.id);
      expect(f.roundTrip, isTrue);
      expect(f.defaultDriverId, isNull);
      expect(f.hasIssues, isTrue);
    });

    test('without a car the form cannot be saved', () async {
      await app.seedGroup();
      await open();
      expect(form().vehicles, isEmpty);
      expect(form().vehicleMissing, isTrue);
      vm()
        ..setName('Arbeit')
        ..setDistance(20000);
      expect(err(await vm().save()), isA<InvalidData>());
    });

    test('saving with problems explains them instead of storing', () async {
      await app.seedVehicle();
      await open();
      expect(err(await vm().save()), isA<InvalidData>());
      expect(form().showErrors, isTrue);
      expect(form().nameMissing, isTrue);
      expect(form().distanceMissing, isTrue);
      vm()
        ..setName('Arbeit')
        ..setDistance(0);
      expect(form().distanceMissing, isTrue);
    });

    test('save stores the template', () async {
      await app.seedVehicle();
      await open();
      vm()
        ..setName(' Arbeit ')
        ..setDistance(12500)
        ..setRoundTrip(on: false)
        ..setDefaultDriver(id(0))
        ..togglePassenger(id(1))
        ..togglePassenger(id(2))
        ..togglePassenger(id(2))
        ..setTolls(250);
      final t = ok(await vm().save());
      expect(t.name, 'Arbeit');
      expect(t.distanceMeters, 12500);
      expect(t.roundTrip, isFalse);
      expect(t.vehicleId, app.golf.id);
      expect(t.defaultDriverId, id(0));
      expect(t.defaultPassengerIds, {id(1)});
      expect(t.tollsCents, 250);
      expect(form().saving, isFalse);
    });

    test('the driver is never also a passenger', () async {
      await app.seedVehicle();
      await open();
      vm()
        ..togglePassenger(id(0))
        ..togglePassenger(id(1));
      expect(form().defaultPassengerIds, {id(0), id(1)});
      vm().setDefaultDriver(id(0));
      expect(form().defaultPassengerIds, {id(1)});
      vm().togglePassenger(id(0));
      expect(form().defaultPassengerIds, {id(1)});
      vm().setDefaultDriver(null);
      expect(form().defaultDriverId, isNull);
    });

    test('picking another car', () async {
      await app.seedVehicle();
      final polo = ok(
        await app.vehicles.add(
          app.group.id,
          name: 'Polo',
          fuelType: FuelType.petrol,
          consumptionMilliPer100km: 6000,
        ),
      );
      await open();
      vm().setVehicle(polo.id);
      expect(form().vehicleId, polo.id);
    });

    test('repository failure is returned and the form stays', () async {
      await app.seedVehicle();
      await open();
      vm()
        ..setName('Arbeit')
        ..setDistance(1000);
      app.templates.failWith = const Storage('disk');
      expect(err(await vm().save()), const Storage('disk'));
      expect(form().saving, isFalse);
      expect(form().name, 'Arbeit');
    });
  });

  group('edit template', () {
    test('adopts the stored values and replaces them on save', () async {
      await app.seedCommute();
      await open(app.work.id);
      final f = form(app.work.id);
      expect(f.editing, isTrue);
      expect(f.name, 'Arbeit');
      expect(f.distanceMeters, 20000);
      expect(f.defaultDriverId, id(0));
      expect(f.defaultPassengerIds, {id(1)});
      expect(f.tollsCents, isNull);
      vm(app.work.id)
        ..setName('Büro')
        ..setTolls(300);
      final t = ok(await vm(app.work.id).save());
      expect(t.id, app.work.id);
      expect(t.name, 'Büro');
      expect(t.tollsCents, 300);
    });

    test('an unknown template fails with NotFound', () async {
      await app.seedVehicle();
      await open('nope');
      expect((state('nope') as TemplateFormFailure).error, isA<NotFound>());
    });
  });

  group('loading failures', () {
    test('an unknown group fails with NotFound, retry reloads', () async {
      await app.seedVehicle();
      const unknown = (groupId: 'nope', templateId: null);
      container.listen(templateFormViewModelProvider(unknown), (_, _) {});
      await pumpEventQueue();
      expect(
        (container.read(
          templateFormViewModelProvider(unknown),
        ) as TemplateFormFailure).error,
        isA<NotFound>(),
      );
      final notifier = container.read(
        templateFormViewModelProvider(unknown).notifier,
      )..retry();
      expect(
        container.read(templateFormViewModelProvider(unknown)),
        isA<TemplateFormLoading>(),
      );
      await pumpEventQueue();
      expect(notifier.debugSnapshot()['status'], 'error');
    });

    test('saving before the form loaded is refused', () async {
      await app.seedVehicle();
      container.listen(templateFormViewModelProvider(key()), (_, _) {});
      expect(err(await vm().save()), isA<InvalidData>());
    });
  });

  test('debugSnapshot', () async {
    await app.seedVehicle();
    container.listen(templateFormViewModelProvider(key()), (_, _) {});
    expect(vm().debugSnapshot()['status'], 'loading');
    await pumpEventQueue();
    vm()
      ..setName('Arbeit')
      ..setDistance(20000);
    expect(vm().debugSnapshot(), {
      'status': 'ready',
      'editing': false,
      'name': 'Arbeit',
      'distanceMeters': 20000,
      'roundTrip': true,
      'vehicleId': app.golf.id,
      'defaultDriverId': null,
      'defaultPassengerIds': <String>[],
      'tollsCents': null,
      'valid': true,
    });
  });
}
