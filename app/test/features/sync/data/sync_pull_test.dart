// Two databases per test (one per simulated device).

import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/outbox_writer.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

import '../../repo_test_support.dart';

class _NoRandom implements Random {
  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;

  @override
  int nextInt(int max) => 0;
}

/// A server that misbehaves on demand, on top of the fake.
class _Scripted extends FakeSyncRemote {
  _Scripted.sharing(super.other, {required super.userId}) : super.sharing();

  /// Fails every pull of this table.
  String? failTable;
  RemoteError? failWith;

  /// Rows handed out once for a table instead of the real ones.
  final Map<String, List<Map<String, Object?>>> injected = {};

  /// Answer expense children with nothing.
  bool dropChildren = false;

  @override
  Future<Result<List<Map<String, Object?>>, RemoteError>> pullChanges({
    required String groupId,
    required String table,
    required int afterSeq,
    required int limit,
  }) async {
    if (table == failTable && failWith != null) return Err(failWith!);
    final fake = injected.remove(table);
    if (fake != null) return Ok(fake);
    return super.pullChanges(
      groupId: groupId,
      table: table,
      afterSeq: afterSeq,
      limit: limit,
    );
  }

  @override
  Future<Result<Map<String, ExpenseChildren>, RemoteError>>
  fetchExpenseChildren(List<String> expenseIds) async => dropChildren
      ? const Ok(<String, ExpenseChildren>{})
      : super.fetchExpenseChildren(expenseIds);
}

class _Device {
  _Device(this.r, this.groupId, this.remote, this.service);

  final Repos r;
  final String groupId;
  final FakeSyncRemote remote;
  final SyncService service;

  AppDatabase get db => r.db!;
  FixedClock get clock => r.clock;

  Future<SyncStatus> pull() => service.pull(groupId);
  Future<SyncStatus> push() => service.push(groupId);

  Future<List<LocalOutboxRow>> outbox() => db.syncStateDao.outboxOf(groupId);

  Future<List<ExpenseRow>> expenseRows() => db.select(db.expenses).get();

  Future<ExpenseRow> expense(String id) =>
      (db.select(db.expenses)..where((e) => e.id.equals(id))).getSingle();

  Future<List<ExpenseRevisionRow>> revisions(String id) =>
      db.expensesDao.revisionsOf(id);

  SyncService serviceAgain() => SyncService(
    db: db,
    remote: remote,
    clock: clock,
    random: _NoRandom(),
    ids: SequentialIdGenerator(prefix: 'again'),
  );
}

class _Pair {
  _Pair(this.a, this.b, this.members, this.car);

  final _Device a;
  final _Device b;
  final List<GroupMember> members;
  final Vehicle car;

  String get groupId => a.groupId;
  _Scripted get bRemote => b.remote as _Scripted;

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
    split: EqualSplit(among ?? {for (final x in members) x.id}),
    category: 'food',
  );

  /// Adds an expense on device A and uploads it.
  Future<String> aExpense({String title = 'Dinner'}) async {
    final e = ok(
      await a.r.expenses.create(groupId, draft(members[0].id, title: title)),
    );
    expect(await a.push(), const SyncIdle());
    return e.expense.id;
  }

  static Future<_Pair> create() async {
    Hlc.debugReset();
    final ar = await driftRepos();
    final seeded = await seedGroup(ar);
    final car = ok(
      await ar.vehicles.add(
        seeded.groupId,
        name: 'Golf',
        fuelType: FuelType.diesel,
        consumptionMilliPer100km: 5500,
        wearMilliPerKm: 80,
        kmRateMilliPerKm: 300,
      ),
    );
    final adb = ar.db!;
    await adb.syncStateDao.setState(
      seeded.groupId,
      SyncState.uploading,
      role: SyncRole.owner,
    );
    final aRemote = FakeSyncRemote();
    final aService = SyncService(
      db: adb,
      remote: aRemote,
      clock: ar.clock,
      random: _NoRandom(),
      ids: SequentialIdGenerator(prefix: 'a'),
    );
    final writer = OutboxWriter(
      db: adb,
      clock: ar.clock,
      ids: SequentialIdGenerator(prefix: 'up'),
    );
    await writer.enqueue(OutboxEntity.group, seeded.groupId);
    expect(await aService.push(seeded.groupId), const SyncIdle());
    await aRemote.bootstrapMembership(seeded.groupId);
    for (final m in seeded.members) {
      await writer.enqueue(OutboxEntity.member, m.id);
    }
    await writer.enqueue(OutboxEntity.vehicle, car.id);
    expect(await aService.push(seeded.groupId), const SyncIdle());
    await adb.syncStateDao.setState(seeded.groupId, SyncState.shared);

    // Device B: only a placeholder group row, as after "join".
    final br = await driftRepos();
    final bdb = br.db!;
    await bdb
        .into(bdb.groups)
        .insert(
          GroupsCompanion.insert(
            id: seeded.groupId,
            name: 'joining',
            currency: 'EUR',
            createdBy: '',
            createdAt: DateTime.utc(2026),
            updatedAt: '',
          ),
        );
    await bdb.syncStateDao.setState(
      seeded.groupId,
      SyncState.shared,
      role: SyncRole.member,
    );
    final bRemote = _Scripted.sharing(aRemote, userId: 'user-2')
      ..addMember(seeded.groupId);
    final bService = SyncService(
      db: bdb,
      remote: bRemote,
      clock: br.clock,
      random: _NoRandom(),
      ids: SequentialIdGenerator(prefix: 'b'),
    );
    return _Pair(
      _Device(ar, seeded.groupId, aRemote, aService),
      _Device(br, seeded.groupId, bRemote, bService),
      seeded.members,
      car,
    );
  }
}

