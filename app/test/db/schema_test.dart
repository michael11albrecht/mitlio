import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';

import 'generated/schema.dart';

/// Fails when the Drift tables drift from `drift_schemas/drift_schema_v5.json`.
/// A schema change needs a version bump, a migration and `make db-schema`.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('fresh v5 schema matches the exported v5 schema', () async {
    final connection = await verifier.startAt(5);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);
  });

  test('v1 -> v5 keeps data and adds the rides and revisions tables', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase
      ..execute(
        'INSERT INTO groups (id, name, currency, created_by, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['g1', 'Trip', 'EUR', 'dev', '2026-01-01T00:00:00.000Z', '0001'],
      )
      ..execute(
        'INSERT INTO members (id, group_id, created_at, updated_at, name, '
        'position) VALUES (?, ?, ?, ?, ?, ?)',
        ['m1', 'g1', '2026-01-01T00:00:00.000Z', '0001', 'Ann', 0],
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);

    final groups = await db.groupsDao.watchGroups().first;
    expect(groups.single.name, 'Trip');
    final members = await db.membersDao.listAllByGroup('g1');
    expect(members.single.name, 'Ann');
    expect(members.single.canDrive, isTrue);

    // New tables are usable after the upgrade.
    expect(await db.select(db.vehicles).get(), isEmpty);
    expect(await db.select(db.rideTemplates).get(), isEmpty);
    expect(await db.select(db.rides).get(), isEmpty);
    expect(await db.select(db.expenseRevisions).get(), isEmpty);
  });

  test('v2 -> v5 keeps expenses and adds a usable revisions table', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase
      ..execute(
        'INSERT INTO groups (id, name, currency, created_by, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['g1', 'Trip', 'EUR', 'dev', '2026-01-01T00:00:00.000Z', '0001'],
      )
      ..execute(
        'INSERT INTO expenses (id, group_id, created_at, updated_at, title, '
        'amount_cents, currency, fx_rate_ppm, group_amount_cents, date, type, '
        'split_mode) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'e1',
          'g1',
          '2026-01-01T00:00:00.000Z',
          '0001',
          'Dinner',
          1000,
          'EUR',
          1000000,
          1000,
          '2026-01-01T00:00:00.000Z',
          'regular',
          'equal',
        ],
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);

    expect((await db.select(db.expenses).get()).single.title, 'Dinner');
    expect(await db.select(db.expenseRevisions).get(), isEmpty);
    await db.expensesDao.addRevision(
      id: 'r1',
      expenseId: 'e1',
      groupId: 'g1',
      changedAt: DateTime.utc(2026, 2),
      snapshot: '{}',
      keep: 50,
    );
    expect((await db.expensesDao.revisionsOf('e1')).single.revision, 1);
  });

  test(
    'v3 -> v5 makes existing members drivers and adds the prompt flags',
    () async {
      final schema = await verifier.schemaAt(3);
      schema.rawDatabase
        ..execute(
          'INSERT INTO groups (id, name, currency, created_by, created_at, '
          'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
          ['g1', 'Trip', 'EUR', 'dev', '2026-01-01T00:00:00.000Z', '0001'],
        )
        ..execute(
          'INSERT INTO members (id, group_id, created_at, updated_at, name, '
          'position) VALUES (?, ?, ?, ?, ?, ?)',
          ['m1', 'g1', '2026-01-01T00:00:00.000Z', '0001', 'Ann', 0],
        );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 5);

      final member = (await db.membersDao.listAllByGroup('g1')).single;
      expect(member.canDrive, isTrue);
      expect(await db.membersDao.askedDriverPrompts(), isEmpty);
      await db.membersDao.markDriverPromptAsked('m1', '0002');
      expect(await db.membersDao.askedDriverPrompts(), {'m1'});
    },
  );

  test(
    'v4 -> v5 adds the sync tables, keeps data, recreates the outbox',
    () async {
      final schema = await verifier.schemaAt(4);
      schema.rawDatabase
        ..execute(
          'INSERT INTO groups (id, name, currency, created_by, created_at, '
          'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
          ['g1', 'Trip', 'EUR', 'dev', '2026-01-01T00:00:00.000Z', '0001'],
        )
        ..execute(
          'INSERT INTO members (id, group_id, created_at, updated_at, name, '
          'position, can_drive) VALUES (?, ?, ?, ?, ?, ?, ?)',
          ['m1', 'g1', '2026-01-01T00:00:00.000Z', '0001', 'Ann', 0, 0],
        );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 5);

      expect((await db.groupsDao.watchGroups().first).single.name, 'Trip');
      final member = (await db.membersDao.listAllByGroup('g1')).single;
      expect(member.canDrive, isFalse);

      final dao = db.syncStateDao;
      expect(await dao.groupSync('g1'), isNull);
      await dao.setState('g1', SyncState.shared, role: SyncRole.owner);
      await dao.setCursor('g1', 'expenses', 3);
      expect(await dao.cursorOf('g1', 'expenses'), 3);
      expect(await dao.hlcNodeId(SequentialIdGenerator()), 'id-1');
      expect(await dao.pendingOutboxCount('g1'), 0);
      await db
          .into(db.localOutbox)
          .insert(
            LocalOutboxCompanion.insert(
              opId: 'o1',
              groupId: 'g1',
              entity: 'expense',
              entityId: 'e1',
              op: 'upsert',
              payload: '{}',
              createdAt: DateTime.utc(2026),
            ),
          );
      expect(await dao.pendingOutboxCount('g1'), 1);
    },
  );
}
