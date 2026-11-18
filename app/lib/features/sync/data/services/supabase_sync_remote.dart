import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_mapper.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _membershipsTable = 'group_memberships';
const _uniqueViolation = '23505';

/// Name of the RPC that upserts an expense with payers and shares.
const upsertExpenseRpc = 'upsert_expense';

/// [SyncRemote] on Supabase: PostgREST for single-row tables, the
/// `upsert_expense` RPC for expenses. Every failure goes through the
/// `core/remote` mapper; a stale write (LWW) is an [PushOutcome.stale], not an
/// error.
class SupabaseSyncRemote implements SyncRemote {
  const SupabaseSyncRemote(this._backend);

  final RemoteBackend _backend;

  static const _unavailable = Rejected('backend_unavailable');

  @override
  Future<Result<PushOutcome, RemoteError>> upsertRows(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      if (table == DbTables.groups) {
        for (final row in rows) {
          await _upsertGroup(client, row);
        }
      } else {
        await client.from(table).upsert(rows, onConflict: DbGroupsCols.id);
      }
      return const Ok(PushOutcome.applied);
    } on Object catch (e) {
      return _outcomeOrError(e);
    }
  }

  /// A group cannot go through `upsert(onConflict: id)`: the insert half needs
  /// `created_by` (not null, RLS `created_by = auth.uid()`) and an upsert by a
  /// non-owner member would overwrite it. So update first (members may
  /// rename); only when no row was visible, insert with the caller as creator.
  Future<void> _upsertGroup(
    SupabaseClient client,
    Map<String, Object?> row,
  ) async {
    final id = row[DbGroupsCols.id]! as String;
    final updated = await client
        .from(DbTables.groups)
        .update(row)
        .eq(DbGroupsCols.id, id)
        .select(DbGroupsCols.id);
    if (updated.isNotEmpty) return;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw const _NotSignedIn();
    }
    try {
      await client.from(DbTables.groups).insert({
        ...row,
        DbGroupsCols.createdBy: uid,
      });
    } on PostgrestException catch (e) {
      // A replay: the first insert reached the server but its answer was
      // lost, and the creator is not a member until the bootstrap, so the
      // update above could not see the row. Only the creator's own row
      // counts; anything else stays an error.
      if (e.code != _uniqueViolation || !await _isOwnGroup(client, id, uid)) {
        rethrow;
      }
    }
  }

  Future<bool> _isOwnGroup(SupabaseClient client, String id, String uid) async {
    final rows = await client
        .from(DbTables.groups)
        .select(DbGroupsCols.id)
        .eq(DbGroupsCols.id, id)
        .eq(DbGroupsCols.createdBy, uid);
    return rows.isNotEmpty;
  }

  @override
  Future<Result<bool, RemoteError>> bootstrapMembership(String groupId) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final uid = client.auth.currentUser?.id;
      if (uid == null) throw const _NotSignedIn();
      // Checked first: for an existing member the bootstrap policy refuses
      // the insert (42501), which would look like "removed".
      final mine = await client
          .from(_membershipsTable)
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', uid);
      if (mine.isNotEmpty) return const Ok(false);
      await client.from(_membershipsTable).insert({
        'group_id': groupId,
        'user_id': uid,
      });
      return const Ok(true);
    } on Object catch (e) {
      return Err(_map(e));
    }
  }

  @override
  Future<Result<PushOutcome, RemoteError>> upsertExpense(
    Map<String, Object?> payload,
  ) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final result = await client.rpc<Object?>(
        upsertExpenseRpc,
        params: {'payload': payload},
      );
      final applied =
          result is Map<String, Object?> && result['applied'] == true;
      return Ok(applied ? PushOutcome.applied : PushOutcome.stale);
    } on Object catch (e) {
      return _outcomeOrError(e);
    }
  }

  @override
  Future<Result<List<Map<String, Object?>>, RemoteError>> pullChanges({
    required String groupId,
    required String table,
    required int afterSeq,
    required int limit,
  }) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final rows = await client
          .from(table)
          .select()
          .eq(table == DbTables.groups ? DbGroupsCols.id : 'group_id', groupId)
          .gt(DbGroupsCols.serverSeq, afterSeq)
          .order(DbGroupsCols.serverSeq, ascending: true)
          .limit(limit);
      return Ok([for (final r in rows) Map<String, Object?>.of(r)]);
    } on Object catch (e) {
      return Err(_map(e));
    }
  }

  @override
  Future<Result<Map<String, ExpenseChildren>, RemoteError>>
  fetchExpenseChildren(List<String> expenseIds) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    if (expenseIds.isEmpty) return const Ok({});
    try {
      final payers = await client
          .from(DbTables.expensePayers)
          .select()
          .inFilter(DbExpensePayersCols.expenseId, expenseIds);
      final shares = await client
          .from(DbTables.expenseShares)
          .select()
          .inFilter(DbExpenseSharesCols.expenseId, expenseIds);
      return Ok({
        for (final id in expenseIds)
          id: ExpenseChildren(
            payers: [
              for (final p in payers)
                if (p[DbExpensePayersCols.expenseId] == id)
                  Map<String, Object?>.of(p),
            ],
            shares: [
              for (final s in shares)
                if (s[DbExpenseSharesCols.expenseId] == id)
                  Map<String, Object?>.of(s),
            ],
          ),
      });
    } on Object catch (e) {
      return Err(_map(e));
    }
  }

  SupabaseClient? get _client => switch (_backend.client()) {
    Ok(:final value) => value,
    Err() => null,
  };

  Result<PushOutcome, RemoteError> _outcomeOrError(Object e) =>
      isStaleWriteException(e) ? const Ok(PushOutcome.stale) : Err(_map(e));

  RemoteError _map(Object e) => e is _NotSignedIn
      ? const Rejected('not_authenticated')
      : fromException(e);
}

class _NotSignedIn implements Exception {
  const _NotSignedIn();
}
