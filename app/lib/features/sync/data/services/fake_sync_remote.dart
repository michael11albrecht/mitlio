import 'dart:collection';

import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory server for tests and DebugDrive (ADR-27 §4). It implements the
/// rules the app depends on, mirroring the migrations:
/// - membership (0001 RLS): writes to a group the account is not in fail with
///   [NotMember]. Pushing a new group row only records its creator; the
///   creator becomes a member through [bootstrapMembership] (policy
///   `group_memberships_insert`), and every other write needs that first;
/// - foreign keys (0001): a row pointing at a parent the server does not hold
///   is `Rejected('foreign_key_violation')`, so a wrongly ordered push shows;
/// - `enforce_lww` (0001): a backwards `updated_at` is [PushOutcome.stale]
///   (equal is a replay and allowed);
/// - `upsert_expense` (0002): `applied=false` on a stale HLC, payer and share
///   sums, members of the group;
/// - one global `server_seq`, bumped on every write.
/// Failures are scripted with [failNext], [offline] and [fail].
class FakeSyncRemote implements SyncRemote {
  FakeSyncRemote({this.userId = 'user-1'})
    : _tables = {},
      _members = {},
      _creators = {},
      _seq = _Seq();

  /// Another view onto the same server as a different account.
  FakeSyncRemote.sharing(FakeSyncRemote other, {required this.userId})
    : _tables = other._tables,
      _members = other._members,
      _creators = other._creators,
      _seq = other._seq;

  /// The signed-in account of this client.
  final String userId;

  final Map<String, Map<String, Map<String, Object?>>> _tables;
  final Map<String, Set<String>> _members;
  final Map<String, String> _creators;
  final _Seq _seq;

  /// While true every call fails with [Offline] (the server never answers).
  bool offline = false;

  /// While set, every call fails with this (e.g. [ServerDown]).
  RemoteError? fail;

  final Queue<RemoteError> _scripted = Queue();

  /// Every write that reached the server, as `table:id` in arrival order
  /// (scripted failures are not recorded).
  final List<String> received = [];

  /// Calls attempted, including failed ones.
  int calls = 0;

  /// Makes the next [times] calls fail with [error], then behaves normally.
  void failNext(RemoteError error, {int times = 1}) {
    for (var i = 0; i < times; i++) {
      _scripted.add(error);
    }
  }

  /// Removes [userId]'s account from [groupId] (the owner removed it).
  void removeMember(String groupId, {String? user}) =>
      _members[groupId]?.remove(user ?? userId);

  /// Adds an account to [groupId] (what `join_group` does).
  void addMember(String groupId, {String? user}) =>
      (_members[groupId] ??= {}).add(user ?? userId);

  /// Whether [user] (default: this client's account) is a member of
  /// [groupId].
  bool hasMember(String groupId, {String? user}) =>
      _members[groupId]?.contains(user ?? userId) ?? false;

  /// The row `table`/`id` as the server holds it, or null.
  Map<String, Object?>? row(String table, String id) => _tables[table]?[id];

  /// Number of rows in [table].
  int count(String table) => _tables[table]?.length ?? 0;

  RemoteError? _gate() {
    calls++;
    if (offline) return const Offline();
    if (_scripted.isNotEmpty) return _scripted.removeFirst();
    return fail;
  }

  @override
  Future<Result<PushOutcome, RemoteError>> upsertRows(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    var outcome = PushOutcome.applied;
    for (final row in rows) {
      final result = _upsertRow(table, row);
      switch (result) {
        case Err(:final error):
          return Err(error);
        case Ok(:final value):
          if (value == PushOutcome.stale) outcome = PushOutcome.stale;
      }
    }
    return Ok(outcome);
  }

