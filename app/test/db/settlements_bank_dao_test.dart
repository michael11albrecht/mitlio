import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = openTestDb();
    await seedGroup(db);
  });
  tearDown(() => db.close());

  group('SettlementsDao', () {
    test('insert, find, list, update', () async {
      await db.settlementsDao.insertSettlement(
        newSettlement('s1', 'g1', 'm1', 'm2'),
      );
      await db.settlementsDao.insertSettlement(
        newSettlement('s2', 'g1', 'm2', 'm1', method: 'paypal'),
      );
      expect((await db.settlementsDao.findById('s1'))!.method, 'cash');
      expect(await db.settlementsDao.findById('x'), isNull);
      expect(await db.settlementsDao.listByGroup('g1'), hasLength(2));

      expect(
        await db.settlementsDao.updateSettlement(
          id: 's1',
          amountCents: 700,
          method: 'sepa',
          date: DateTime.utc(2026, 5, 5),
          updatedAt: '0002',
        ),
        isTrue,
      );
      final s = (await db.settlementsDao.findById('s1'))!;
      expect([s.amountCents, s.method], [700, 'sepa']);
      expect(
        await db.settlementsDao.updateSettlement(
          id: 'x',
          amountCents: 1,
          method: 'cash',
          date: DateTime.utc(2026),
          updatedAt: '3',
        ),
        isFalse,
      );
    });

    test('soft delete excludes from default queries', () async {
      await db.settlementsDao.insertSettlement(
        newSettlement('s1', 'g1', 'm1', 'm2'),
      );
      expect(
        await db.settlementsDao.softDelete(
          id: 's1',
          deletedAt: deletedAt,
          updatedAt: '0002',
        ),
        isTrue,
      );
      expect(
        await db.settlementsDao.softDelete(
          id: 's1',
          deletedAt: deletedAt,
          updatedAt: '0003',
        ),
        isFalse,
      );
      expect(await db.settlementsDao.findById('s1'), isNull);
      expect(await db.settlementsDao.listByGroup('g1'), isEmpty);
      expect(await db.settlementsDao.watchByGroup('g1').first, isEmpty);
      expect(await db.select(db.settlements).get(), hasLength(1));
    });

    test('constraints: amount > 0, known method, existing members', () async {
      await expectLater(
        db.settlementsDao.insertSettlement(
          newSettlement('s1', 'g1', 'm1', 'm2', amount: 0),
        ),
        throwsA(anything),
      );
      await expectLater(
        db.settlementsDao.insertSettlement(
          newSettlement('s1', 'g1', 'm1', 'm2', method: 'bitcoin'),
        ),
        throwsA(anything),
      );
      await expectLater(
        db.settlementsDao.insertSettlement(
          newSettlement('s1', 'g1', 'm1', 'zz'),
        ),
        throwsA(anything),
      );
    });
  });

  group('LocalMemberBankDao', () {
    test('upsert, find, delete', () async {
      expect(await db.localMemberBankDao.findByMember('m1'), isNull);
      await db.localMemberBankDao.upsert(
        LocalMemberBankCompanion.insert(
          memberId: 'm1',
          iban: 'DE89370400440532013000',
          updatedAt: '0001',
        ),
      );
      await db.localMemberBankDao.upsert(
        LocalMemberBankCompanion.insert(
          memberId: 'm1',
          iban: 'DE02120300000000202051',
          updatedAt: '0002',
        ),
      );
      expect(
        (await db.localMemberBankDao.findByMember('m1'))!.iban,
        'DE02120300000000202051',
      );
      await db.localMemberBankDao.deleteByMember('m1');
      expect(await db.localMemberBankDao.findByMember('m1'), isNull);
    });

    test('IBAN never leaks into synced rows or other DAO results', () async {
      const iban = 'DE89370400440532013000';
      await db.localMemberBankDao.upsert(
        LocalMemberBankCompanion.insert(
          memberId: 'm1',
          iban: iban,
          updatedAt: '0001',
        ),
      );
      final members = await db.membersDao.listByGroup('g1');
      expect(members.map((m) => m.toString()).join(), isNot(contains(iban)));
      expect(members.first.toJson().values, isNot(contains(iban)));
      // The bank table is not part of any synced table's columns.
      for (final t in <TableInfo<Table, Object?>>[
        db.groups,
        db.members,
        db.expenses,
        db.expensePayers,
        db.expenseShares,
        db.settlements,
      ]) {
        expect(t.$columns.map((c) => c.name), isNot(contains('iban')));
      }
    });

    test('requires an existing member', () async {
      await expectLater(
        db.localMemberBankDao.upsert(
          LocalMemberBankCompanion.insert(
            memberId: 'ghost',
            iban: 'x',
            updatedAt: '1',
          ),
        ),
        throwsA(anything),
      );
    });
  });

  test('local_outbox exists and accepts rows with default attempts', () async {
    await db
        .into(db.localOutbox)
        .insert(
          LocalOutboxCompanion.insert(
            entity: 'expense',
            entityId: 'e1',
            op: 'upsert',
            payload: '{}',
          ),
        );
    final row = (await db.select(db.localOutbox).get()).single;
    expect([row.seq, row.attempts], [1, 0]);
  });

  test('appDatabaseProvider throws unless overridden', () {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);
    expect(() => bare.read(appDatabaseProvider), throwsA(anything));

    final c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    expect(c.read(appDatabaseProvider), same(db));
  });

  test('file database persists across reopen', () async {
    final dir = Directory.systemTemp.createTempSync('mitlio_db_');
    addTearDown(() => dir.deleteSync(recursive: true));
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(
      () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
    );
    final file = File('${dir.path}/app.sqlite');
    var d = AppDatabase(NativeDatabase(file));
    await d.groupsDao.insertGroup(newGroup('g1'));
    await d.close();
    d = AppDatabase(NativeDatabase(file));
    expect(await d.groupsDao.findById('g1'), isNotNull);
    await d.close();
  });
}
