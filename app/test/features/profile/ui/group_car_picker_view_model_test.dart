import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/fake_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/ui/group_car_picker_view_model.dart';
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

  group('GroupCarPickerViewModel', () {
    GroupCarPickerViewModel vm() =>
        c.read(groupCarPickerViewModelProvider(gA).notifier);

    List<String> names() => [
      for (final v in c.read(groupCarPickerViewModelProvider(gA)).requireValue)
        v.name,
    ];

    test('offers the personal cars without a copy here', () async {
      c.listen(groupCarPickerViewModelProvider(gA), (_, _) {});
      expect(c.read(groupCarPickerViewModelProvider(gA)).isLoading, isTrue);
      await settle();
      expect(names(), ['Golf']);
    });

    test('use creates the linked copy and the car leaves the list', () async {
      c.listen(groupCarPickerViewModelProvider(gA), (_, _) {});
      await settle();
      final copy = ok(await vm().use(golf.id));
      await settle();
      expect(names(), isEmpty);
      expect(ok(await app.vehicles.sourceOf(copy.id)), golf.id);
      // Another group still has it on offer.
      c.listen(groupCarPickerViewModelProvider(gB), (_, _) {});
      await settle();
      expect(c.read(groupCarPickerViewModelProvider(gB)).requireValue, [golf]);
    });

    test('a new personal car shows up', () async {
      c.listen(groupCarPickerViewModelProvider(gA), (_, _) {});
      await settle();
      ok(
        await app.userVehicles.add(
          name: 'Zoe',
          fuelType: FuelType.electric,
          consumptionMilliPer100km: 16000,
        ),
      );
      await settle();
      expect(names(), ['Golf', 'Zoe']);
    });

    test('use of an unknown car is NotFound', () async {
      expect(err(await vm().use('nope')), isA<NotFound>());
    });

    test('a failing stream is an error that retry can leave', () async {
      app.userVehicles = _BrokenWatch(ids: SequentialIdGenerator());
      final failing = app.container();
      addTearDown(failing.dispose);
      failing.listen(groupCarPickerViewModelProvider(gA), (_, _) {});
      await settle();
      expect(
        failing.read(groupCarPickerViewModelProvider(gA)).error,
        isA<Storage>(),
      );
    });
  });
}

/// Personal vehicles whose stream fails.
class _BrokenWatch extends FakeUserVehiclesRepository {
  _BrokenWatch({required super.ids});

  @override
  Stream<List<Vehicle>> watchVehicles() => Stream.error(const Storage('x'));
}
