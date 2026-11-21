import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/members/data/services/fake_iban_cipher.dart';
import 'package:mitlio/features/profile/data/repositories/drift_profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/drift_profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/drift_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/fake_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/sync/data/outbox_writer.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'profile_repositories_contract.dart';

AppDatabase _db() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

Future<ProfileRepos> _drift() async {
  final db = _db();
  final clock = FixedClock(DateTime.utc(2026, 3, 1, 12));
  return (
    profile: DriftProfileRepository(db: db, clock: clock),
    bank: DriftProfileBankRepository(
      db: db,
      clock: clock,
      cipher: const FakeIbanCipher(),
    ),
    vehicles: DriftUserVehiclesRepository(
      db: db,
      clock: clock,
      ids: SequentialIdGenerator(),
    ),
  );
}

Future<ProfileRepos> _fake() async {
  final profile = FakeProfileRepository();
  return (
    profile: profile,
    bank: FakeProfileBankRepository(profile: profile),
    vehicles: FakeUserVehiclesRepository(ids: SequentialIdGenerator()),
  );
}

void main() {
  runProfileRepositoriesContract('drift', _drift);
  runProfileRepositoriesContract('fake', _fake);

  group('Drift storage', () {
    test('the IBAN is stored encrypted, never in the profile row', () async {
      final db = _db();
      final clock = FixedClock(DateTime.utc(2026, 3, 1, 12));
      final profile = DriftProfileRepository(db: db, clock: clock);
      final bank = DriftProfileBankRepository(
        db: db,
        clock: clock,
        cipher: const FakeIbanCipher(),
      );
      ok(await profile.save(displayName: 'Ann', paypalMe: 'ann'));
      ok(await bank.save(iban: testIban));

      final stored = (await db.localProfileBankDao.find())!;
      expect(stored.iban, startsWith(FakeIbanCipher.marker));
      expect(stored.iban, isNot(contains(testIban)));
      final profileRow = (await db.profileDao.find())!;
      expect(profileRow.toString(), isNot(contains('DE89')));
    });

    test(
      'profile and personal vehicle writes never enqueue sync ops',
      () async {
        final db = _db();
        final clock = FixedClock(DateTime.utc(2026, 3, 1, 12));
        final profile = DriftProfileRepository(db: db, clock: clock);
        final bank = DriftProfileBankRepository(
          db: db,
          clock: clock,
          cipher: const FakeIbanCipher(),
        );
        final vehicles = DriftUserVehiclesRepository(
          db: db,
          clock: clock,
          ids: SequentialIdGenerator(),
        );
        ok(await profile.save(displayName: 'Ann'));
        ok(await bank.save(iban: testIban));
        final v = ok(
          await vehicles.add(
            name: 'Golf',
            fuelType: FuelType.petrol,
            consumptionMilliPer100km: 7000,
          ),
        );
        ok(
          await vehicles.saveCosts(
            v.id,
            const UserVehicleCostDetails(annualKm: 1),
          ),
        );
        expect(await db.select(db.localOutbox).get(), isEmpty);
      },
    );

    test('a group vehicle copy keeps its personal source link', () async {
      final repos = await driftRepos();
      final db = repos.db!;
      final gid = (await seedGroup(repos)).groupId;
      final golf = ok(
        await repos.vehicles.add(
          gid,
          name: 'Golf',
          fuelType: FuelType.petrol,
          consumptionMilliPer100km: 7000,
        ),
      );
      expect(
        (await db.ridesDao.findVehicle(golf.id))!.sourceUserVehicleId,
        isNull,
      );
      await db.ridesDao.updateVehicle(
        golf.id,
        const VehiclesCompanion(sourceUserVehicleId: Value('uv-1')),
      );
      expect(
        (await db.ridesDao.findVehicle(golf.id))!.sourceUserVehicleId,
        'uv-1',
      );
    });

    test(
      'the sync payload of a vehicle never carries the source link',
      () async {
        final repos = await driftRepos();
        final db = repos.db!;
        final gid = (await seedGroup(repos)).groupId;
        await db.syncStateDao.setState(gid, SyncState.shared);
        final golf = ok(
          await repos.vehicles.add(
            gid,
            name: 'Golf',
            fuelType: FuelType.petrol,
            consumptionMilliPer100km: 7000,
          ),
        );
        await db.ridesDao.updateVehicle(
          golf.id,
          const VehiclesCompanion(sourceUserVehicleId: Value('uv-1')),
        );
        ok(await repos.vehicles.update(golf));
        final payloads = [
          for (final o in await db.select(db.localOutbox).get())
            if (o.entity == OutboxEntity.vehicle.table) o.payload,
        ];
        expect(payloads, isNotEmpty);
        for (final p in payloads) {
          expect(p, isNot(contains('source_user_vehicle_id')));
          expect(p, isNot(contains('uv-1')));
          expect(jsonDecode(p), isA<Map<String, Object?>>());
        }
      },
    );
  });
}
