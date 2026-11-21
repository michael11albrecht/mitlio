import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/rides/ui/vehicle_link_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer c;
  late String gA;
  late Vehicle golf;

  setUp(() async {
    app = FakeApp();
    c = app.container();
    addTearDown(c.dispose);
    gA = ok(
      await app.groups.create(name: 'A', currency: eur, createdBy: 'dev'),
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

  group('VehicleLinkViewModel', () {
    test('a plain vehicle is not linked, a copy is', () async {
      final plain = ok(
        await app.vehicles.add(
          gA,
          name: 'Bus',
          fuelType: FuelType.diesel,
          consumptionMilliPer100km: 9000,
        ),
      );
      final copy = ok(
        await c
            .read(personalCarLinksRepositoryProvider)
            .useInGroup(gA, golf.id),
      );
      c
        ..listen(vehicleLinkViewModelProvider(plain.id), (_, _) {})
        ..listen(vehicleLinkViewModelProvider(copy.id), (_, _) {});
      await settle();
      expect(c.read(vehicleLinkViewModelProvider(plain.id)).value, isFalse);
      expect(c.read(vehicleLinkViewModelProvider(copy.id)).value, isTrue);
    });

    test('unlink keeps the values and ends the link', () async {
      final copy = ok(
        await c
            .read(personalCarLinksRepositoryProvider)
            .useInGroup(gA, golf.id),
      );
      c.listen(vehicleLinkViewModelProvider(copy.id), (_, _) {});
      await settle();
      ok(await c.read(vehicleLinkViewModelProvider(copy.id).notifier).unlink());
      expect(c.read(vehicleLinkViewModelProvider(copy.id)).value, isFalse);
      expect(ok(await app.vehicles.sourceOf(copy.id)), isNull);
      expect(ok(await app.vehicles.get(copy.id)).name, 'Golf');
    });

    test('an unknown vehicle is an error, unlink reports it', () async {
      c.listen(vehicleLinkViewModelProvider('nope'), (_, _) {});
      await settle();
      expect(c.read(vehicleLinkViewModelProvider('nope')).hasError, isTrue);
      expect(
        err(
          await c.read(vehicleLinkViewModelProvider('nope').notifier).unlink(),
        ),
        isA<NotFound>(),
      );
    });
  });
}
