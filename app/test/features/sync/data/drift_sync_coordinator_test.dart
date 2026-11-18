// Real timers on purpose: the coordinator sits on a real in-memory Drift
// database, whose futures do not run under fake time. The 2 s debounce is
// injected as milliseconds instead.

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/lifecycle.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/drift_sync_coordinator.dart';
import 'package:mitlio/features/sync/data/outbox_writer.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

class _HalfRandom implements Random {
  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;

  @override
  int nextInt(int max) => 0;
}

class _FakeLifecycle implements LifecycleSource {
  final controller = StreamController<void>.broadcast();

  @override
  Stream<void> get onResume => controller.stream;

  void resume() => controller.add(null);
}

/// Counts how many pushes run at the same time.
class _SlowRemote extends FakeSyncRemote {
  int active = 0;
  int maxActive = 0;

  @override
  Future<Result<PushOutcome, RemoteError>> upsertRows(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    active++;
    maxActive = max(maxActive, active);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    active--;
    return super.upsertRows(table, rows);
  }
}

class _ThrowingService extends SyncService {
  _ThrowingService({
    required super.db,
    required super.remote,
    required super.clock,
    required super.random,
    required super.ids,
  });

  @override
  Future<SyncStatus> push(String groupId) => throw StateError('disk full');
}

