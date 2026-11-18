import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/share.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
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
        authServiceProvider.overrideWithValue(FakeAuthService()),
        clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 3))),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
    );
    addTearDown(container.dispose);
    h = shareDriveHandlers(container);
    await db.groupsDao.insertGroup(newGroup('g1'));
  });

  test('needs a groupId', () async {
    expect((await h['group.share']!({}))['error'], 'invalid_params');
  });

  test('shares the group and reports state and counts', () async {
    expect(await h['group.share']!({'groupId': 'g1'}), {
      'state': 'shared',
      'uploaded': 1,
      'total': 1,
    });
    expect((await db.syncStateDao.groupSync('g1'))!.state, 'shared');
    expect(remote.hasMember('g1'), isTrue);
  });

  test('an unknown group is not_found', () async {
    expect(
      (await h['group.share']!({'groupId': 'nope'}))['error'],
      'not_found',
    );
  });

  test('a removed group is notMember', () async {
    await db.syncStateDao.setState('g1', SyncState.removed);
    expect((await h['group.share']!({'groupId': 'g1'}))['error'], 'notMember');
  });

  test('a failure carries the error case and the numbers', () async {
    remote.offline = true;
    expect(await h['group.share']!({'groupId': 'g1'}), {
      'error': 'offline',
      'message': 'Offline()',
      'uploaded': 0,
      'total': 1,
    });
  });
}
