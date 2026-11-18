import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What the server did with a pushed write.
enum PushOutcome {
  /// The server stored it (or already held exactly this version).
  applied,

  /// The server holds a newer version of the same row and kept it (the
  /// `enforce_lww` trigger rejected a backwards `updated_at`, or
  /// `upsert_expense` returned `applied=false`). Not an error: the next pull
  /// brings the newer version (ADR-27 §3).
  stale,
}

/// Payer and share rows of one expense, in server column names.
class ExpenseChildren {
  const ExpenseChildren({required this.payers, required this.shares});

  final List<Map<String, Object?>> payers;
  final List<Map<String, Object?>> shares;
}

/// The sync endpoints of the backend (ADR-07, ADR-27 §4). Rows are plain
/// maps in server column names (`db_contract.g.dart`). Every failure is a
/// [RemoteError]; nothing throws. The Supabase implementation is
/// `SupabaseSyncRemote`, the in-memory one `FakeSyncRemote`; both run the
/// shared contract suite.
abstract interface class SyncRemote {
  /// Upserts [rows] of a single-row [table] by `id` (PostgREST). All rows
  /// belong to one group.
  Future<Result<PushOutcome, RemoteError>> upsertRows(
    String table,
    List<Map<String, Object?>> rows,
  );

  /// Upserts one expense with its payers and shares (RPC `upsert_expense`).
  Future<Result<PushOutcome, RemoteError>> upsertExpense(
    Map<String, Object?> payload,
  );

  /// Rows of [table] in [groupId] with `server_seq > afterSeq`, ascending,
  /// at most [limit] (pull, P6-T11).
  Future<Result<List<Map<String, Object?>>, RemoteError>> pullChanges({
    required String groupId,
    required String table,
    required int afterSeq,
    required int limit,
  });

  /// Payers and shares of [expenseIds], by expense id (pull, P6-T11).
  Future<Result<Map<String, ExpenseChildren>, RemoteError>>
  fetchExpenseChildren(List<String> expenseIds);
}
