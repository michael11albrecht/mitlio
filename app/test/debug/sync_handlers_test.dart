import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/sync.dart';

import '../db/test_support.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;

  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    h = syncDriveHandlers(container);
    await db.groupsDao.insertGroup(newGroup('g1'));
  });

  test('a never shared group reports local', () async {
    expect(await h['sync.state']!({'groupId': 'g1'}), {
      'groupId': 'g1',
      'state': 'local',
      'role': null,
      'cursors': <String, int>{},
      'pendingOutbox': 0,
      'lastPushAt': null,
      'lastPullAt': null,
      'lastErrorCode': null,
      'lastErrorAt': null,
    });
  });

  test('reports state, role, cursors, pending count and last error', () async {
    final dao = db.syncStateDao;
    await dao.setState('g1', SyncState.shared, role: SyncRole.owner);
    await dao.setCursor('g1', 'expenses', 4);
    await dao.markPulled('g1', DateTime.utc(2026, 3));
    await dao.recordError('g1', 'offline', DateTime.utc(2026, 3, 2));
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
            createdAt: DateTime.utc(2026, 3),
          ),
        );
    final r = await h['sync.state']!({'groupId': 'g1'});
    expect(r['state'], 'shared');
    expect(r['role'], 'owner');
    expect(r['cursors'], {'expenses': 4});
    expect(r['pendingOutbox'], 1);
    expect(r['lastPullAt'], '2026-03-01T00:00:00.000Z');
    expect(r['lastErrorCode'], 'offline');
    expect(r['lastErrorAt'], '2026-03-02T00:00:00.000Z');
  });

  test('a missing groupId is invalid_params', () async {
    expect((await h['sync.state']!({}))['error'], 'invalid_params');
  });
}
