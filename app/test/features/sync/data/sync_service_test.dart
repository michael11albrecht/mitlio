import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/outbox_writer.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  int nextInt(int max) => (value * max).floor();
}

/// Plays the real world: a newer write replaces the op while it is in flight,
/// or the answer gets lost after the server stored the row.
class _MeddlingRemote extends FakeSyncRemote {
  /// Runs after the server stored a row of this table, before the answer.
  Future<void> Function(String table)? whileInFlight;

  /// Lose the next answers after the server applied them.
  int loseAnswers = 0;

  @override
  Future<Result<PushOutcome, RemoteError>> upsertRows(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    final result = await super.upsertRows(table, rows);
    final hook = whileInFlight;
    if (hook != null) {
      whileInFlight = null;
      await hook(table);
    }
    if (loseAnswers > 0 && result is Ok) {
      loseAnswers--;
      return const Err(Offline());
    }
    return result;
  }
}

class _World {
  _World._(this.r, this.groupId, this.m, this.car, this.remote, this.service);

  final Repos r;
  final String groupId;
  final List<GroupMember> m;
  final Vehicle car;
  final FakeSyncRemote remote;
  final SyncService service;

  AppDatabase get db => r.db!;
  FixedClock get clock => r.clock;

  Future<List<LocalOutboxRow>> outbox() => db.syncStateDao.outboxOf(groupId);

  Future<LocalGroupSyncRow?> sync() => db.syncStateDao.groupSync(groupId);

  Future<SyncStatus> push() => service.push(groupId);

  ExpenseDraft draft(
    String payer, {
    String title = 'Dinner',
    int cents = 3000,
    Set<String>? among,
  }) => ExpenseDraft(
    title: title,
    amountCents: cents,
    currency: eur,
    date: DateTime.utc(2026, 3),
    payers: {payer: cents},
    split: EqualSplit(among ?? {for (final x in m) x.id}),
    category: 'food',
  );

  static Future<_World> create({
    FakeSyncRemote? remote,
    double jitter = 0.5,
    bool uploaded = true,
  }) async {
    final r = await driftRepos();
    final seeded = await seedGroup(r);
    final car = ok(
      await r.vehicles.add(
        seeded.groupId,
        name: 'Golf',
        fuelType: FuelType.diesel,
        consumptionMilliPer100km: 5500,
        wearMilliPerKm: 80,
        kmRateMilliPerKm: 300,
      ),
    );
    final db = r.db!;
    await db.syncStateDao.setState(
      seeded.groupId,
      SyncState.uploading,
      role: SyncRole.owner,
    );
    final fake = remote ?? FakeSyncRemote();
    final world = _World._(
      r,
      seeded.groupId,
      seeded.members,
      car,
      fake,
      SyncService(
        db: db,
        remote: fake,
        clock: r.clock,
        random: _FixedRandom(jitter),
      ),
    );
    if (uploaded) {
      // What "share this group" will do (#163): queue everything, push once.
      final writer = OutboxWriter(
        db: db,
        clock: r.clock,
        ids: SequentialIdGenerator(prefix: 'upload'),
      );
      await writer.enqueue(OutboxEntity.group, seeded.groupId);
      for (final x in seeded.members) {
        await writer.enqueue(OutboxEntity.member, x.id);
      }
      await writer.enqueue(OutboxEntity.vehicle, car.id);
      final status = await world.push();
      expect(status, const SyncIdle());
      fake.received.clear();
    }
    return world;
  }
}

/// The FK order derived from the real schema, so a new foreign key that
/// breaks [pushRank] fails here.
Map<String, Set<String>> _parentsFromSql() {
  final sql = File('../supabase/migrations/0001_core.sql').readAsStringSync();
  final parents = <String, Set<String>>{};
  final table = RegExp(
    r'create table public\.(\w+) \((.*?)\n\);',
    dotAll: true,
  );
  final ref = RegExp(r'references public\.(\w+)');
  for (final t in table.allMatches(sql)) {
    parents[t.group(1)!] = {
      for (final m in ref.allMatches(t.group(2)!)) m.group(1)!,
    };
  }
  return parents;
}

