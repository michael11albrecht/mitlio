import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

const testIban = 'DE89370400440532013000';

/// The repositories of the personal profile slice on one store.
typedef ProfileRepos = ({
  ProfileRepository profile,
  ProfileBankRepository bank,
  UserVehiclesRepository vehicles,
});

/// Behaviour every profile, profile bank and user vehicles repository must
/// show; run against Drift and the in-memory fakes.
void runProfileRepositoriesContract(
  String name,
  Future<ProfileRepos> Function() create,
) {
  group('Profile repositories contract ($name)', () {
    late ProfileRepos r;

    setUp(() async => r = await create());

    group('profile', () {
      test('is empty until saved', () async {
        expect(ok(await r.profile.get()), isNull);
        expect(await r.profile.watchProfile().first, isNull);
      });

      test(
        'save trims, normalises the PayPal.Me handle and reads back',
        () async {
          final saved = ok(
            await r.profile.save(
              displayName: '  Ann ',
              avatarColor: 0xFF336699,
              avatarEmoji: ' 🚗 ',
              paypalMe: 'https://paypal.me/ann',
            ),
          );
          expect(saved.displayName, 'Ann');
          expect(saved.avatarColor, 0xFF336699);
          expect(saved.avatarEmoji, '🚗');
          expect(saved.paypalMe, 'ann');
          expect(ok(await r.profile.get()), saved);
        },
      );

      test('save replaces every field; blank values clear', () async {
        ok(await r.profile.save(displayName: 'Ann', paypalMe: 'ann'));
        final again = ok(
          await r.profile.save(displayName: 'Anna', avatarEmoji: ' '),
        );
        expect(again.displayName, 'Anna');
        expect(again.paypalMe, isNull);
        expect(again.avatarEmoji, isNull);
        expect(ok(await r.profile.get()), again);
      });

      test('save rejects bad input and names the field only', () async {
        final blank = err(await r.profile.save(displayName: '  '));
        expect(blank, isA<InvalidData>());
        expect((blank as InvalidData).details, contains('displayName'));
        final long = err(await r.profile.save(displayName: 'x' * 61));
        expect(long, isA<InvalidData>());
        final paypal = err(
          await r.profile.save(displayName: 'Ann', paypalMe: 'not a handle!!'),
        );
        expect(paypal, isA<InvalidData>());
        expect((paypal as InvalidData).details, contains('paypalMe'));
        expect(ok(await r.profile.get()), isNull);
      });

      test('watchProfile emits the current value, then changes', () async {
        final emitted = <UserProfile?>[];
        final sub = r.profile.watchProfile().listen(emitted.add);
        addTearDown(sub.cancel);
        await pumpEventQueue();
        ok(await r.profile.save(displayName: 'Ann'));
        await pumpEventQueue();
        expect(emitted.first, isNull);
        expect(emitted.last?.displayName, 'Ann');
      });
    });

    group('profile bank', () {
      test('is empty until saved', () async {
        expect(ok(await r.bank.get()), isNull);
      });

      test('save needs a profile', () async {
        expect(
          err(await r.bank.save(iban: testIban)),
          isA<NotFound>(),
        );
        expect(ok(await r.bank.get()), isNull);
      });

      test('save normalises IBAN and BIC and reads back', () async {
        ok(await r.profile.save(displayName: 'Ann'));
        final saved = ok(
          await r.bank.save(
            iban: 'de89 3704 0044 0532 0130 00',
            bic: 'cobadeffxxx',
            accountName: ' Ann Muster ',
          ),
        );
        expect(saved.iban, testIban);
        expect(saved.bic, 'COBADEFFXXX');
        expect(saved.accountName, 'Ann Muster');
        expect(ok(await r.bank.get()), saved);
      });

      test('save rejects bad input without leaking it', () async {
        ok(await r.profile.save(displayName: 'Ann'));
        final bad = err(await r.bank.save(iban: 'DE00 1234'));
        expect(bad, isA<InvalidData>());
        expect(bad.toString(), isNot(contains('1234')));
        final checksum = err(await r.bank.save(iban: 'DE89370400440532013001'));
        expect(checksum, isA<InvalidData>());
        expect(ok(await r.bank.get()), isNull);
      });

      test('save replaces, clear removes and is idempotent', () async {
        ok(await r.profile.save(displayName: 'Ann'));
        ok(await r.bank.save(iban: testIban, bic: 'COBADEFFXXX'));
        final again = ok(await r.bank.save(iban: testIban));
        expect(again.bic, isNull);
        ok(await r.bank.clear());
        expect(ok(await r.bank.get()), isNull);
        ok(await r.bank.clear());
      });

      test('toString never contains the IBAN', () async {
        ok(await r.profile.save(displayName: 'Ann'));
        final bank = ok(await r.bank.save(iban: testIban));
        expect(bank.toString(), isNot(contains('DE89')));
      });
    });

    group('user vehicles', () {
      Future<Vehicle> addGolf() async => ok(
        await r.vehicles.add(
          name: 'Golf',
          fuelType: FuelType.diesel,
          consumptionMilliPer100km: 5500,
          wearMilliPerKm: 80,
          kmRateMilliPerKm: 300,
        ),
      );

      test('add trims, stores every field and reads back', () async {
        final v = ok(
          await r.vehicles.add(
            name: '  Zoe ',
            fuelType: FuelType.electric,
            consumptionMilliPer100km: 16000,
          ),
        );
        expect(v.name, 'Zoe');
        expect(v.wearMilliPerKm, 0);
        expect(v.kmRateMilliPerKm, isNull);
        final golf = await addGolf();
        expect(ok(await r.vehicles.get(golf.id)), golf);
        expect(golf.kmRateMilliPerKm, 300);
      });

      test('add validates input', () async {
        expect(
          err(
            await r.vehicles.add(
              name: ' ',
              fuelType: FuelType.petrol,
              consumptionMilliPer100km: 7000,
            ),
          ),
          isA<InvalidData>(),
        );
        expect(
          err(
            await r.vehicles.add(
              name: 'x',
              fuelType: FuelType.petrol,
              consumptionMilliPer100km: 0,
            ),
          ),
          isA<InvalidData>(),
        );
        expect(await r.vehicles.watchVehicles().first, isEmpty);
      });

      test('get of an unknown id is NotFound', () async {
        expect(err(await r.vehicles.get('nope')), isA<NotFound>());
      });

      test('watchVehicles lists in creation order', () async {
        final a = await addGolf();
        final b = ok(
          await r.vehicles.add(
            name: 'Zoe',
            fuelType: FuelType.electric,
            consumptionMilliPer100km: 16000,
          ),
        );
        expect(await r.vehicles.watchVehicles().first, [a, b]);
      });

      test('update replaces every field; unknown id is NotFound', () async {
        final golf = await addGolf();
        final changed = ok(
          await r.vehicles.update(
            Vehicle(
              id: golf.id,
              name: 'Golf 2',
              fuelType: FuelType.petrol,
              consumptionMilliPer100km: 7000,
            ),
          ),
        );
        expect(ok(await r.vehicles.get(golf.id)), changed);
        expect(changed.kmRateMilliPerKm, isNull);
        expect(
          err(
            await r.vehicles.update(
              Vehicle(
                id: 'nope',
                name: 'x',
                fuelType: FuelType.petrol,
                consumptionMilliPer100km: 7000,
              ),
            ),
          ),
          isA<NotFound>(),
        );
      });

      test('softDelete hides, undo restores', () async {
        final golf = await addGolf();
        final undo = ok(await r.vehicles.softDelete(golf.id));
        expect(await r.vehicles.watchVehicles().first, isEmpty);
        expect(err(await r.vehicles.get(golf.id)), isA<NotFound>());
        expect(err(await r.vehicles.softDelete(golf.id)), isA<NotFound>());
        ok(await undo());
        expect(await r.vehicles.watchVehicles().first, [golf]);
      });

      test('restore: live is Conflict, unknown is NotFound', () async {
        final golf = await addGolf();
        expect(err(await r.vehicles.restore(golf.id)), isA<Conflict>());
        expect(err(await r.vehicles.restore('nope')), isA<NotFound>());
      });

      group('costs', () {
        const costs = UserVehicleCostDetails(
          annualKm: 12000,
          shareBasis: UserVehicleShareBasis.full,
          annualCents: {
            UserVehicleCostCategory.insurance: 54000,
            UserVehicleCostCategory.tyres: 0,
            UserVehicleCostCategory.other: 1,
          },
        );

        test('none until saved; unknown vehicle is NotFound', () async {
          final golf = await addGolf();
          expect(ok(await r.vehicles.getCosts(golf.id)), isNull);
          expect(err(await r.vehicles.getCosts('nope')), isA<NotFound>());
        });

        test('save, read back (skipped categories stay absent)', () async {
          final golf = await addGolf();
          expect(ok(await r.vehicles.saveCosts(golf.id, costs)), costs);
          final read = ok(await r.vehicles.getCosts(golf.id))!;
          expect(read, costs);
          expect(
            read.annualCents.containsKey(UserVehicleCostCategory.tax),
            isFalse,
          );
        });

        test('save replaces; clear removes and is idempotent', () async {
          final golf = await addGolf();
          ok(await r.vehicles.saveCosts(golf.id, costs));
          const smaller = UserVehicleCostDetails(annualKm: 8000);
          ok(await r.vehicles.saveCosts(golf.id, smaller));
          expect(ok(await r.vehicles.getCosts(golf.id)), smaller);
          ok(await r.vehicles.clearCosts(golf.id));
          expect(ok(await r.vehicles.getCosts(golf.id)), isNull);
          ok(await r.vehicles.clearCosts(golf.id));
        });

        test('save validates and needs a live vehicle', () async {
          final golf = await addGolf();
          expect(
            err(
              await r.vehicles.saveCosts(
                golf.id,
                const UserVehicleCostDetails(annualKm: 0),
              ),
            ),
            isA<InvalidData>(),
          );
          expect(
            err(
              await r.vehicles.saveCosts(
                golf.id,
                const UserVehicleCostDetails(
                  annualKm: 1,
                  annualCents: {UserVehicleCostCategory.tax: -1},
                ),
              ),
            ),
            isA<InvalidData>(),
          );
          expect(
            err(await r.vehicles.saveCosts('nope', costs)),
            isA<NotFound>(),
          );
          ok(await r.vehicles.softDelete(golf.id));
          expect(
            err(await r.vehicles.saveCosts(golf.id, costs)),
            isA<NotFound>(),
          );
        });
      });
    });
  });
}