/// Polls until [test] holds; fails after ~3 s.
Future<void> eventually(
  FutureOr<bool> Function() test, {
  String? reason,
}) async {
  for (var i = 0; i < 300; i++) {
    if (await test()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail(reason ?? 'condition did not become true');
}

class _World {
  _World._(
    this.r,
    this.groupId,
    this.remote,
    this.service,
    this.lifecycle,
    this.coordinator,
    this.errors,
  );

  final Repos r;
  final String groupId;
  final FakeSyncRemote remote;
  final SyncService service;
  final _FakeLifecycle lifecycle;
  final DriftSyncCoordinator coordinator;
  final List<Object> errors;

  AppDatabase get db => r.db!;
  FixedClock get clock => r.clock;

  static const debounce = Duration(milliseconds: 120);

  /// A shared group (already uploaded) and a coordinator that is not started.
  static Future<_World> create({
    FakeSyncRemote? remote,
    bool shared = true,
    SyncService Function(AppDatabase, FakeSyncRemote, Repos)? service,
    Future<void> Function(String groupId)? resumeShare,
  }) async {
    final r = await driftRepos();
    final seeded = await seedGroup(r);
    final db = r.db!;
    final fake = remote ?? FakeSyncRemote();
    if (shared) {
      // Since #198 the fake server is strict: the owner is made a member
      // by the bootstrap call of makeShared, which these tests skip.
      fake.addMember(seeded.groupId);
      await db.syncStateDao.setState(
        seeded.groupId,
        SyncState.uploading,
        role: SyncRole.owner,
      );
      final writer = OutboxWriter(
        db: db,
        clock: r.clock,
        ids: SequentialIdGenerator(prefix: 'up'),
      );
      await writer.enqueue(OutboxEntity.group, seeded.groupId);
      for (final m in seeded.members) {
        await writer.enqueue(OutboxEntity.member, m.id);
      }
    }
    final svc =
        service?.call(db, fake, r) ??
        SyncService(
          db: db,
          remote: fake,
          clock: r.clock,
          random: _HalfRandom(),
          ids: SequentialIdGenerator(prefix: 'pull'),
        );
    final lifecycle = _FakeLifecycle();
    final errors = <Object>[];
    final coordinator = DriftSyncCoordinator(
      db: db,
      service: svc,
      clock: r.clock,
      lifecycle: lifecycle,
      debounce: debounce,
      onError: (e, _) => errors.add(e),
      resumeShare: resumeShare,
    );
    addTearDown(coordinator.dispose);
    return _World._(
      r,
      seeded.groupId,
      fake,
      svc,
      lifecycle,
      coordinator,
      errors,
    );
  }

  Future<void> addMember(String name) async =>
      ok(await r.members.add(groupId, name: name));
}

void main() {
  group('app start', () {
    test('without shared groups nothing touches the network', () async {
      final w = await _World.create(shared: false);
      await w.coordinator.start();
      await w.coordinator.start(); // idempotent
      w.lifecycle.resume();
      await w.addMember('Dan');
      await Future<void>.delayed(_World.debounce * 2);
      expect(w.remote.calls, 0);
      expect(w.errors, isEmpty);
    });

    test('syncs every shared group once: push, then pull', () async {
      final w = await _World.create();
      await w.coordinator.start();
      expect(w.remote.count('groups'), 1);
      expect(w.remote.count('members'), 3);
      final sync = await w.db.syncStateDao.groupSync(w.groupId);
      expect(sync!.lastPushAt, isNotNull);
      expect(sync.lastPullAt, isNotNull);
      expect(await w.service.status(w.groupId), const SyncIdle());
    });

    test('a start with the server down shows the error, no crash', () async {
      final w = await _World.create(remote: FakeSyncRemote()..offline = true);
      await w.coordinator.start();
      expect(await w.service.status(w.groupId), const SyncError(Offline()));
      // The pull is not even tried: the server did not answer the push.
      expect(
        (await w.db.syncStateDao.groupSync(w.groupId))!.lastPullAt,
        isNull,
      );
      expect(w.errors, isEmpty);
    });
  });

  group('local writes', () {
    test('wait for a quiet moment, then go out as one sync', () async {
      final w = await _World.create();
      await w.coordinator.start();
      w.remote.calls = 0;
      await w.addMember('Dan');
      await w.addMember('Eve');
      await w.addMember('Fay');
      // Still inside the debounce: nothing was sent yet.
      expect(w.remote.calls, 0);
      expect(await w.service.status(w.groupId), const SyncPending(3));
      await eventually(() => w.remote.count('members') == 6);
      await eventually(() => w.remote.calls > 0);
      expect(await w.service.status(w.groupId), const SyncIdle());
    });

    test('a push does not trigger another one by itself', () async {
      final w = await _World.create();
      await w.coordinator.start();
      await w.addMember('Dan');
      await eventually(() => w.remote.count('members') == 4);
      final calls = w.remote.calls;
      await Future<void>.delayed(_World.debounce * 3);
      expect(w.remote.calls, calls);
    });

    test('a failed push waits for its backoff instead of looping', () async {
      final w = await _World.create();
      await w.coordinator.start();
      w.remote.offline = true;
      w.remote.calls = 0;
      await w.addMember('Dan');
      await eventually(() => w.remote.calls >= 1);
      await Future<void>.delayed(_World.debounce);
      final calls = w.remote.calls;
      await Future<void>.delayed(_World.debounce * 3);
      expect(w.remote.calls, calls, reason: 'the deferred op is not due');
      expect(await w.service.status(w.groupId), const SyncError(Offline()));
    });

    test('a local-only group queues nothing and is never synced', () async {
      final w = await _World.create(shared: false);
      await w.coordinator.start();
      await w.addMember('Dan');
      await Future<void>.delayed(_World.debounce * 2);
      expect(w.remote.calls, 0);
    });
  });

  group('resume', () {
    test('syncs again, but respects a waiting backoff', () async {
      final w = await _World.create();
      await w.coordinator.start();
      w.remote.offline = true;
      w.remote.calls = 0;
      await w.addMember('Dan');
      await eventually(() => w.remote.calls >= 1);
      await Future<void>.delayed(_World.debounce);
      w.remote.offline = false;

      w.lifecycle.resume();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(w.remote.count('members'), 3, reason: 'op not due yet');

      w.clock.advance(const Duration(minutes: 10));
      w.lifecycle.resume();
      await eventually(() => w.remote.count('members') == 4);
      expect(await w.service.status(w.groupId), const SyncIdle());
    });

    test('pulls as well: lastPullAt moves', () async {
      final w = await _World.create();
      await w.coordinator.start();
      w.clock.advance(const Duration(minutes: 1));
      w.lifecycle.resume();
      await eventually(
        () async =>
            (await w.db.syncStateDao.groupSync(w.groupId))!.lastPullAt ==
            w.clock.now(),
        reason: 'the resume sync pulled',
      );
    });
  });

  group('syncNow', () {
    test('one sync per group at a time; callers get the same result', () async {
      final slow = _SlowRemote();
      final w = await _World.create(remote: slow);
      final results = await Future.wait([
        w.coordinator.syncNow(w.groupId),
        w.coordinator.syncNow(w.groupId),
        w.coordinator.syncNow(w.groupId),
      ]);
      expect(slow.maxActive, 1);
      expect(results.every((s) => s.ran), isTrue);
      expect(results.first.status, const SyncIdle());
      expect(slow.count('members'), 3);
    });

    test('a call while one runs makes it go one more round', () async {
      final slow = _SlowRemote();
      final w = await _World.create(remote: slow);
      final first = w.coordinator.syncNow(w.groupId);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await w.addMember('Dan'); // arrives while the push runs
      final second = w.coordinator.syncNow(w.groupId);
      await Future.wait([first, second]);
      expect(slow.count('members'), 4);
      expect(await w.service.status(w.groupId), const SyncIdle());
    });

    test('force retries an op that waits for its backoff', () async {
      final w = await _World.create(remote: FakeSyncRemote()..offline = true);
      final failed = await w.coordinator.syncNow(w.groupId);
      expect(failed.status, const SyncError(Offline()));
      w.remote.offline = false;

      final waiting = await w.coordinator.syncNow(w.groupId);
      expect(waiting.status, const SyncError(Offline()), reason: 'not due');

      final forced = await w.coordinator.syncNow(w.groupId, force: true);
      expect(forced.status, const SyncIdle());
      expect(w.remote.count('members'), 3);
    });

    test('a local-only group answers without any call', () async {
      final w = await _World.create(shared: false);
      final stats = await w.coordinator.syncNow(w.groupId, force: true);
      expect(stats.ran, isFalse);
      expect(stats.status, const SyncIdle());
      expect(w.remote.calls, 0);
    });

    test('after NotMember the group is removed and no longer synced', () async {
      final w = await _World.create(
        remote: FakeSyncRemote()..fail = const NotMember(),
      );
      final first = await w.coordinator.syncNow(w.groupId);
      expect(first.status, const SyncError(NotMember()));
      w.remote.fail = null;
      final calls = w.remote.calls;
      final again = await w.coordinator.syncNow(w.groupId, force: true);
      expect(again.ran, isFalse);
      expect(again.status, const SyncError(NotMember()));
      expect(w.remote.calls, calls);
    });

    test('a refused change does not stop the pull', () async {
      final w = await _World.create();
      await w.coordinator.syncNow(w.groupId);
      await w.addMember('Dan');
      w.remote.failNext(const Rejected('check_violation'));
      final stats = await w.coordinator.syncNow(w.groupId);
      expect(stats.status, isA<SyncError>());
      expect((stats.status as SyncError).error, isA<Rejected>());
      expect(
        (await w.db.syncStateDao.groupSync(w.groupId))!.lastPullAt,
        isNotNull,
      );
    });

    test('retries by itself when the earliest op is due', () async {
      final w = await _World.create(remote: FakeSyncRemote()..offline = true);
      await w.coordinator.syncNow(w.groupId);
      w.remote.offline = false;
      // First backoff is 1.5 s (2 s at 75 %); the fixed clock jumps ahead.
      w.clock.advance(const Duration(seconds: 3));
      await eventually(() => w.remote.count('members') == 3);
    });
  });

  group('an interrupted share (state uploading)', () {
    /// What `ShareGroupRepository.makeShared` does for an uploading group:
    /// push, and flip to `shared` once the outbox is empty.
    Future<void> Function(String) fakeMakeShared(
      List<String> calls,
      Future<_World> Function() world,
    ) => (id) async {
      calls.add(id);
      final w = await world();
      await w.service.push(id);
      if (await w.db.syncStateDao.pendingOutboxCount(id) == 0) {
        await w.db.syncStateDao.setState(id, SyncState.shared);
      }
    };

    test(
      'a trigger finishes the share: the group ends shared, then pulls',
      () async {
        final calls = <String>[];
        late _World w;
        w = await _World.create(
          resumeShare: (id) => fakeMakeShared(calls, () async => w)(id),
        );
        expect(
          (await w.db.syncStateDao.groupSync(w.groupId))!.state,
          'uploading',
        );
        final stats = await w.coordinator.syncNow(w.groupId);
        expect(calls, [w.groupId]);
        expect(stats.ran, isTrue);
        expect(stats.status, const SyncIdle());
        final row = await w.db.syncStateDao.groupSync(w.groupId);
        expect(row!.state, 'shared');
        expect(row.lastPullAt, isNotNull);
        expect(w.remote.count('members'), 3);
      },
    );

    test('app start resumes it by itself', () async {
      final calls = <String>[];
      late _World w;
      w = await _World.create(
        resumeShare: (id) => fakeMakeShared(calls, () async => w)(id),
      );
      await w.coordinator.start();
      expect(calls, [w.groupId]);
      expect((await w.db.syncStateDao.groupSync(w.groupId))!.state, 'shared');
    });

    test(
      'while it cannot finish: no pull, the error shows, state stays',
      () async {
        late _World w;
        w = await _World.create(
          remote: FakeSyncRemote()..offline = true,
          resumeShare: (id) => fakeMakeShared([], () async => w)(id),
        );
        final stats = await w.coordinator.syncNow(w.groupId);
        expect(stats.status, const SyncError(Offline()));
        final row = await w.db.syncStateDao.groupSync(w.groupId);
        expect(row!.state, 'uploading');
        expect(row.lastPullAt, isNull);
      },
    );

    test('a shared group never goes through the share path', () async {
      final calls = <String>[];
      late _World w;
      w = await _World.create(
        resumeShare: (id) => fakeMakeShared(calls, () async => w)(id),
      );
      await w.db.syncStateDao.setState(w.groupId, SyncState.shared);
      await w.coordinator.syncNow(w.groupId);
      expect(calls, isEmpty);
    });

    test('the line says uploading, with what is left', () async {
      final w = await _World.create();
      final seen = <SyncStatus?>[];
      final sub = w.coordinator.watchLine(w.groupId).listen(seen.add);
      addTearDown(sub.cancel);
      await eventually(() => seen.isNotEmpty);
      expect(seen.last, const SyncUploading(remaining: 4));
      w.remote.offline = true;
      await w.coordinator.syncNow(w.groupId);
      await eventually(() => seen.last == const SyncError(Offline()));
    });
  });

  group('groupOpened', () {
    test('syncs a shared group in the background', () async {
      final w = await _World.create();
      w.coordinator.groupOpened(w.groupId);
      await eventually(() => w.remote.count('members') == 3);
    });

    test('a local-only group stays offline', () async {
      final w = await _World.create(shared: false);
      w.coordinator.groupOpened(w.groupId);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(w.remote.calls, 0);
    });

    test('an unexpected failure is reported, not swallowed', () async {
      final w = await _World.create(
        service: (db, remote, r) => _ThrowingService(
          db: db,
          remote: remote,
          clock: r.clock,
          random: _HalfRandom(),
          ids: SequentialIdGenerator(prefix: 'b'),
        ),
      );
      w.coordinator.groupOpened(w.groupId);
      await eventually(() => w.errors.isNotEmpty);
      expect(w.errors.single, isA<StateError>());
    });

    test('without a sink the failure surfaces to the caller', () async {
      final w = await _World.create(
        service: (db, remote, r) => _ThrowingService(
          db: db,
          remote: remote,
          clock: r.clock,
          random: _HalfRandom(),
          ids: SequentialIdGenerator(prefix: 'b'),
        ),
      );
      await expectLater(
        w.coordinator.syncNow(w.groupId),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('refreshAll', () {
    test('syncs every shared group with force, skips local ones', () async {
      final w = await _World.create(remote: FakeSyncRemote()..offline = true);
      await w.coordinator.syncNow(w.groupId);
      w.remote.offline = false;
      final local = ok(
        await w.r.groups.create(name: 'Home', currency: eur, createdBy: 'dev'),
      );
      final stats = await w.coordinator.refreshAll();
      expect(stats.map((s) => s.groupId), [w.groupId]);
      expect(stats.single.status, const SyncIdle());
      expect(local.id, isNot(w.groupId));
    });

    test('nothing shared: an empty answer, no call', () async {
      final w = await _World.create(shared: false);
      expect(await w.coordinator.refreshAll(), isEmpty);
      expect(w.remote.calls, 0);
    });
  });

  group('watchLine', () {
    test('is null for a local group', () async {
      final w = await _World.create(shared: false);
      expect(await w.coordinator.watchLine(w.groupId).first, isNull);
    });

    test(
      'follows pending, sending, idle and errors of a shared group',
      () async {
        final w = await _World.create();
        await w.db.syncStateDao.setState(w.groupId, SyncState.shared);
        final seen = <SyncStatus?>[];
        final sub = w.coordinator.watchLine(w.groupId).listen(seen.add);
        addTearDown(sub.cancel);
        await eventually(() => seen.isNotEmpty);
        expect(seen.last, const SyncPending(4));

        await w.coordinator.syncNow(w.groupId);
        await eventually(() => seen.last == const SyncIdle());
        expect(seen, contains(const SyncSyncing()));

        w.remote.offline = true;
        await w.addMember('Dan');
        await w.coordinator.syncNow(w.groupId);
        await eventually(() => seen.last == const SyncError(Offline()));
      },
    );

    test('goes away when the group is no longer shared', () async {
      final w = await _World.create();
      final seen = <SyncStatus?>[];
      final sub = w.coordinator.watchLine(w.groupId).listen(seen.add);
      addTearDown(sub.cancel);
      await eventually(() => seen.isNotEmpty);
      await w.db.syncStateDao.clearGroup(w.groupId);
      await eventually(() => seen.last == null);
    });
  });

  group('acknowledge', () {
    test('forgets a refused change', () async {
      final w = await _World.create();
      await w.coordinator.syncNow(w.groupId);
      await w.addMember('Dan');
      w.remote.failNext(const Rejected('check_violation'));
      await w.coordinator.syncNow(w.groupId);
      expect(
        await w.service.status(w.groupId),
        isA<SyncError>().having((s) => s.error, 'error', isA<Rejected>()),
      );
      await w.coordinator.acknowledge(w.groupId);
      expect(await w.service.status(w.groupId), const SyncIdle());
    });
  });

  group('dispose', () {
    test('stops listening to resume and writes', () async {
      final w = await _World.create();
      await w.coordinator.start();
      w.coordinator.dispose();
      w.remote.calls = 0;
      w.lifecycle.resume();
      await w.addMember('Dan');
      await Future<void>.delayed(_World.debounce * 2);
      expect(w.remote.calls, 0);
      await w.coordinator.start(); // a disposed coordinator stays quiet
      expect(w.remote.calls, 0);
    });
  });

  group('dao', () {
    test('syncGroupIds lists shared and uploading groups only', () async {
      final w = await _World.create();
      final dao = w.db.syncStateDao;
      final b = ok(
        await w.r.groups.create(name: 'B', currency: eur, createdBy: 'dev'),
      );
      final c = ok(
        await w.r.groups.create(name: 'C', currency: eur, createdBy: 'dev'),
      );
      await dao.setState(b.id, SyncState.shared);
      await dao.setState(c.id, SyncState.removed);
      expect(
        (await dao.syncGroupIds())..sort(),
        [w.groupId, b.id]..sort(),
      );
    });
  });
}