  Result<PushOutcome, RemoteError> _upsertRow(
    String table,
    Map<String, Object?> row,
  ) {
    final id = row[DbGroupsCols.id]! as String;
    final isGroup = table == DbTables.groups;
    final groupId = isGroup ? id : row[DbMembersCols.groupId]! as String;
    final tableRows = _tables[table] ??= {};
    final existing = tableRows[id];

    if (isGroup && !_groupExists(groupId)) {
      // groups_insert: created_by = auth.uid(). Not a member yet.
      _creators[groupId] = userId;
      tableRows[id] = {...row, DbGroupsCols.serverSeq: ++_seq.value};
      received.add('$table:$id');
      return const Ok(PushOutcome.applied);
    }
    if (!_isMember(groupId)) {
      // A replayed insert of the creator before its bootstrap (the real
      // remote treats the duplicate key as done).
      if (isGroup && _creators[groupId] == userId) {
        return const Ok(PushOutcome.applied);
      }
      return const Err(NotMember());
    }
    if (!isGroup && !_groupExists(groupId)) return const Err(_fk);
    final missing = _missingParent(table, row);
    if (missing) return const Err(_fk);

    if (existing != null) {
      final old = existing[DbGroupsCols.updatedAt]! as String;
      final next = row[DbGroupsCols.updatedAt]! as String;
      if (next.compareTo(old) < 0) return const Ok(PushOutcome.stale);
    }
    tableRows[id] = {
      ...?existing,
      ...row,
      DbGroupsCols.serverSeq: ++_seq.value,
    };
    received.add('$table:$id');
    return const Ok(PushOutcome.applied);
  }

