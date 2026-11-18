import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/sync.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';

import '../db/test_support.dart';

void main() {
  late AppDatabase db;
  late FakeSyncRemote remote;
  late Map<String, DriveHandler> h;

  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    remote = FakeSyncRemote();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncRemoteProvider.overrideWithValue(remote),
      ],
    );
    addTearDown(container.dispose);
    h = syncDriveHandlers(container);
    await db.groupsDao.insertGroup(newGroup('g1'));
  });

  test('missing groupId is invalid_params', () async {
    expect((await h['sync.now']!({}))['error'], 'invalid_params');
    expect((await h['sync.status']!({}))['error'], 'invalid_params');
  });

  test('a local group: nothing ran, no line, no network', () async {
    final now = await h['sync.now']!({'groupId': 'g1'});
    expect(now['ran'], false);
    expect(now['status'], 'idle');
    expect(remote.calls, 0);
    final status = await h['sync.status']!({'groupId': 'g1'});
    expect(status['state'], 'local');
    expect(status['line'], isNull);
    expect(status['text'], isNull);
  });

  test('a shared group syncs and reports the line in words', () async {
    await db.syncStateDao.setState('g1', SyncState.shared);
    remote.addMember('g1');
    final now = await h['sync.now']!({'groupId': 'g1'});
    expect(now['ran'], true);
    expect(now['status'], 'idle');
    expect(now['pendingOutbox'], 0);
    expect(now['lastPullAt'], isNotNull);
    final status = await h['sync.status']!({'groupId': 'g1'});
    expect(status['state'], 'shared');
    expect(status['line'], {'status': 'idle'});
    expect(status['text'], 'Aktuell');
  });

  test('a failure shows as case name and German text', () async {
    await db.syncStateDao.setState('g1', SyncState.shared);
    await db.syncStateDao.recordError(
      'g1',
      'serverDown',
      DateTime.utc(2026),
    );
    final status = await h['sync.status']!({'groupId': 'g1'});
    expect((status['line']! as Map)['error'], 'serverDown');
    expect(status['text'], contains('Server'));
  });
}