String _vehicleHlc(int n) =>
    '2026-03-01T12:00:00.000Z-${n.toString().padLeft(4, '0')}-other';

Map<String, Object?> _vehicleRow(String groupId, int n, {String? hlc}) => {
  DbVehiclesCols.id: 'bulk-$n',
  DbVehiclesCols.groupId: groupId,
  DbVehiclesCols.name: 'Car $n',
  DbVehiclesCols.fuelType: 'petrol',
  DbVehiclesCols.consumptionMilliPer100km: 6000,
  DbVehiclesCols.wearMilliPerKm: 0,
  DbVehiclesCols.kmRateMilliPerKm: null,
  DbVehiclesCols.createdAt: '2026-03-01T12:00:00.000Z',
  DbVehiclesCols.updatedAt: hlc ?? _vehicleHlc(n % 9000),
  DbVehiclesCols.deletedAt: null,
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('first pull', () {
    test(
      'brings the whole group; FKs are enforced, parents come first',
      () async {
        final p = await _Pair.create();
        final id = await p.aExpense();

        final fk = await p.b.db.customSelect('PRAGMA foreign_keys').getSingle();
        expect(fk.read<int>('foreign_keys'), 1);

        // The expense page references members that are new in this very pull.
        expect(await p.b.pull(), const SyncIdle());

        final g = await p.b.db.select(p.b.db.groups).getSingle();
        expect(g.name, 'Trip');
        expect(await p.b.db.select(p.b.db.members).get(), hasLength(3));
        expect(await p.b.db.select(p.b.db.vehicles).get(), hasLength(1));
        final e = ok(await p.b.r.expenses.get(id));
        expect(e.expense.title, 'Dinner');
        expect(e.expense.amountCents, 3000);
        expect(e.expense.payers, {p.members[0].id: 3000});
        expect(e.expense.shares.values.fold<int>(0, (a, b) => a + b), 3000);
        expect(
          (await p.b.db.syncStateDao.groupSync(p.groupId))?.lastPullAt,
          isNotNull,
        );
      },
    );

    test('applying queues nothing and a push has nothing to send', () async {
      final p = await _Pair.create();
      await p.aExpense();
      await p.b.pull();
      expect(await p.b.outbox(), isEmpty);
      expect(await p.b.push(), const SyncIdle());
      expect(p.b.remote.received, isEmpty);
    });

    test('creating a pulled expense writes no revision', () async {
      final p = await _Pair.create();
      final id = await p.aExpense();
      await p.b.pull();
      expect(await p.b.revisions(id), isEmpty);
    });
  });

  group('cursor and pages', () {
    test('1 200 rows arrive across pages, ordered, exactly once', () async {
      final p = await _Pair.create();
      final rows = [for (var i = 0; i < 1200; i++) _vehicleRow(p.groupId, i)];
      expect(
        await p.a.remote.upsertRows(DbTables.vehicles, rows),
        isA<Ok<PushOutcome, RemoteError>>(),
      );
      p.b.remote.calls = 0;
      expect(await p.b.pull(), const SyncIdle());
      expect(await p.b.db.select(p.b.db.vehicles).get(), hasLength(1201));
      final cursor = await p.b.db.syncStateDao.cursorOf(
        p.groupId,
        DbTables.vehicles,
      );
      final top = [
        for (final r in rows)
          p.a.remote.row(
                DbTables.vehicles,
                r[DbVehiclesCols.id]! as String,
              )![DbVehiclesCols.serverSeq]!
              as int,
      ].reduce(max);
      expect(cursor, top);
      // 6 other tables once each; vehicles 500 + 500 + 201.
      expect(p.b.remote.calls, 6 + 3);
    });

    test('the cursor survives a restart; a re-pull changes nothing', () async {
      final p = await _Pair.create();
      final id = await p.aExpense();
      await p.b.pull();
      final before = await p.b.expense(id);
      final cursors = await p.b.db.syncStateDao.cursorsOf(p.groupId);

      final restarted = p.b.serviceAgain();
      expect(await restarted.pull(p.groupId), const SyncIdle());
      expect(await p.b.db.syncStateDao.cursorsOf(p.groupId), cursors);
      expect((await p.b.expense(id)).updatedAt, before.updatedAt);
      expect(await p.b.revisions(id), isEmpty);

      final id2 = await p.aExpense(title: 'Lunch');
      expect(await restarted.pull(p.groupId), const SyncIdle());
      expect((await p.b.expense(id2)).title, 'Lunch');
      expect(await p.b.expenseRows(), hasLength(2));
    });

    test('a second call while a pull runs waits for it', () async {
      final p = await _Pair.create();
      await p.aExpense();
      final first = p.b.pull();
      expect(await p.b.service.status(p.groupId), const SyncSyncing());
      final second = p.b.pull();
      expect(await Future.wait([first, second]), [
        const SyncIdle(),
        const SyncIdle(),
      ]);
      expect(await p.b.expenseRows(), hasLength(1));
    });
  });

  group('merge', () {
    test(
      'a tombstone is applied and keeps the old version as history',
      () async {
        final p = await _Pair.create();
        final id = await p.aExpense();
        await p.b.pull();
        ok(await p.a.r.expenses.softDelete(id));
        await p.a.push();
        expect(await p.b.pull(), const SyncIdle());
        expect((await p.b.expense(id)).deletedAt, isNotNull);
        expect(await p.b.revisions(id), hasLength(1));
        expect(await p.b.outbox(), isEmpty);
      },
    );

    test('a restore beats the older delete', () async {
      final p = await _Pair.create();
      final id = await p.aExpense();
      ok(await p.a.r.expenses.softDelete(id));
      await p.a.push();
      await p.b.pull();
      expect((await p.b.expense(id)).deletedAt, isNotNull);
      ok(await p.a.r.expenses.restore(id));
      await p.a.push();
      await p.b.pull();
      expect((await p.b.expense(id)).deletedAt, isNull);
    });

    test('children are replaced, not merged', () async {
      final p = await _Pair.create();
      final id = await p.aExpense();
      await p.b.pull();
      ok(
        await p.a.r.expenses.update(
          id,
          p.draft(
            p.members[1].id,
            title: 'Dinner 2',
            cents: 4000,
            among: {p.members[1].id, p.members[2].id},
          ),
        ),
      );
      await p.a.push();
      await p.b.pull();
      final aSide = ok(await p.a.r.expenses.get(id)).expense;
      final bSide = ok(await p.b.r.expenses.get(id)).expense;
      expect(bSide.payers, {p.members[1].id: 4000});
      expect(bSide.payers, aSide.payers);
      expect(bSide.shares, aSide.shares);
      expect(await p.b.db.select(p.b.db.expensePayers).get(), hasLength(1));
      expect(await p.b.revisions(id), hasLength(1));
    });

    test('remote newer than a pending local op: applied, op dropped', () async {
      final p = await _Pair.create();
      final id = await p.aExpense();
      await p.b.pull();
      ok(await p.b.r.expenses.update(id, p.draft(p.members[0].id, title: 'B')));
      expect(await p.b.outbox(), hasLength(1));
      ok(await p.a.r.expenses.update(id, p.draft(p.members[0].id, title: 'A')));
      await p.a.push();

      expect(await p.b.pull(), const SyncIdle());
      expect((await p.b.expense(id)).title, 'A');
      expect(await p.b.outbox(), isEmpty);
      // B's own edit and the version the pull overwrote are both history.
      final history = await p.b.revisions(id);
      expect(history, hasLength(2));
      expect(await p.b.push(), const SyncIdle());
      expect(p.b.remote.received, isEmpty);
      expect(p.a.remote.row(DbTables.expenses, id)![DbExpensesCols.title], 'A');
    });

    test('pending local newer than the remote: kept and pushed', () async {
      final p = await _Pair.create();
      final id = await p.aExpense();
      await p.b.pull();
      ok(await p.a.r.expenses.update(id, p.draft(p.members[0].id, title: 'A')));
      await p.a.push();
      ok(await p.b.r.expenses.update(id, p.draft(p.members[0].id, title: 'B')));
      final op = (await p.b.outbox()).single;

      expect(await p.b.pull(), const SyncPending(1));
      expect((await p.b.expense(id)).title, 'B');
      expect((await p.b.outbox()).single.opId, op.opId);

      expect(await p.b.push(), const SyncIdle());
      expect(p.a.remote.row(DbTables.expenses, id)![DbExpensesCols.title], 'B');
    });

    test('dropping a superseded op removes only that op_id', () async {
      final p = await _Pair.create();
      final id = await p.aExpense();
      await p.b.pull();
      ok(await p.b.r.expenses.update(id, p.draft(p.members[0].id, title: 'B')));
      ok(await p.b.r.members.update(p.members[1].id, name: 'Benny'));
      final ops = {for (final o in await p.b.outbox()) o.entityId: o.opId};
      expect(ops, hasLength(2));

      ok(await p.a.r.expenses.update(id, p.draft(p.members[0].id, title: 'A')));
      await p.a.push();
      await p.b.pull();

      final left = await p.b.outbox();
      expect(left.single.entityId, p.members[1].id);
      expect(left.single.opId, ops[p.members[1].id]);
      // A write after the pull is a new op, not the dropped one.
      ok(await p.b.r.expenses.update(id, p.draft(p.members[0].id, title: 'C')));
      final fresh = (await p.b.outbox()).firstWhere((o) => o.entityId == id);
      expect(fresh.opId, isNot(ops[id]));
    });

    test(
      'local-only data survives: the full IBAN stays on the phone',
      () async {
        final p = await _Pair.create();
        await p.b.pull();
        final m = p.members[0].id;
        await p.b.db.localMemberBankDao.upsert(
          LocalMemberBankCompanion.insert(
            memberId: m,
            iban: 'DE02120300000000202051',
            updatedAt: 'x',
          ),
        );
        ok(await p.a.r.members.update(m, name: 'Annabelle'));
        await p.a.push();
        await p.b.pull();
        final row = await (p.b.db.select(
          p.b.db.members,
        )..where((t) => t.id.equals(m))).getSingle();
        expect(row.name, 'Annabelle');
        final bank = await p.b.db.localMemberBankDao.findByMember(m);
        expect(bank?.iban, 'DE02120300000000202051');
      },
    );

    test('the account link comes from the server', () async {
      final p = await _Pair.create();
      final m = p.members[2].id;
      // What join_group does server side: sets user_id (the fake keeps it).
      final row = Map<String, Object?>.of(
        p.a.remote.row(DbTables.members, m)!,
      );
      row[DbMembersCols.userId] = 'user-9';
      row[DbMembersCols.updatedAt] = Hlc.now(p.a.clock);
      await p.a.remote.upsertRows(DbTables.members, [row]);
      await p.b.pull();
      final local = await (p.b.db.select(
        p.b.db.members,
      )..where((t) => t.id.equals(m))).getSingle();
      expect(local.userId, 'user-9');
    });

    test('a remote delete archives the group and keeps it shared', () async {
      final p = await _Pair.create();
      await p.b.pull();
      ok(await p.a.r.groups.softDelete(p.groupId));
      await p.a.push();
      expect(await p.b.pull(), const SyncIdle());
      final g = await p.b.db.select(p.b.db.groups).getSingle();
      expect(g.deletedAt, isNotNull);
      expect(await p.b.db.select(p.b.db.members).get(), hasLength(3));
      expect(
        (await p.b.db.syncStateDao.groupSync(p.groupId))?.state,
        SyncState.shared.name,
      );
    });
  });

  group('clock', () {
    test(
      'a far-future remote stamp is applied, the local clock is not moved',
      () async {
        final p = await _Pair.create();
        await p.a.remote.upsertRows(DbTables.vehicles, [
          _vehicleRow(
            p.groupId,
            1,
            hlc: '2099-01-01T00:00:00.000Z-0000-other',
          ),
        ]);
        expect(await p.b.pull(), const SyncIdle());
        final v = await (p.b.db.select(
          p.b.db.vehicles,
        )..where((t) => t.id.equals('bulk-1'))).getSingle();
        expect(v.name, 'Car 1');
        expect(Hlc.now(p.b.clock), startsWith('2026-'));
      },
    );

    test('an unreadable stamp stops the page and is shown', () async {
      final p = await _Pair.create();
      await p.a.remote.upsertRows(DbTables.vehicles, [
        _vehicleRow(p.groupId, 2, hlc: 'garbage'),
      ]);
      final status = await p.b.pull();
      expect(status, const SyncError(PullFailed('invalid_updated_at')));
      expect(await p.b.db.select(p.b.db.vehicles).get(), isEmpty);
      expect(
        await p.b.db.syncStateDao.cursorOf(p.groupId, DbTables.vehicles),
        0,
      );
      expect(
        remoteErrorText(
          AppLocalizationsDe(),
          (status as SyncError).error,
        ),
        'Neue Änderungen aus der Gruppe konnten nicht übernommen werden. '
        'Deine eigenen Daten sind sicher. '
        'Versuch es später nochmal oder aktualisiere mitlio.',
      );
      expect(
        remoteErrorText(AppLocalizationsEn(), status.error),
        'New changes from the group could not be applied. '
        'Your own data is safe. Try again later or update mitlio.',
      );
    });
  });

  group('failures are visible and leave the cursor alone', () {
    test('offline mid-pull: earlier pages stay, the failed one not', () async {
      final p = await _Pair.create();
      final id = await p.aExpense();
      p.bRemote
        ..failTable = DbTables.expenses
        ..failWith = const Offline();

      final status = await p.b.pull();
      expect(status, const SyncError(Offline()));
      expect(await p.b.db.select(p.b.db.members).get(), hasLength(3));
      expect(await p.b.expenseRows(), isEmpty);
      expect(
        await p.b.db.syncStateDao.cursorOf(p.groupId, DbTables.expenses),
        0,
      );
      expect(
        remoteErrorText(AppLocalizationsDe(), (status as SyncError).error),
        'Keine Verbindung. Deine Änderungen sind gespeichert und gehen raus, '
        'sobald du online bist.',
      );
      expect(
        remoteErrorText(AppLocalizationsEn(), status.error),
        'No connection. Your changes are saved and will go out as soon as you '
        'are online.',
      );

      p.bRemote.failWith = null;
      expect(await p.b.pull(), const SyncIdle());
      expect((await p.b.expense(id)).title, 'Dinner');
      expect(
        (await p.b.db.syncStateDao.groupSync(p.groupId))?.lastErrorCode,
        isNull,
      );
    });

    test('server down and rate limit are shown with their words', () async {
      final p = await _Pair.create();
      p.b.remote.failNext(const ServerDown());
      var status = await p.b.pull();
      expect(status, const SyncError(ServerDown()));
      expect(
        remoteErrorText(AppLocalizationsDe(), (status as SyncError).error),
        'Der Server antwortet gerade nicht. Wir versuchen es gleich nochmal.',
      );
      expect(
        remoteErrorText(AppLocalizationsEn(), status.error),
        'The server is not responding right now. We will try again shortly.',
      );

      p.b.remote.failNext(const RateLimitedRemote(Duration(minutes: 3)));
      status = await p.b.pull();
      expect(status, const SyncError(RateLimitedRemote(Duration(minutes: 3))));
      expect(
        remoteErrorText(AppLocalizationsDe(), (status as SyncError).error),
        'Zu viele Versuche. Versuch es in 3 Min. nochmal.',
      );
      expect(
        remoteErrorText(AppLocalizationsEn(), status.error),
        contains('3'),
      );
    });

    test('a failure fetching expense children applies no expense', () async {
      final p = await _Pair.create();
      await p.aExpense();
      p.bRemote.dropChildren = true;
      final status = await p.b.pull();
      expect(status, const SyncError(PullFailed('expense_children_missing')));
      expect(await p.b.expenseRows(), isEmpty);
      expect(await p.b.db.select(p.b.db.expensePayers).get(), isEmpty);
      expect(
        await p.b.db.syncStateDao.cursorOf(p.groupId, DbTables.expenses),
        0,
      );
    });

    test(
      'a page the local database refuses is rolled back and shown',
      () async {
        final p = await _Pair.create();
        p.bRemote.injected[DbTables.settlements] = [
          {
            DbSettlementsCols.id: 's1',
            DbSettlementsCols.groupId: p.groupId,
            DbSettlementsCols.fromMember: 'ghost',
            DbSettlementsCols.toMember: p.members[0].id,
            DbSettlementsCols.amountCents: 100,
            DbSettlementsCols.currency: 'EUR',
            DbSettlementsCols.date: '2026-03-01T00:00:00.000Z',
            DbSettlementsCols.method: 'cash',
            DbSettlementsCols.createdAt: '2026-03-01T12:00:00.000Z',
            DbSettlementsCols.updatedAt: _vehicleHlc(1),
            DbSettlementsCols.deletedAt: null,
            DbSettlementsCols.serverSeq: 7,
          },
        ];
        final status = await p.b.pull();
        expect(status, const SyncError(PullFailed('local_apply_failed')));
        expect(await p.b.db.select(p.b.db.settlements).get(), isEmpty);
        expect(
          await p.b.db.syncStateDao.cursorOf(p.groupId, DbTables.settlements),
          0,
        );
        expect(
          (await p.b.db.syncStateDao.groupSync(p.groupId))?.lastErrorCode,
          'pullFailed:local_apply_failed',
        );
      },
    );

    test('rows that do not move the cursor cannot loop forever', () async {
      final p = await _Pair.create();
      p.bRemote.injected[DbTables.vehicles] = [
        {..._vehicleRow(p.groupId, 3), DbVehiclesCols.serverSeq: 0},
      ];
      expect(
        await p.b.pull(),
        const SyncError(PullFailed('cursor_stuck')),
      );
    });

    test(
      'removed from the group: kept data, state removed, no more calls',
      () async {
        final p = await _Pair.create();
        await p.aExpense();
        await p.b.pull();
        p.a.remote.removeMember(p.groupId, user: 'user-2');

        final status = await p.b.pull();
        expect(status, const SyncError(NotMember()));
        expect(
          (await p.b.db.syncStateDao.groupSync(p.groupId))?.state,
          SyncState.removed.name,
        );
        expect(await p.b.db.select(p.b.db.members).get(), hasLength(3));
        expect(await p.b.expenseRows(), hasLength(1));
        expect(
          remoteErrorText(AppLocalizationsDe(), (status as SyncError).error),
          'Du bist nicht mehr in dieser Gruppe. Deine Daten bleiben auf diesem '
          'Handy.',
        );
        expect(
          remoteErrorText(AppLocalizationsEn(), status.error),
          'You are no longer in this group. Your data stays on this phone.',
        );

        final calls = p.b.remote.calls;
        expect(await p.b.pull(), const SyncError(NotMember()));
        expect(p.b.remote.calls, calls);
      },
    );

    test('a push refusal stays visible after a good pull', () async {
      final p = await _Pair.create();
      await p.b.pull();
      await p.b.db.syncStateDao.recordError(
        p.groupId,
        'rejected:payers_sum_mismatch',
        p.b.clock.now(),
      );
      await p.b.pull();
      expect(
        (await p.b.db.syncStateDao.groupSync(p.groupId))?.lastErrorCode,
        'rejected:payers_sum_mismatch',
      );
    });

    test('a good pull keeps an error while pushes still wait', () async {
      final p = await _Pair.create();
      await p.b.pull();
      ok(await p.b.r.members.update(p.members[0].id, name: 'Anni'));
      await p.b.db.syncStateDao.recordError(
        p.groupId,
        'offline',
        p.b.clock.now(),
      );
      expect(await p.b.pull(), const SyncError(Offline()));
      await p.b.push();
      expect(await p.b.pull(), const SyncIdle());
    });

    test('a local group without sync does nothing', () async {
      final p = await _Pair.create();
      await p.b.db.syncStateDao.clearGroup(p.groupId);
      p.b.remote.calls = 0;
      expect(await p.b.pull(), const SyncIdle());
      expect(p.b.remote.calls, 0);
    });
  });
}
