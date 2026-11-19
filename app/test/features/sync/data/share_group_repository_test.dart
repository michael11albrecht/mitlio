import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/outbox_writer.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_error_text.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

class _NoRandom implements Random {
  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

/// Fails every row write after [failAfterWrites] successful ones.
class _FlakyRemote extends FakeSyncRemote {
  int writes = 0;
  int? failAfterWrites;
  RemoteError failWith = const ServerDown();

  bool get _broken => failAfterWrites != null && writes >= failAfterWrites!;

  @override
  Future<Result<PushOutcome, RemoteError>> upsertRows(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    if (_broken) return Err(failWith);
    writes++;
    return super.upsertRows(table, rows);
  }

  @override
  Future<Result<PushOutcome, RemoteError>> upsertExpense(
    Map<String, Object?> payload,
  ) async {
    if (_broken) return Err(failWith);
    writes++;
    return super.upsertExpense(payload);
  }
}

class _World {
  _World._(this.r, this.groupId, this.m, this.remote, this.auth);

  final Repos r;
  final String groupId;
  final List<GroupMember> m;
  final _FlakyRemote remote;
  final FakeAuthService auth;

  AppDatabase get db => r.db!;

  /// A new set of objects on the same database and server: "app restarted".
  ShareGroupRepository share() {
    final ids = SequentialIdGenerator(prefix: 'share${_boots++}');
    return ShareGroupRepository(
      db: db,
      auth: AuthRepository(auth),
      remote: remote,
      sync: SyncService(
        db: db,
        remote: remote,
        clock: r.clock,
        random: _NoRandom(),
        ids: ids,
      ),
      clock: r.clock,
      ids: ids,
    );
  }

  int _boots = 0;

  Future<LocalGroupSyncRow?> sync() => db.syncStateDao.groupSync(groupId);

  Future<int> pending() => db.syncStateDao.pendingOutboxCount(groupId);

  /// Every local row of every table, as JSON, to prove nothing changed.
  Future<String> snapshot() async {
    final out = <String, Object?>{};
    for (final t in db.allTables) {
      if (t.actualTableName.startsWith('local_')) continue;
      final rows = await db
          .customSelect('select * from ${t.actualTableName} order by 1')
          .get();
      out[t.actualTableName] = [for (final row in rows) row.data];
    }
    return jsonEncode(out);
  }

