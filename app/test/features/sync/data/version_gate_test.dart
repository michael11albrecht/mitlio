import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/outbox_writer.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/repositories/version_gate.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';
import 'package:mitlio/features/sync/data/services/fake_app_config_remote.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_platform.dart';
import '../../repo_test_support.dart';

class _NoRandom implements Random {
  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

void main() {
  late Repos r;
  late AppDatabase db;
  late FixedClock clock;
  late FakeAppConfigRemote config;
  late FakeLinkLauncher launcher;

  setUp(() async {
    r = await driftRepos();
    db = r.db!;
    clock = FixedClock(DateTime.utc(2026, 11));
    config = FakeAppConfigRemote();
    launcher = FakeLinkLauncher();
  });

  VersionGate gate({String? current = '1.0.0', String? platform = 'ios'}) =>
      VersionGate(
        db: db,
        remote: config,
        clock: clock,
        launcher: launcher,
        currentVersion: current,
        platform: platform,
      );

  void serve(String min, {String? url}) =>
      config.rows['ios'] = MinVersionConfig(version: min, storeUrl: url);

  group('decision', () {
    test('older than the minimum is blocked', () async {
      serve('1.1.0');
      final s = await gate().check();
      expect(s.blocked, isTrue);
      expect(s.current, '1.0.0');
      expect(s.min, '1.1.0');
    });

    test('equal to the minimum is allowed', () async {
      serve('1.0.0');
      expect((await gate().check()).blocked, isFalse);
    });

    test('newer than the minimum is allowed', () async {
      serve('0.9.9');
      final s = await gate().check();
      expect(s.blocked, isFalse);
      expect(s.min, '0.9.9');
    });

    test('compares numbers, not text (1.10.0 is newer than 1.9.0)', () async {
      serve('1.9.0');
      expect((await gate(current: '1.10.0').check()).blocked, isFalse);
    });

    test('the seeded 0.0.0 blocks nobody', () async {
      serve('0.0.0');
      expect((await gate(current: '0.0.1').check()).blocked, isFalse);
    });

    test('a build suffix of the own version is ignored', () async {
      serve('1.0.0');
      expect((await gate(current: '1.0.0+7').check()).blocked, isFalse);
    });

    test('an update unblocks at once, without a new request', () async {
      serve('1.1.0');
      expect((await gate().check()).blocked, isTrue);
      final after = await gate(current: '1.1.0').check();
      expect(after.blocked, isFalse);
      expect(config.calls, 1);
    });
  });

  group('fail open (nothing failed for the user, so nothing is shown)', () {
    test('offline without a cache is not blocked', () async {
      config.offline = true;
      final s = await gate().check();
      expect(s.blocked, isFalse);
      expect(s.min, isNull);
    });

    test('a server error is not blocked', () async {
      config.fail = const ServerDown();
      expect((await gate().check()).blocked, isFalse);
    });

    test('no row for the platform is not blocked', () async {
      expect((await gate().check()).blocked, isFalse);
    });

    for (final bad in ['', 'abc', '1.2', '1.2.3-beta', '-1.0.0', '1.2.3.4']) {
      test('a malformed minimum "$bad" is not blocked', () async {
        serve(bad);
        final s = await gate().check();
        expect(s.blocked, isFalse);
        expect(s.min, isNull);
      });
    }

    test('an unreadable own version is not blocked and asks nothing', () async {
      serve('9.0.0');
      expect((await gate(current: null).check()).blocked, isFalse);
      expect((await gate(current: 'dev').check()).blocked, isFalse);
      expect(config.calls, 0);
    });

    test('a platform without a store (Linux harness) is never gated', () async {
      serve('9.0.0');
      expect((await gate(platform: null).check()).blocked, isFalse);
      expect(config.calls, 0);
    });

    test('offline after a blocked answer stays blocked', () async {
      serve('1.1.0');
      await gate().check();
      clock.advance(const Duration(days: 3));
      config.offline = true;
      expect((await gate().check()).blocked, isTrue);
    });
  });

  group('cache window (Clock)', () {
    test('asks once, then uses the stored answer for 12 hours', () async {
      serve('0.0.0');
      await gate().check();
      clock.advance(const Duration(hours: 11, minutes: 59));
      // A new object, as after an app restart: the cache is in local_settings.
      await gate().check();
      expect(config.calls, 1);
    });

    test('asks again after 12 hours and sees the new minimum', () async {
      serve('0.0.0');
      expect((await gate().check()).blocked, isFalse);
      serve('2.0.0');
      clock.advance(versionGateCacheTtl);
      expect((await gate().check()).blocked, isTrue);
      expect(config.calls, 2);
    });

    test('a raised minimum is not seen inside the window', () async {
      serve('0.0.0');
      await gate().check();
      serve('2.0.0');
      clock.advance(const Duration(hours: 1));
      expect((await gate().check()).blocked, isFalse);
    });

    test('force asks again inside the window', () async {
      serve('0.0.0');
      await gate().check();
      serve('2.0.0');
      expect((await gate().check(force: true)).blocked, isTrue);
      expect(config.calls, 2);
    });

    test('a clock set back does not make the cache last forever', () async {
      serve('0.0.0');
      await gate().check();
      clock.value = clock.value.subtract(const Duration(days: 30));
      await gate().check();
      expect(config.calls, 2);
    });

    test('a failed refresh keeps the old answer and tries again', () async {
      serve('0.0.0');
      await gate().check();
      clock.advance(const Duration(days: 1));
      config.offline = true;
      await gate().check();
      await gate().check();
      expect(config.calls, 3);
    });

    test('a missing row is cached too (no request on every sync)', () async {
      await gate().check();
      await gate().check();
      expect(config.calls, 1);
    });

    test('an unreadable cache stamp is a cache miss', () async {
      serve('0.0.0');
      await gate().check();
      await db.syncStateDao.putSetting(versionGateCheckedAtSetting, 'garbage');
      await gate().check();
      expect(config.calls, 2);
    });

    test('concurrent checks share one request', () async {
      serve('0.0.0');
      final g = gate();
      await Future.wait([g.check(), g.check(), g.check()]);
      expect(config.calls, 1);
    });
  });

  group('store link', () {
    test('the server link is used when it is https', () async {
      serve('2.0.0', url: 'https://apps.apple.com/app/id42');
      expect(
        (await gate().check()).storeUrl,
        'https://apps.apple.com/app/id42',
      );
    });

    for (final bad in [
      'javascript:alert(1)',
      'http://example.com',
      'not a url',
      'https://',
      '',
    ]) {
      test('a link that is not usable ("$bad") falls back', () async {
        serve('2.0.0', url: bad);
        expect(
          (await gate().check()).storeUrl,
          fallbackStoreUrls['ios'],
        );
      });
    }

    test('no link falls back per platform', () async {
      config.rows['android'] = const MinVersionConfig(version: '2.0.0');
      expect(
        (await gate(platform: 'android').check()).storeUrl,
        fallbackStoreUrls['android'],
      );
      expect(fallbackStoreUrls.keys, unorderedEquals(['ios', 'android']));
    });

    test('openStore opens the link in the store app', () async {
      serve('2.0.0', url: 'https://apps.apple.com/app/id42');
      expect(await gate().openStore(), isTrue);
      expect(launcher.launched, [Uri.parse('https://apps.apple.com/app/id42')]);
    });

    test('openStore says false when nothing can open it', () async {
      serve('2.0.0');
      launcher.canLaunch = false;
      expect(await gate().openStore(), isFalse);
    });

    test('openStore without a store link (no platform) is false', () async {
      expect(await gate(platform: null).openStore(), isFalse);
      expect(launcher.launched, isEmpty);
    });
  });

  group('state value', () {
    test('equality and text', () {
      const a = VersionGateState(
        current: '1.0.0',
        min: '1.1.0',
        blocked: true,
        storeUrl: 'u',
      );
      const same = VersionGateState(
        current: '1.0.0',
        min: '1.1.0',
        blocked: true,
        storeUrl: 'u',
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(const VersionGateState.open(current: '1.0.0')));
      expect(a.toString(), contains('blocked: true'));
    });
  });

  group('SyncService: blocks sync only', () {
    late String groupId;
    late FakeSyncRemote server;

    Future<SyncService> service(VersionGate? g) async => SyncService(
      db: db,
      remote: server,
      clock: clock,
      random: _NoRandom(),
      ids: SequentialIdGenerator(prefix: 'v'),
      gate: g,
    );

    setUp(() async {
      server = FakeSyncRemote();
      final seeded = await seedGroup(r);
      groupId = seeded.groupId;
      await db.syncStateDao.setState(
        groupId,
        SyncState.shared,
        role: SyncRole.owner,
      );
      final writer = OutboxWriter(
        db: db,
        clock: r.clock,
        ids: SequentialIdGenerator(prefix: 'w'),
      );
      // The group and the membership are on the server (as after sharing);
      // the members are what waits in the outbox.
      await writer.enqueue(OutboxEntity.group, groupId);
      expect(await (await service(null)).push(groupId), const SyncIdle());
      expect(
        await server.bootstrapMembership(groupId),
        const Ok<bool, RemoteError>(true),
      );
      server.received.clear();
      server.calls = 0;
      for (final m in seeded.members) {
        await writer.enqueue(OutboxEntity.member, m.id);
      }
      clock = FixedClock(DateTime.utc(2026, 11));
    });

    test('a blocked app neither pushes nor pulls and says why', () async {
      serve('1.1.0');
      final s = await service(gate());
      final before = (await db.syncStateDao.outboxOf(groupId)).length;

      expect(await s.push(groupId), const SyncError(VersionTooOld()));
      expect(await s.pull(groupId), const SyncError(VersionTooOld()));
      expect(server.calls, 0);
      expect(await db.syncStateDao.outboxOf(groupId), hasLength(before));
      expect(
        (await db.syncStateDao.groupSync(groupId))?.lastErrorCode,
        'versionTooOld',
      );
    });

    test('local data stays usable while blocked', () async {
      serve('1.1.0');
      await (await service(gate())).push(groupId);
      expect(ok(await r.members.list(groupId)), hasLength(3));
      ok(await r.members.add(groupId, name: 'Dee'));
      expect(ok(await r.members.list(groupId)), hasLength(4));
    });

    test('after the update the queued changes go out', () async {
      serve('1.1.0');
      expect(
        await (await service(gate())).push(groupId),
        const SyncError(VersionTooOld()),
      );
      final updated = await service(gate(current: '1.1.0'));
      expect(await updated.push(groupId), const SyncIdle());
      expect(await updated.pull(groupId), const SyncIdle());
      expect(server.received, isNotEmpty);
      expect(
        (await db.syncStateDao.groupSync(groupId))?.lastErrorCode,
        isNull,
      );
    });

    test('an allowed app syncs as before', () async {
      serve('1.0.0');
      expect(
        await (await service(gate())).push(groupId),
        const SyncIdle(),
      );
    });

    test('a removed group is left alone (no error recorded)', () async {
      serve('1.1.0');
      await db.syncStateDao.setState(groupId, SyncState.removed);
      final s = await service(gate());
      await s.push(groupId);
      await s.pull(groupId);
      expect(
        (await db.syncStateDao.groupSync(groupId))?.lastErrorCode,
        isNull,
      );
    });

    test('without a gate nothing changes', () async {
      expect(await (await service(null)).push(groupId), const SyncIdle());
    });

    test('every group of a blocked app shows the error', () async {
      serve('1.1.0');
      final second = ok(
        await r.groups.create(name: 'Two', currency: eur, createdBy: 'dev'),
      );
      await db.syncStateDao.setState(
        second.id,
        SyncState.shared,
        role: SyncRole.member,
      );
      final s = await service(gate());
      await s.push(groupId);
      await s.push(second.id);
      expect(await s.status(groupId), const SyncError(VersionTooOld()));
      expect(await s.status(second.id), const SyncError(VersionTooOld()));
    });
  });

  group('ShareGroupRepository: a blocked app does not start a share', () {
    test('says versionTooOld, does not sign in or touch the server', () async {
      final seeded = await seedGroup(r);
      serve('1.1.0');
      final server = FakeSyncRemote();
      final auth = FakeAuthService();
      final ids = SequentialIdGenerator(prefix: 's');
      final g = gate();
      final share = ShareGroupRepository(
        db: db,
        auth: AuthRepository(auth),
        remote: server,
        sync: SyncService(
          db: db,
          remote: server,
          clock: clock,
          random: _NoRandom(),
          ids: ids,
          gate: g,
        ),
        clock: clock,
        ids: ids,
        gate: g,
      );
      final result = await share.makeShared(seeded.groupId);
      expect(
        result,
        isA<Err<ShareProgress, ShareError>>().having(
          (e) => e.error,
          'error',
          isA<ShareUploadFailed>().having(
            (f) => f.error,
            'error',
            const VersionTooOld(),
          ),
        ),
      );
      expect(server.calls, 0);
      expect(await db.syncStateDao.groupSync(seeded.groupId), isNull);
    });
  });
}
