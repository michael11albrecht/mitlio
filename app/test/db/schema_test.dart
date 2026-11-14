import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';

import 'generated/schema.dart';

/// Fails when the Drift tables drift from `drift_schemas/drift_schema_v1.json`.
/// A schema change needs a version bump, a migration and `make db-schema`.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('current schema matches the exported v1 schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 1);
  });
}