  static Future<_World> create({bool rich = true}) async {
    final r = await driftRepos();
    final seeded = await seedGroup(r);
    final m = seeded.members;
    if (rich) {
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
      ok(
        await r.rideTemplates.add(
          seeded.groupId,
          RideTemplate(
            id: 'tpl',
            name: 'Work',
            distanceMeters: 12000,
            vehicleId: car.id,
            defaultDriverId: m[0].id,
            defaultPassengerIds: {m[1].id},
          ),
        ),
      );
      ExpenseDraft draft(String title, int cents) => ExpenseDraft(
        title: title,
        amountCents: cents,
        currency: eur,
        date: DateTime.utc(2026, 3),
        payers: {m[0].id: cents},
        split: EqualSplit({for (final x in m) x.id}),
        category: 'food',
      );
      final keep = ok(
        await r.expenses.create(seeded.groupId, draft('Pizza', 3000)),
      );
      final gone = ok(
        await r.expenses.create(seeded.groupId, draft('Oops', 900)),
      );
      ok(await r.expenses.softDelete(gone.expense.id));
      ok(
        await r.rides.log(
          seeded.groupId,
          Ride(
            id: 'ride-1',
            date: DateTime.utc(2026, 3, 2),
            distanceMeters: 12000,
            roundTrip: true,
            vehicleId: car.id,
            driverId: m[0].id,
            passengerIds: {m[1].id},
            driverCounts: false,
            pricePerUnitMilli: 1700,
            useKmRate: true,
          ),
        ),
      );
      final settlement = ok(
        await r.settlements.create(
          seeded.groupId,
          SettlementDraft(
            fromId: m[1].id,
            toId: m[0].id,
            amountCents: 500,
            currency: eur,
            date: DateTime.utc(2026, 3, 5),
            method: SettlementMethod.cash,
          ),
        ),
      );
      ok(await r.settlements.softDelete(settlement.settlement.id));
      final dan = ok(await r.members.add(seeded.groupId, name: 'Dan'));
      ok(await r.members.softDelete(dan.id));
      expect(keep.expense.id, isNotEmpty);
    }
    final remote = _FlakyRemote();
    return _World._(r, seeded.groupId, m, remote, FakeAuthService());
  }
}

void main() {
  final de = AppLocalizationsDe();
  final en = AppLocalizationsEn();

  Future<List<({String table, String id})>> localHistory(_World w) async {
    final out = <({String table, String id})>[];
    Future<void> add(String table, Iterable<String> ids) async {
      for (final id in ids) {
        out.add((table: table, id: id));
      }
    }

    await add(DbTables.groups, [w.groupId]);
    await add(DbTables.members, [
      for (final x in await w.db.select(w.db.members).get()) x.id,
    ]);
    await add(DbTables.vehicles, [
      for (final x in await w.db.select(w.db.vehicles).get()) x.id,
    ]);
    await add(DbTables.rideTemplates, [
      for (final x in await w.db.select(w.db.rideTemplates).get()) x.id,
    ]);
    await add(DbTables.expenses, [
      for (final x in await w.db.select(w.db.expenses).get()) x.id,
    ]);
    await add(DbTables.rides, [
      for (final x in await w.db.select(w.db.rides).get()) x.id,
    ]);
    await add(DbTables.settlements, [
      for (final x in await w.db.select(w.db.settlements).get()) x.id,
    ]);
    return out;
  }

  group('makeShared', () {
    test(
      'full history arrives, first push never removes the group',
      () async {
        final w = await _World.create();
        final history = await localHistory(w);
        final writer = OutboxWriter(
          db: w.db,
          clock: w.r.clock,
          ids: SequentialIdGenerator(prefix: 'p'),
        );

        final result = await w.share().makeShared(w.groupId);

        final total = history.length;
        expect(
          result,
          Ok<ShareProgress, ShareError>(
            ShareProgress(
              state: SyncState.shared,
              uploaded: total,
              total: total,
            ),
          ),
        );
        final sync = (await w.sync())!;
        expect(sync.state, SyncState.shared.name);
        expect(sync.role, SyncRole.owner.name);
        expect(sync.lastErrorCode, isNull);
        expect(await w.pending(), 0);
        expect(w.remote.hasMember(w.groupId), isTrue);
        // The bootstrap came before the first member/expense write.
        expect(w.remote.received.first, '${DbTables.groups}:${w.groupId}');

        // Server state equals local state: canonical JSON of every row.
        for (final h in history) {
          final entity = OutboxEntity.values.singleWhere(
            (e) => e.table == h.table,
          );
          final local = await writer.payloadOf(entity, h.id);
          final server = Map<String, Object?>.of(
            w.remote.row(h.table, h.id)!,
          )..remove(DbGroupsCols.serverSeq);
          if (h.table == DbTables.expenses) {
            final kids = (await w.remote.fetchExpenseChildren([
              h.id,
            ]) as Ok<Map<String, ExpenseChildren>, RemoteError>).value[h.id]!;
            // The server adds expense_id to the child rows.
            server['payers'] = [
              for (final p in kids.payers) {...p}..remove('expense_id'),
            ];
            server['shares'] = [
              for (final s in kids.shares) {...s}..remove('expense_id'),
            ];
          }
          if (h.table == DbTables.groups) {
            server.remove(DbGroupsCols.createdBy);
          }
          expect(
            jsonEncode(_canonical(server)),
            jsonEncode(_canonical(local)),
            reason: '${h.table} ${h.id}',
          );
        }
        // Soft-deleted rows are part of the history.
        expect(
          history.where((h) => h.table == DbTables.expenses),
          hasLength(2),
        );
        expect(
          w.remote.row(
            DbTables.members,
            (await w.db.select(w.db.members).get())
                .firstWhere((x) => x.name == 'Dan')
                .id,
          )![DbMembersCols.deletedAt],
          isNotNull,
        );
        // The local created_by is the account now.
        final group = await w.db.select(w.db.groups).getSingle();
        expect(group.createdBy, 'fake-user-1');
        // No local-only column ever reaches the server.
        for (final h in history) {
          expect(
            w.remote.row(h.table, h.id)!.keys,
            isNot(contains('iban')),
          );
        }
      },
    );

    test('shared already: no-op, no call to the server', () async {
      final w = await _World.create(rich: false);
      expect(
        await w.share().makeShared(w.groupId),
        isA<Ok<ShareProgress, ShareError>>(),
      );
      final calls = w.remote.calls;
      final signIns = w.auth.signInCalls;
      final again = await w.share().makeShared(w.groupId);
      expect(
        (again as Ok<ShareProgress, ShareError>).value.state,
        SyncState.shared,
      );
      expect(w.remote.calls, calls);
      expect(w.auth.signInCalls, signIns);
    });

    test('unknown group and removed group say so', () async {
      final w = await _World.create(rich: false);
      expect(
        await w.share().makeShared('nope'),
        const Err<ShareProgress, ShareError>(ShareGroupMissing()),
      );
      await w.db.syncStateDao.setState(w.groupId, SyncState.removed);
      expect(
        await w.share().makeShared(w.groupId),
        const Err<ShareProgress, ShareError>(ShareGroupRemoved()),
      );
      expect(w.remote.calls, 0);
      expect(shareErrorText(de, const ShareGroupMissing()), isNotEmpty);
      expect(
        shareErrorText(en, const ShareGroupRemoved()),
        en.remoteErrorNotMember,
      );
    });

    group('failure before anything is queued', () {
      Future<void> expectUntouched(_World w, String before) async {
        expect(await w.snapshot(), before);
        expect(await w.sync(), isNull);
        expect(await w.pending(), 0);
      }

      test('offline: nothing changes, the message says so (de, en)', () async {
        final w = await _World.create();
        final before = await w.snapshot();
        w.remote.offline = true;
        final r = await w.share().makeShared(w.groupId);
        final failed =
            (r as Err<ShareProgress, ShareError>).error as ShareUploadFailed;
        expect(failed.error, const Offline());
        expect(failed.uploaded, 0);
        expect(failed.total, greaterThan(5));
        await expectUntouched(w, before);
        expect(
          shareErrorText(de, failed),
          '0 von ${failed.total} Einträgen hochgeladen. '
          'Auf diesem Handy ist alles unverändert. '
          'Wir versuchen es weiter. ${de.remoteErrorOffline}',
        );
        expect(
          shareErrorText(en, failed),
          startsWith('0 of ${failed.total} entries uploaded. '),
        );
        expect(shareErrorText(en, failed), endsWith(en.remoteErrorOffline));
        // Back online: the same call finishes it.
        w.remote.offline = false;
        final ok2 = await w.share().makeShared(w.groupId);
        expect(ok2, isA<Ok<ShareProgress, ShareError>>());
      });

      test('rate limited: the wait is in the message', () async {
        final w = await _World.create(rich: false);
        final before = await w.snapshot();
        w.remote.fail = const RateLimitedRemote(Duration(minutes: 3));
        final failed = ((await w.share().makeShared(
          w.groupId,
        )) as Err<ShareProgress, ShareError>).error;
        expect(shareErrorText(de, failed), contains('3 Min.'));
        expect(shareErrorText(en, failed), contains('3 min'));
        await expectUntouched(w, before);
      });

      test(
        'no account: the auth error is shown, server never called',
        () async {
          final w = await _World.create(rich: false);
          w.auth.failWith = const ServerDown();
          final r = await w.share().makeShared(w.groupId);
          expect(
            (r as Err<ShareProgress, ShareError>).error,
            isA<ShareUploadFailed>().having(
              (e) => e.error,
              'error',
              const ServerDown(),
            ),
          );
          expect(w.remote.calls, 0);
          expect(await w.sync(), isNull);
        },
      );

      test('bootstrap refused: group stays local, nothing queued', () async {
        final w = await _World.create(rich: false);
        final before = await w.snapshot();
        // Someone else already holds the group id on the server.
        w.remote.addMember(w.groupId, user: 'someone-else');
        final r = await w.share().makeShared(w.groupId);
        expect(
          (r as Err<ShareProgress, ShareError>).error,
          isA<ShareUploadFailed>().having(
            (e) => e.error,
            'error',
            const NotMember(),
          ),
        );
        await expectUntouched(w, before);
      });
    });

    group('failure during the upload', () {
      test(
        '5xx after k of m: partial message with numbers, local data unchanged, '
        'restart finishes',
        () async {
          final w = await _World.create();
          final history = await localHistory(w);
          final total = history.length;
          // 1 write for the group in the bootstrap, then 4 history writes.
          w.remote.failAfterWrites = 5;

          final r = await w.share().makeShared(w.groupId);
          final failed =
              (r as Err<ShareProgress, ShareError>).error as ShareUploadFailed;
          expect(failed.error, const ServerDown());
          expect(failed.total, total);
          expect(failed.uploaded, 4);
          expect(await w.pending(), total - 4);
          // Never removed, resumable.
          final sync = (await w.sync())!;
          expect(sync.state, SyncState.uploading.name);
          expect(sync.lastErrorCode, isNotNull);
          expect(
            shareErrorText(de, failed),
            startsWith(
              '4 von $total Einträgen hochgeladen. '
              'Auf diesem Handy ist alles unverändert.',
            ),
          );
          expect(
            shareErrorText(de, failed),
            endsWith(de.remoteErrorServerDown),
          );
          expect(
            shareErrorText(en, failed),
            contains('4 of $total entries uploaded'),
          );

          // A kill between the failure and the next try: new objects, and the
          // retry backoff of the failed op is over.
          w.r.clock.advance(const Duration(minutes: 10));
          w.remote.failAfterWrites = null;
          final done = await w.share().makeShared(w.groupId);
          expect(
            done,
            Ok<ShareProgress, ShareError>(
              ShareProgress(
                state: SyncState.shared,
                uploaded: total,
                total: total,
              ),
            ),
          );
          expect((await w.sync())!.state, SyncState.shared.name);
          expect(await w.pending(), 0);
          expect(w.remote.count(DbTables.expenses), 2);
          expect(w.remote.count(DbTables.members), 4);
        },
      );

      test('rate limited mid-upload keeps the rest queued', () async {
        final w = await _World.create(rich: false);
        w.remote
          ..failAfterWrites = 2
          ..failWith = const RateLimitedRemote(Duration(minutes: 2));
        final r = await w.share().makeShared(w.groupId);
        final failed =
            (r as Err<ShareProgress, ShareError>).error as ShareUploadFailed;
        expect(failed.error, const RateLimitedRemote(Duration(minutes: 2)));
        expect(shareErrorText(de, failed), contains('2 Min.'));
        expect((await w.sync())!.state, SyncState.uploading.name);
      });

      test(
        'a plain push of an uploading group keeps going (no makeShared)',
        () async {
          final w = await _World.create(rich: false);
          w.remote.failAfterWrites = 3;
          await w.share().makeShared(w.groupId);
          w.remote.failAfterWrites = null;
          final service = SyncService(
            db: w.db,
            remote: w.remote,
            clock: w.r.clock,
            random: _NoRandom(),
            ids: SequentialIdGenerator(prefix: 'plain'),
          );
          // The retry backoff of the failed op is over.
          w.r.clock.advance(const Duration(minutes: 10));
          expect(await service.push(w.groupId), const SyncIdle());
          expect(w.remote.hasMember(w.groupId), isTrue);
          expect((await w.sync())!.state, SyncState.uploading.name);
          // Finishing is idempotent and marks it shared.
          final done = await w.share().makeShared(w.groupId);
          expect(
            (done as Ok<ShareProgress, ShareError>).value.state,
            SyncState.shared,
          );
        },
      );
    });

    test(
      'a kill after the bootstrap, before queueing: repeat is idempotent',
      () async {
        final w = await _World.create(rich: false);
        // What a first try left on the server before it died.
        final writer = OutboxWriter(
          db: w.db,
          clock: w.r.clock,
          ids: SequentialIdGenerator(prefix: 'k'),
        );
        await w.remote.upsertRows(DbTables.groups, [
          await writer.payloadOf(OutboxEntity.group, w.groupId),
        ]);
        await w.remote.bootstrapMembership(w.groupId);
        final r = await w.share().makeShared(w.groupId);
        expect(
          (r as Ok<ShareProgress, ShareError>).value.state,
          SyncState.shared,
        );
        expect(w.remote.count(DbTables.members), 3);
      },
    );

    test(
      'a kill after the group row, before the bootstrap: repeat finishes',
      () async {
        final w = await _World.create(rich: false);
        final writer = OutboxWriter(
          db: w.db,
          clock: w.r.clock,
          ids: SequentialIdGenerator(prefix: 'k'),
        );
        await w.remote.upsertRows(DbTables.groups, [
          await writer.payloadOf(OutboxEntity.group, w.groupId),
        ]);
        expect(w.remote.hasMember(w.groupId), isFalse);
        final r = await w.share().makeShared(w.groupId);
        expect(
          (r as Ok<ShareProgress, ShareError>).value.state,
          SyncState.shared,
        );
        expect(w.remote.hasMember(w.groupId), isTrue);
      },
    );

    test(
      'a refused entry is shown with its title and counted as not uploaded',
      () async {
        final w = await _World.create(rich: false);
        // The server refuses expense payloads it cannot store.
        w.remote.failWith = const Rejected('amount_not_positive');
        w.remote.failAfterWrites = 4;
        final r = await w.share().makeShared(w.groupId);
        final failed =
            (r as Err<ShareProgress, ShareError>).error as ShareUploadFailed;
        expect(failed.error, isA<Rejected>());
        expect(failed.uploaded, lessThan(failed.total));
        expect(shareErrorText(de, failed), contains('von ${failed.total}'));
      },
    );
  });
}

/// Key order and `+00:00` vs `Z` differences do not matter, only content.
Object? _canonical(Object? v) => switch (v) {
  final Map<Object?, Object?> m => {
    for (final k in (m.keys.toList()..sort((a, b) => '$a'.compareTo('$b'))))
      k: _canonical(m[k]),
  },
  final List<Object?> l => [for (final e in l) _canonical(e)],
  _ => v,
};
