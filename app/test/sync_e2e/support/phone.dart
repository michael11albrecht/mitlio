// Justification: Snapshot is a value type whose list is never changed after
// construction; its async builders cannot be constructors.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: prefer_constructors_over_static_methods
import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/repositories/join_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../features/sync/support/share_support.dart';
import '../../helpers/fake_platform.dart';
import 'local_supabase.dart';

/// All phones of a scenario tell the same time (a shared clock keeps every
/// HLC inside the one-minute drift window); the test moves it forward to say
/// who edited last.
class World {
  World() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final clock = FixedClock(DateTime.utc(2026, 3, 1, 12));

  /// One minute later; every edit of a scenario happens at its own minute.
  void tick([Duration by = const Duration(minutes: 1)]) => clock.advance(by);

  Phone phone(String name, int seed) => Phone._(this, name, seed);
}

/// One headless "device": its own in-memory database, its own anonymous
/// account, and the app's real repositories, sync service and Supabase
/// implementations. No UI.
class Phone {
  Phone._(this.world, this.name, int seed)
    : db = AppDatabase(NativeDatabase.memory()),
      secrets = MemorySecretStore() {
    final client = LocalSupabase.instance.newClient();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        remoteBackendProvider.overrideWithValue(
          RemoteBackend.withClient(client),
        ),
        clockProvider.overrideWithValue(world.clock),
        idGeneratorProvider.overrideWithValue(
          UuidV7Generator(clock: world.clock, random: Random(seed)),
        ),
        randomProvider.overrideWithValue(Random(seed)),
        secretStoreProvider.overrideWithValue(secrets),
        shareServiceProvider.overrideWithValue(FakeShareService()),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
  }

  final World world;
  final String name;
  final AppDatabase db;
  final MemorySecretStore secrets;
  late final ProviderContainer container;

  GroupsRepository get groups => container.read(groupsRepositoryProvider);
  MembersRepository get members => container.read(membersRepositoryProvider);
  ExpensesRepository get expenses => container.read(expensesRepositoryProvider);
  SettlementsRepository get settlements =>
      container.read(settlementsRepositoryProvider);
  VehiclesRepository get vehicles => container.read(vehiclesRepositoryProvider);
  SyncService get sync => container.read(syncServiceProvider);
  ShareGroupRepository get share =>
      container.read(shareGroupRepositoryProvider);
  ShareLinkRepository get links => container.read(shareLinkRepositoryProvider);
  JoinRepository get join => container.read(joinRepositoryProvider);

  String? get userId => container.read(authServiceProvider).currentUserId;

  /// What the server tells this phone's account about a group.
  SyncRemoteView get server =>
      SyncRemoteView(container.read(syncRemoteProvider));

  Future<SyncStatus> push(String groupId) => sync.push(groupId);
  Future<SyncStatus> pull(String groupId) => sync.pull(groupId);

  /// Push, then pull; both must end idle.
  Future<void> syncBoth(String groupId) async {
    expect(await push(groupId), const SyncIdle(), reason: '$name push');
    expect(await pull(groupId), const SyncIdle(), reason: '$name pull');
  }

  Future<int> pending(String groupId) =>
      db.syncStateDao.pendingOutboxCount(groupId);

