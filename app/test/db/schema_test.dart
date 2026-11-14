import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';

import 'generated/schema.dart';

/// Fails when the Drift tables drift from `drift_schemas/drift_schema_v3.json`.
/// A schema change needs a version bump, a migration and `make db-schema`.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('fresh v3 schema matches the exported v3 schema', () async {
    final connection = await verifier.startAt(3);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
  });

  test('v1 -> v3 keeps data and adds the rides and revisions tables', () async {
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
    await verifier.migrateAndValidate(db, 3);

    final groups = await db.groupsDao.watchGroups().first;
    expect(groups.single.name, 'Trip');
    final members = await db.membersDao.listAllByGroup('g1');
    expect(members.single.name, 'Ann');

    // New tables are usable after the upgrade.
    expect(await db.select(db.vehicles).get(), isEmpty);
    expect(await db.select(db.rideTemplates).get(), isEmpty);
    expect(await db.select(db.rides).get(), isEmpty);
    expect(await db.select(db.expenseRevisions).get(), isEmpty);
  });

  test('v2 -> v3 keeps expenses and adds a usable revisions table', () async {
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
    await verifier.migrateAndValidate(db, 3);

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
}