  @override
  Future<Result<PushOutcome, RemoteError>> upsertExpense(
    Map<String, Object?> payload,
  ) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    final id = payload[DbExpensesCols.id]! as String;
    final groupId = payload[DbExpensesCols.groupId]! as String;
    if (!_isMember(groupId)) return const Err(NotMember());
    final payers = _list(payload['payers']);
    final shares = _list(payload['shares']);
    if (payers.isEmpty || shares.isEmpty) {
      return const Err(Rejected('invalid_payload'));
    }
    final amount = payload[DbExpensesCols.amountCents]! as int;
    final groupAmount = payload[DbExpensesCols.groupAmountCents]! as int;
    if (amount <= 0 || groupAmount <= 0) {
      return const Err(Rejected('amount_not_positive'));
    }
    if (_sum(payers, DbExpensePayersCols.paidCents) != amount) {
      return const Err(Rejected('payers_sum_mismatch'));
    }
    if (_sum(shares, DbExpenseSharesCols.shareCents) != groupAmount) {
      return const Err(Rejected('shares_sum_mismatch'));
    }
    final inGroup = (_tables[DbTables.members] ?? {}).values
        .where((m) => m[DbMembersCols.groupId] == groupId)
        .map((m) => m[DbMembersCols.id])
        .toSet();
    for (final c in [...payers, ...shares]) {
      if (!inGroup.contains(c[DbExpensePayersCols.memberId])) {
        return const Err(Rejected('member_not_in_group'));
      }
    }
    final expenses = _tables[DbTables.expenses] ??= {};
    final existing = expenses[id];
    if (existing != null &&
        (existing[DbExpensesCols.updatedAt]! as String).compareTo(
              payload[DbExpensesCols.updatedAt]! as String,
            ) >=
            0) {
      return const Ok(PushOutcome.stale);
    }
    final seq = ++_seq.value;
    expenses[id] = {
      for (final e in payload.entries)
        if (e.key != 'payers' && e.key != 'shares') e.key: e.value,
      DbExpensesCols.serverSeq: seq,
    };
    (_tables[DbTables.expensePayers] ??= {})[id] = {
      'rows': [
        for (final p in payers) {...p, DbExpensePayersCols.expenseId: id},
      ],
    };
    (_tables[DbTables.expenseShares] ??= {})[id] = {
      'rows': [
        for (final s in shares) {...s, DbExpenseSharesCols.expenseId: id},
      ],
    };
    received.add('${DbTables.expenses}:$id');
    return const Ok(PushOutcome.applied);
  }

  @override
  Future<Result<List<Map<String, Object?>>, RemoteError>> pullChanges({
    required String groupId,
    required String table,
    required int afterSeq,
    required int limit,
  }) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    if (!_isMember(groupId)) return const Err(NotMember());
    final isGroup = table == DbTables.groups;
    final rows =
        (_tables[table] ?? {}).values
            .where(
              (r) =>
                  (isGroup ? r[DbGroupsCols.id] : r[DbMembersCols.groupId]) ==
                      groupId &&
                  (r[DbGroupsCols.serverSeq]! as int) > afterSeq,
            )
            .toList()
          ..sort(
            (a, b) => (a[DbGroupsCols.serverSeq]! as int).compareTo(
              b[DbGroupsCols.serverSeq]! as int,
            ),
          );
    return Ok([
      for (final r in rows.take(limit)) Map<String, Object?>.of(r),
    ]);
  }

  @override
  Future<Result<Map<String, ExpenseChildren>, RemoteError>>
  fetchExpenseChildren(List<String> expenseIds) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    final result = <String, ExpenseChildren>{};
    for (final id in expenseIds) {
      final expense = _tables[DbTables.expenses]?[id];
      if (expense == null ||
          !_isMember(expense[DbExpensesCols.groupId]! as String)) {
        continue;
      }
      result[id] = ExpenseChildren(
        payers: _list(_tables[DbTables.expensePayers]?[id]?['rows']),
        shares: _list(_tables[DbTables.expenseShares]?[id]?['rows']),
      );
    }
    return Ok(result);
  }

  @override
  Future<Result<bool, RemoteError>> bootstrapMembership(String groupId) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    if (_isMember(groupId)) return const Ok(false);
    // can_bootstrap_group: own group, not deleted, no membership yet.
    final group = _tables[DbTables.groups]?[groupId];
    if (group == null ||
        _creators[groupId] != userId ||
        group[DbGroupsCols.deletedAt] != null ||
        (_members[groupId]?.isNotEmpty ?? false)) {
      return const Err(NotMember());
    }
    addMember(groupId);
    return const Ok(true);
  }

  // -- rules ----------------------------------------------------------------

  static const _fk = Rejected('foreign_key_violation');

  bool _isMember(String groupId) =>
      _members[groupId]?.contains(userId) ?? false;

  bool _groupExists(String groupId) =>
      _tables[DbTables.groups]?.containsKey(groupId) ?? false;

  bool _has(String table, Object? id) =>
      id == null || (_tables[table]?.containsKey(id) ?? false);

  /// Foreign keys of 0001 (child column -> parent table); the same list the
  /// push order is derived from.
  bool _missingParent(String table, Map<String, Object?> r) => switch (table) {
    DbTables.rideTemplates =>
      !_has(DbTables.vehicles, r[DbRideTemplatesCols.vehicleId]) ||
          !_has(DbTables.members, r[DbRideTemplatesCols.defaultDriverId]),
    DbTables.rides =>
      !_has(DbTables.vehicles, r[DbRidesCols.vehicleId]) ||
          !_has(DbTables.members, r[DbRidesCols.driverId]) ||
          !_has(DbTables.expenses, r[DbRidesCols.settledExpenseId]),
    DbTables.settlements =>
      !_has(DbTables.members, r[DbSettlementsCols.fromMember]) ||
          !_has(DbTables.members, r[DbSettlementsCols.toMember]),
    _ => false,
  };

  static List<Map<String, Object?>> _list(Object? v) => [
    for (final e in (v as List<Object?>? ?? const []))
      Map<String, Object?>.of(e! as Map<String, Object?>),
  ];

  static int _sum(List<Map<String, Object?>> rows, String col) =>
      rows.fold(0, (a, r) => a + (r[col]! as int));
}

/// Shared mutable `server_seq` counter.
class _Seq {
  int value = 0;
}