  /// A group with Ann, Ben and Cy on this phone, not shared yet.
  Future<({String groupId, List<GroupMember> members})> seedGroup() async {
    final g = unwrap(
      await groups.create(
        name: 'Trip',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    final people = [
      for (final n in ['Ann', 'Ben', 'Cy'])
        unwrap(await members.add(g.id, name: n)),
    ];
    return (groupId: g.id, members: people);
  }

  ExpenseDraft draft(
    String payer,
    Iterable<String> among, {
    String title = 'Dinner',
    int cents = 3000,
  }) => ExpenseDraft(
    title: title,
    amountCents: cents,
    currency: Currency.eur,
    date: DateTime.utc(2026, 3),
    payers: {payer: cents},
    split: EqualSplit(among.toSet()),
    category: 'food',
  );

  /// The canonical state of [groupId] on this phone.
  Future<Snapshot> snapshot(String groupId) => Snapshot.ofDevice(db, groupId);
}

/// [RepoResult] or fail.
T unwrap<T>(RepoResult<T> r) => switch (r) {
  Ok<T, RepositoryError>(:final value) => value,
  Err<T, RepositoryError>(:final error) => fail('expected Ok, got $error'),
};

/// [Result] of a remote call or fail.
T unwrapRemote<T>(Result<T, RemoteError> r) => switch (r) {
  Ok<T, RemoteError>(:final value) => value,
  Err<T, RemoteError>(:final error) => fail('expected Ok, got $error'),
};

/// The server side of a group as one account may read it.
class SyncRemoteView {
  SyncRemoteView(this._remote);

  final SyncRemote _remote;

  Future<Snapshot> snapshot(String groupId) =>
      Snapshot.ofServer(_remote, groupId);
}

/// A canonical, comparable form of everything the app syncs for a group: ids,
/// the fields people see, versions and deletions, payers and shares. Local-only
/// columns (full IBAN, places, outbox, cursors) are not part of it.
class Snapshot {
  Snapshot._(this.lines);

  final List<String> lines;

  String get text => lines.join('\n');

  @override
  bool operator ==(Object other) => other is Snapshot && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;

  static String _line(String kind, List<Object?> parts) =>
      '$kind|${parts.join('|')}';

  static Snapshot _sorted(List<String> lines) => Snapshot._(lines..sort());

  static Future<Snapshot> ofDevice(AppDatabase db, String groupId) async {
    final lines = <String>[];
    for (final g in await (db.select(
      db.groups,
    )..where((t) => t.id.equals(groupId))).get()) {
      lines.add(
        _line('group', [
          g.id,
          g.name,
          g.currency,
          g.updatedAt,
          g.deletedAt != null,
        ]),
      );
    }
    for (final m in await (db.select(
      db.members,
    )..where((t) => t.groupId.equals(groupId))).get()) {
      lines.add(
        _line('member', [
          m.id,
          m.name,
          m.position,
          m.updatedAt,
          m.deletedAt != null,
        ]),
      );
    }
    for (final v in await (db.select(
      db.vehicles,
    )..where((t) => t.groupId.equals(groupId))).get()) {
      lines.add(
        _line('vehicle', [v.id, v.name, v.updatedAt, v.deletedAt != null]),
      );
    }
    final payers = await db.select(db.expensePayers).get();
    final shares = await db.select(db.expenseShares).get();
    for (final e in await (db.select(
      db.expenses,
    )..where((t) => t.groupId.equals(groupId))).get()) {
      lines.add(
        _line('expense', [
          e.id,
          e.title,
          e.amountCents,
          e.updatedAt,
          e.deletedAt != null,
          _kv([
            for (final p in payers)
              if (p.expenseId == e.id) '${p.memberId}:${p.paidCents}',
          ]),
          _kv([
            for (final s in shares)
              if (s.expenseId == e.id) '${s.memberId}:${s.shareCents}',
          ]),
        ]),
      );
    }
    for (final s in await (db.select(
      db.settlements,
    )..where((t) => t.groupId.equals(groupId))).get()) {
      lines.add(
        _line('settlement', [
          s.id,
          s.fromMember,
          s.toMember,
          s.amountCents,
          s.updatedAt,
          s.deletedAt != null,
        ]),
      );
    }
    return _sorted(lines);
  }

  static String _pair(Object? member, Object? cents) => '$member:$cents';

  static String _kv(List<String> items) => (items..sort()).join(',');

  static Future<List<Map<String, Object?>>> _all(
    SyncRemote remote,
    String groupId,
    String table,
  ) async {
    final rows = <Map<String, Object?>>[];
    var after = 0;
    while (true) {
      final page = unwrapRemote(
        await remote.pullChanges(
          groupId: groupId,
          table: table,
          afterSeq: after,
          limit: 500,
        ),
      );
      rows.addAll(page);
      if (page.length < 500) return rows;
      after = page.last[DbGroupsCols.serverSeq]! as int;
    }
  }

  static Future<Snapshot> ofServer(SyncRemote remote, String groupId) async {
    final lines = <String>[];
    for (final g in await _all(remote, groupId, DbTables.groups)) {
      lines.add(
        _line('group', [
          g[DbGroupsCols.id],
          g[DbGroupsCols.name],
          g[DbGroupsCols.currency],
          g[DbGroupsCols.updatedAt],
          g[DbGroupsCols.deletedAt] != null,
        ]),
      );
    }
    for (final m in await _all(remote, groupId, DbTables.members)) {
      lines.add(
        _line('member', [
          m[DbMembersCols.id],
          m[DbMembersCols.name],
          m[DbMembersCols.position],
          m[DbMembersCols.updatedAt],
          m[DbMembersCols.deletedAt] != null,
        ]),
      );
    }
    for (final v in await _all(remote, groupId, DbTables.vehicles)) {
      lines.add(
        _line('vehicle', [
          v[DbVehiclesCols.id],
          v[DbVehiclesCols.name],
          v[DbVehiclesCols.updatedAt],
          v[DbVehiclesCols.deletedAt] != null,
        ]),
      );
    }
    final expenses = await _all(remote, groupId, DbTables.expenses);
    final children = unwrapRemote(
      await remote.fetchExpenseChildren([
        for (final e in expenses) e[DbExpensesCols.id]! as String,
      ]),
    );
    for (final e in expenses) {
      final id = e[DbExpensesCols.id]! as String;
      final c = children[id];
      lines.add(
        _line('expense', [
          id,
          e[DbExpensesCols.title],
          e[DbExpensesCols.amountCents],
          e[DbExpensesCols.updatedAt],
          e[DbExpensesCols.deletedAt] != null,
          _kv([
            for (final p in c?.payers ?? const <Map<String, Object?>>[])
              _pair(
                p[DbExpensePayersCols.memberId],
                p[DbExpensePayersCols.paidCents],
              ),
          ]),
          _kv([
            for (final s in c?.shares ?? const <Map<String, Object?>>[])
              _pair(
                s[DbExpenseSharesCols.memberId],
                s[DbExpenseSharesCols.shareCents],
              ),
          ]),
        ]),
      );
    }
    for (final s in await _all(remote, groupId, DbTables.settlements)) {
      lines.add(
        _line('settlement', [
          s[DbSettlementsCols.id],
          s[DbSettlementsCols.fromMember],
          s[DbSettlementsCols.toMember],
          s[DbSettlementsCols.amountCents],
          s[DbSettlementsCols.updatedAt],
          s[DbSettlementsCols.deletedAt] != null,
        ]),
      );
    }
    return _sorted(lines);
  }
}

/// Fails with both snapshots when [a] and [b] differ.
void expectSame(Snapshot a, Snapshot b, String what) {
  expect(a.text, b.text, reason: what);
}

/// Owner phone shares its group, a second phone joins by link and connects to
/// [personIndex].
Future<
  ({
    String groupId,
    List<GroupMember> people,
    String token,
  })
>
shareAndJoin(
  Phone owner,
  Phone joiner, {
  int personIndex = 1,
}) async {
  final seeded = await owner.seedGroup();
  final shared = await owner.share.makeShared(seeded.groupId);
  expect(
    switch (shared) {
      Ok(:final value) => value.state,
      Err(:final error) => fail('share failed: $error'),
    },
    SyncState.shared,
  );
  final link = switch (await owner.links.link(seeded.groupId, isOwner: true)) {
    Ok(:final value) => value,
    Err(:final error) => fail('no link: $error'),
  };
  final joined = switch (await joiner.join.join(link.token)) {
    Ok(:final value) => value,
    Err(:final error) => fail('join failed: $error'),
  };
  expect(joined.groupId, seeded.groupId);
  final connect = await joiner.join.connect(
    seeded.groupId,
    seeded.members[personIndex].id,
  );
  expect(connect, isA<Ok<void, RemoteError>>(), reason: '$connect');
  return (groupId: seeded.groupId, people: seeded.members, token: link.token);
}