void main() {
  group('push order', () {
    test('pushRank puts every parent before its children (from the SQL)', () {
      final parents = _parentsFromSql();
      expect(parents[DbTables.rides], contains(DbTables.expenses));
      var checked = 0;
      for (final MapEntry(key: child, value: ps) in parents.entries) {
        final childRank = pushRank[child];
        if (childRank == null) continue; // not pushed row by row
        for (final p in ps) {
          final parentRank = pushRank[p];
          if (parentRank == null) continue;
          expect(
            parentRank,
            lessThan(childRank),
            reason: '$child references $p, so $p must be pushed first',
          );
          checked++;
        }
      }
      expect(checked, greaterThan(8));
      expect(pushRank.keys.toSet(), {
        for (final e in OutboxEntity.values) e.table,
      });
    });

    test('sends by entity rank, then queue order', () async {
      final w = await _World.create(uploaded: false);
      final writer = OutboxWriter(
        db: w.db,
        clock: w.clock,
        ids: SequentialIdGenerator(prefix: 'q'),
      );
      // Queue in the worst order: leaves first.
      final created = ok(
        await w.r.expenses.create(w.groupId, w.draft(w.m[0].id)),
      );
      await writer.enqueue(OutboxEntity.expense, created.expense.id);
      await writer.enqueue(OutboxEntity.vehicle, w.car.id);
      await writer.enqueue(OutboxEntity.member, w.m[2].id);
      await writer.enqueue(OutboxEntity.member, w.m[1].id);
      await writer.enqueue(OutboxEntity.member, w.m[0].id);
      await writer.enqueue(OutboxEntity.group, w.groupId);

      expect(await w.push(), const SyncIdle());
      expect(w.remote.received, [
        '${DbTables.groups}:${w.groupId}',
        '${DbTables.members}:${w.m[2].id}',
        '${DbTables.members}:${w.m[1].id}',
        '${DbTables.members}:${w.m[0].id}',
        '${DbTables.vehicles}:${w.car.id}',
        '${DbTables.expenses}:${created.expense.id}',
      ]);
      expect(await w.outbox(), isEmpty);
    });

    test(
      'a member renamed after its expense is still sent before the expense',
      () async {
        final w = await _World.create();
        final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
        final e = ok(
          await w.r.expenses.create(
            w.groupId,
            w.draft(dan.id, among: {dan.id, w.m[0].id}),
          ),
        );
        ok(await w.r.members.update(dan.id, name: 'Daniel'));

        // Coalescing moved the member op behind the expense op.
        final queue = [for (final o in await w.outbox()) o.entityId];
        expect(queue.indexOf(e.expense.id), lessThan(queue.indexOf(dan.id)));

        expect(await w.push(), const SyncIdle());
        expect(w.remote.received, [
          '${DbTables.members}:${dan.id}',
          '${DbTables.expenses}:${e.expense.id}',
        ]);
        expect(
          w.remote.row(DbTables.members, dan.id)![DbMembersCols.name],
          'Daniel',
        );
        expect(await w.outbox(), isEmpty);
        expect((await w.sync())!.lastErrorCode, isNull);
      },
    );

    test('a settled ride goes after the expense it points at', () async {
      final w = await _World.create();
      for (final id in ['r1', 'r2']) {
        ok(
          await w.r.rides.log(
            w.groupId,
            Ride(
              id: id,
              date: DateTime.utc(2026, 3, 2),
              distanceMeters: 12000,
              roundTrip: true,
              vehicleId: w.car.id,
              driverId: w.m[0].id,
              passengerIds: {w.m[1].id},
              driverCounts: false,
              pricePerUnitMilli: 1700,
              useKmRate: true,
            ),
          ),
        );
      }
      final expenses = ok(
        await w.r.rides.settlePeriod(w.groupId, [
          PeriodSettlement(
            rideIds: const ['r1', 'r2'],
            draft: w.draft(w.m[0].id, title: 'Rides', cents: 600),
          ),
        ]),
      );
      final expenseId = expenses.single.expense.id;

      expect(await w.push(), const SyncIdle());
      final sent = w.remote.received;
      expect(
        sent.indexOf('${DbTables.expenses}:$expenseId'),
        lessThan(sent.indexOf('${DbTables.rides}:r1')),
      );
      expect(
        w.remote.row(DbTables.rides, 'r1')![DbRidesCols.settledExpenseId],
        expenseId,
      );
    });
  });

  group('success', () {
    test('deletes the op, stamps lastPushAt, status idle', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      expect(await w.service.status(w.groupId), const SyncPending(1));
      w.clock.advance(const Duration(minutes: 1));
      expect(await w.push(), const SyncIdle());
      expect(await w.outbox(), isEmpty);
      expect((await w.sync())!.lastPushAt, w.clock.now());
    });

    test('a local-only or removed group never calls the server', () async {
      final w = await _World.create();
      expect(await w.service.push('unknown-group'), const SyncIdle());
      await w.db.syncStateDao.setState(w.groupId, SyncState.removed);
      expect(await w.push(), const SyncIdle());
      expect(w.remote.calls, greaterThan(0)); // only the initial upload
      final calls = w.remote.calls;
      await w.push();
      expect(w.remote.calls, calls);
    });

    test('concurrent pushes send every op once', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      final results = await Future.wait([w.push(), w.push(), w.push()]);
      expect(results, everyElement(const SyncIdle()));
      expect(w.remote.received, hasLength(1));
    });
  });

  group('idempotent', () {
    test('a lost answer is retried and the server still has one row', () async {
      final remote = _MeddlingRemote();
      final w = await _World.create(remote: remote);
      final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
      remote.loseAnswers = 1;
      expect(await w.push(), isA<SyncError>());
      expect((await w.outbox()).single.entityId, dan.id);
      expect(remote.count(DbTables.members), 4); // 3 seeded + Dan

      w.clock.advance(const Duration(minutes: 1));
      expect(await w.push(), const SyncIdle());
      expect(remote.count(DbTables.members), 4);
      expect(await w.outbox(), isEmpty);
    });
  });

  group('an op replaced while in flight', () {
    test('only the sent op_id is deleted, the newer one stays', () async {
      final remote = _MeddlingRemote();
      final w = await _World.create(remote: remote);
      final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
      final sentOp = (await w.outbox()).single;
      remote.whileInFlight = (table) async {
        ok(await w.r.members.update(dan.id, name: 'Daniel'));
        remote.offline = true; // the newer op cannot go out yet
      };

      final status = await w.push();
      expect(status, const SyncError(Offline()));
      final left = (await w.outbox()).single;
      expect(left.opId, isNot(sentOp.opId));
      expect(
        (jsonDecode(left.payload) as Map<String, Object?>)[DbMembersCols.name],
        'Daniel',
      );
      expect(
        remote.row(
          DbMembersCols.id == 'id' ? DbTables.members : '',
          dan.id,
        )![DbMembersCols.name],
        'Dan',
      );

      remote.offline = false;
      w.clock.advance(const Duration(minutes: 1));
      expect(await w.push(), const SyncIdle());
      expect(
        remote.row(DbTables.members, dan.id)![DbMembersCols.name],
        'Daniel',
      );
    });

    test(
      'a failure of the replaced op does not penalise the new one',
      () async {
        final remote = _MeddlingRemote();
        final w = await _World.create(remote: remote);
        final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
        remote
          ..loseAnswers = 1
          ..whileInFlight = (table) async {
            ok(await w.r.members.update(dan.id, name: 'Daniel'));
          };

        expect(await w.push(), const SyncError(Offline()));
        final left = (await w.outbox()).single;
        expect(
          (jsonDecode(left.payload)
              as Map<String, Object?>)[DbMembersCols.name],
          'Daniel',
        );
        expect(left.attempts, 0);
        expect(left.nextAttemptAt, isNull);
        expect(left.lastErrorCode, isNull);
      },
    );
  });

  group('retry with backoff', () {
    test('the schedule doubles with jitter and caps at 5 minutes', () async {
      final w = await _World.create(); // jitter 0.5 -> 75 % of the base
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.remote.offline = true;
      final delays = <Duration>[];
      for (var i = 0; i < 10; i++) {
        final before = w.clock.now();
        await w.push();
        final op = (await w.outbox()).single;
        expect(op.attempts, i + 1);
        expect(op.lastErrorCode, 'offline');
        delays.add(op.nextAttemptAt!.difference(before));
        w.clock.value = op.nextAttemptAt!;
      }
      expect(delays.map((d) => d.inMilliseconds / 1000), [
        1.5, 3, 6, 12, 24, 48, 96, 192, 225, 225, //
      ]);
      expect(delays.every((d) => d <= const Duration(minutes: 5)), isTrue);
    });

    test('jitter spans half to full of the delay', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      Duration first(double jitter) {
        final svc = SyncService(
          db: db,
          remote: FakeSyncRemote(),
          clock: FixedClock(DateTime.utc(2026)),
          random: _FixedRandom(jitter),
        );
        return svc.backoff(1);
      }

      expect(first(0), const Duration(seconds: 1));
      expect(first(0.999999).inMilliseconds, inInclusiveRange(1990, 2000));
    });

    test('nothing is sent before the retry is due, then it recovers', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.remote.offline = true;

      final status = await w.push();
      expect(status, const SyncError(Offline()));
      expect((await w.sync())!.lastErrorCode, 'offline');
      final calls = w.remote.calls;

      // Network flaps: still waiting for the backoff, no call goes out.
      w.remote.offline = false;
      expect(await w.push(), const SyncError(Offline()));
      expect(w.remote.calls, calls);

      w.clock.advance(const Duration(seconds: 2));
      expect(await w.push(), const SyncIdle());
      expect((await w.sync())!.lastErrorCode, isNull);
      expect(await w.outbox(), isEmpty);
    });

    test('a failing op holds back the ops that may depend on it', () async {
      final w = await _World.create();
      final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
      ok(
        await w.r.expenses.create(
          w.groupId,
          w.draft(dan.id, among: {dan.id, w.m[0].id}),
        ),
      );
      final before = w.remote.calls;
      w.remote.failNext(const ServerDown());
      await w.push();
      expect(w.remote.calls, before + 1); // only the member call went out
      expect(await w.outbox(), hasLength(2));

      w.clock.advance(const Duration(seconds: 3));
      expect(await w.push(), const SyncIdle());
      expect(w.remote.received.first, startsWith(DbTables.members));
    });

    test('5xx is kept, counted and shown as serverDown', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.remote.fail = const ServerDown();
      expect(await w.push(), const SyncError(ServerDown()));
      expect((await w.outbox()).single.lastErrorCode, 'serverDown');
    });

    test('an app that is too old keeps its ops and says so', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.remote.failNext(const VersionTooOld());
      expect(await w.push(), const SyncError(VersionTooOld()));
      expect(await w.outbox(), hasLength(1));
    });
  });

  group('rate limited', () {
    test('waits the hinted time and shows it', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.remote.failNext(const RateLimitedRemote(Duration(minutes: 3)));
      final started = w.clock.now();

      final status = await w.push();
      expect(status, const SyncError(RateLimitedRemote(Duration(minutes: 3))));
      expect(
        (await w.outbox()).single.nextAttemptAt,
        started.add(const Duration(minutes: 3)),
      );
      expect(
        remoteErrorText(AppLocalizationsDe(), (status as SyncError).error),
        'Zu viele Versuche. Versuch es in 3 Min. nochmal.',
      );
      expect(
        remoteErrorText(AppLocalizationsEn(), status.error),
        contains('3'),
      );

      final calls = w.remote.calls;
      w.clock.advance(const Duration(minutes: 2, seconds: 59));
      await w.push();
      expect(w.remote.calls, calls);

      w.clock.advance(const Duration(seconds: 1));
      expect(await w.push(), const SyncIdle());
    });

    test('without a hint it backs off like any retry', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.remote.failNext(const RateLimitedRemote(null));
      final started = w.clock.now();
      final status = await w.push();
      expect(status, const SyncError(RateLimitedRemote(null)));
      expect(
        (await w.outbox()).single.nextAttemptAt,
        started.add(const Duration(milliseconds: 1500)),
      );
      expect(
        remoteErrorText(AppLocalizationsDe(), (status as SyncError).error),
        'Zu viele Versuche. Versuch es in ein paar Minuten nochmal.',
      );
    });

    test('the wait survives a restart as a rate-limit error', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.remote.failNext(const RateLimitedRemote(Duration(minutes: 3)));
      await w.push();
      final restarted = SyncService(
        db: w.db,
        remote: w.remote,
        clock: w.clock,
        random: _FixedRandom(0.5),
      );
      expect(
        await restarted.status(w.groupId),
        const SyncError(RateLimitedRemote(null)),
      );
    });
  });

  group('refused for good (4xx)', () {
    test(
      'drops the op, surfaces code and title, keeps pushing the rest',
      () async {
        final w = await _World.create();
        final e = ok(await w.r.expenses.create(w.groupId, w.draft(w.m[0].id)));
        ok(await w.r.members.add(w.groupId, name: 'Dan'));
        // Dan (a member) is sent before the expense and takes the refusal.
        w.remote.failNext(const Rejected('check_violation'));
        final status = await w.push();

        expect(w.remote.row(DbTables.expenses, e.expense.id), isNotNull);
        expect(await w.outbox(), isEmpty);
        final sync = (await w.sync())!;
        expect(sync.lastErrorCode, 'rejected:check_violation');
        expect(sync.lastErrorAt, w.clock.now());
        expect(
          status,
          const SyncError(Rejected('check_violation'), title: 'Dan'),
        );
      },
    );

    test('shows the expense title in de and en', () async {
      final w = await _World.create();
      ok(
        await w.r.expenses.create(
          w.groupId,
          w.draft(w.m[0].id, title: 'Pizza'),
        ),
      );
      w.remote.failNext(const Rejected('payers_sum_mismatch'));
      final status = await w.push() as SyncError;

      expect(status.title, 'Pizza');
      expect(
        remoteErrorText(
          AppLocalizationsDe(),
          status.error,
          title: status.title,
        ),
        '„Pizza“ konnte nicht geteilt werden. Sie ist nur auf diesem Handy.',
      );
      expect(
        remoteErrorText(
          AppLocalizationsEn(),
          status.error,
          title: status.title,
        ),
        '“Pizza” could not be shared. It is only on this phone.',
      );
      expect(await w.outbox(), isEmpty);
    });

    test('a later successful push does not hide the refusal', () async {
      final w = await _World.create();
      ok(
        await w.r.expenses.create(
          w.groupId,
          w.draft(w.m[0].id, title: 'Pizza'),
        ),
      );
      w.remote.failNext(const Rejected('payers_sum_mismatch'));
      await w.push();

      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.clock.advance(const Duration(minutes: 1));
      final status = await w.push();
      expect(status, isA<SyncError>());
      final sync = (await w.sync())!;
      expect(sync.lastErrorCode, 'rejected:payers_sum_mismatch');
      expect(sync.lastPushAt, w.clock.now());
    });

    test('other server refusals are stored under their case name', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      w.remote.failNext(const NotOwner());
      expect(
        await w.push(),
        const SyncError(Rejected('notOwner'), title: 'Dan'),
      );
      expect(await w.outbox(), isEmpty);
    });
  });

  group('stale writes', () {
    test('are dropped quietly: the next pull brings the newer row', () async {
      final w = await _World.create();
      final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
      // Someone else already wrote a newer version of Dan.
      await w.remote.upsertRows(DbTables.members, [
        {
          DbMembersCols.id: dan.id,
          DbMembersCols.groupId: w.groupId,
          DbMembersCols.name: 'Other',
          DbMembersCols.position: 3,
          DbMembersCols.canDrive: true,
          DbMembersCols.createdAt: '2026-03-01T00:00:00.000Z',
          DbMembersCols.updatedAt: '9999-12-31T00:00:00.000Z-0000-z',
        },
      ]);
      expect(await w.push(), const SyncIdle());
      expect(await w.outbox(), isEmpty);
      expect((await w.sync())!.lastErrorCode, isNull);
      expect(
        w.remote.row(DbTables.members, dan.id)![DbMembersCols.name],
        'Other',
      );
    });

    test('a stale expense (applied=false) is dropped quietly', () async {
      final w = await _World.create();
      final e = ok(await w.r.expenses.create(w.groupId, w.draft(w.m[0].id)));
      await w.push();
      final again = ok(
        await w.r.expenses.update(
          e.expense.id,
          w.draft(w.m[0].id, title: 'Edit'),
        ),
      );
      expect(again.expense.id, e.expense.id);
      final payload =
          jsonDecode((await w.outbox()).single.payload) as Map<String, Object?>;
      // The server meanwhile got a newer HLC.
      w.remote.row(DbTables.expenses, e.expense.id)![DbExpensesCols.updatedAt] =
          '9999-12-31T00:00:00.000Z-0000-z';
      expect(payload[DbExpensesCols.title], 'Edit');
      expect(await w.push(), const SyncIdle());
      expect(await w.outbox(), isEmpty);
    });
  });

  group('removed from the group', () {
    test('notMember stops the group, keeps data and ops, says why', () async {
      final w = await _World.create();
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      ok(await w.r.expenses.create(w.groupId, w.draft(w.m[0].id)));
      w.remote.removeMember(w.groupId);

      final status = await w.push();
      expect(status, const SyncError(NotMember()));
      final sync = (await w.sync())!;
      expect(sync.state, SyncState.removed.name);
      expect(sync.lastErrorCode, 'notMember');
      expect(await w.outbox(), hasLength(2)); // nothing thrown away
      expect(await w.r.groups.get(w.groupId), isNotNull);
      expect(
        remoteErrorText(AppLocalizationsDe(), (status as SyncError).error),
        'Du bist nicht mehr in dieser Gruppe. '
        'Deine Daten bleiben auf diesem Handy.',
      );
      expect(
        remoteErrorText(AppLocalizationsEn(), status.error),
        contains('phone'),
      );

      final calls = w.remote.calls;
      w.remote.addMember(w.groupId);
      expect(await w.push(), const SyncError(NotMember()));
      expect(w.remote.calls, calls); // no more pushing
    });
  });

  group('status stream', () {
    test('pending, syncing, idle and errors reach the listener', () async {
      final w = await _World.create();
      final seen = <SyncStatus>[];
      final sub = w.service.watchStatus(w.groupId).listen(seen.add);
      await pumpEventQueue();
      expect(seen.last, const SyncIdle());

      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      await pumpEventQueue();
      expect(seen.last, const SyncPending(1));

      w.remote.offline = true;
      await w.push();
      await pumpEventQueue();
      expect(seen.last, const SyncError(Offline()));

      w.remote.offline = false;
      w.clock.advance(const Duration(minutes: 1));
      await w.push();
      await pumpEventQueue();
      expect(seen.last, const SyncIdle());
      expect(seen, contains(const SyncSyncing()));
      await sub.cancel();
    });
  });

  group('status value types', () {
    test('equality and printing', () {
      expect(const SyncPending(2), const SyncPending(2));
      expect(const SyncPending(2), isNot(const SyncPending(3)));
      expect(const SyncIdle().hashCode, const SyncIdle().hashCode);
      expect(const SyncSyncing().hashCode, const SyncSyncing().hashCode);
      expect(const SyncPending(2).hashCode, const SyncPending(2).hashCode);
      expect(
        const SyncError(Offline(), title: 'a').hashCode,
        const SyncError(Offline(), title: 'a').hashCode,
      );
      expect(const SyncIdle().toString(), 'SyncIdle()');
      expect(const SyncSyncing().toString(), 'SyncSyncing()');
      expect(const SyncPending(2).toString(), 'SyncPending(2)');
      expect(const SyncError(Offline()).toString(), contains('Offline'));
    });
  });
}
