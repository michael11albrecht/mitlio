// An interrupted share finishes by itself when a sync trigger fires (P6-T12 +
// P6-T15): the coordinator hands an `uploading` group to makeShared.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/lifecycle.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/drift_sync_coordinator.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

class _Half implements Random {
  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

/// The server stops answering row writes after [okWrites] of them.
class _DiesAfter extends FakeSyncRemote {
  int? okWrites;
  int writes = 0;

  @override
  Future<Result<PushOutcome, RemoteError>> upsertRows(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    if (okWrites != null && writes >= okWrites!) return const Err(Offline());
    writes++;
    return super.upsertRows(table, rows);
  }
}

void main() {
  test('uploading group + trigger: makeShared finishes it, group ends '
      'shared, then the first pull runs', () async {
    final r = await driftRepos();
    final seeded = await seedGroup(r);
    final db = r.db!;
    final remote = _DiesAfter()..okWrites = 2; // group row, group op, then dead
    final ids = SequentialIdGenerator(prefix: 's');
    final service = SyncService(
      db: db,
      remote: remote,
      clock: r.clock,
      random: _Half(),
      ids: ids,
    );
    final share = ShareGroupRepository(
      db: db,
      auth: AuthRepository(FakeAuthService()),
      remote: remote,
      sync: service,
      clock: r.clock,
      ids: ids,
    );

    // The user taps "share"; the connection dies half way.
    final first = await share.makeShared(seeded.groupId);
    expect(first, isA<Err<ShareProgress, ShareError>>());
    expect(
      (await db.syncStateDao.groupSync(seeded.groupId))!.state,
      SyncState.uploading.name,
    );
    expect(
      await db.syncStateDao.pendingOutboxCount(seeded.groupId),
      isPositive,
    );

    // Back online; the app comes to the foreground, no tap needed.
    remote.okWrites = null;
    r.clock.advance(const Duration(minutes: 10));
    final coordinator = DriftSyncCoordinator(
      db: db,
      service: service,
      clock: r.clock,
      lifecycle: const NoLifecycle(),
      resumeShare: (id) async {
        await share.makeShared(id);
      },
    );
    addTearDown(coordinator.dispose);
    final stats = await coordinator.syncNow(seeded.groupId);

    final row = await db.syncStateDao.groupSync(seeded.groupId);
    expect(row!.state, SyncState.shared.name);
    expect(row.lastPullAt, isNotNull);
    expect(await db.syncStateDao.pendingOutboxCount(seeded.groupId), 0);
    expect(stats.status, const SyncIdle());
    expect(remote.count('members'), 3);
  });
}
