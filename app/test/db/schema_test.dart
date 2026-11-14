import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';

import 'generated/schema.dart';

/// Fails when the Drift tables drift from `drift_schemas/drift_schema_v2.json`.
/// A schema change needs a version bump, a migration and `make db-schema`.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('fresh v2 schema matches the exported v2 schema', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('v1 -> v2 keeps data and adds the rides tables', () async {
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
    await verifier.migrateAndValidate(db, 2);

    final groups = await db.groupsDao.watchGroups().first;
    expect(groups.single.name, 'Trip');
    final members = await db.membersDao.listAllByGroup('g1');
    expect(members.single.name, 'Ann');

    // New tables are usable after the upgrade.
    expect(await db.select(db.vehicles).get(), isEmpty);
    expect(await db.select(db.rideTemplates).get(), isEmpty);
    expect(await db.select(db.rides).get(), isEmpty);
  });
}
