import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/recurring/data/recurring_models.dart';

export 'package:mitlio/features/recurring/data/recurring_models.dart'
    show RecurringDraft, RecurringExpense;

/// Recurring expense rules. Local only for v1 (P9-T03): nothing here syncs,
/// "delete my data" wipes the table with the rest of the database. The
/// expenses a rule creates go through the normal `ExpensesRepository`.
abstract interface class RecurringRepository {
  /// The rules of [groupId], oldest first.
  Stream<List<RecurringExpense>> watchRules(String groupId);

  /// Every rule of every group, oldest first.
  Future<RepoResult<List<RecurringExpense>>> all();

  /// Stores a new rule. Rejects a blank title or a non-positive amount
  /// (`InvalidData`).
  Future<RepoResult<RecurringExpense>> create(
    String groupId,
    RecurringDraft draft,
  );

  /// Replaces what the rule creates and when. Keeps what was generated
  /// already (`lastGenerated`) and the paused flag.
  Future<RepoResult<RecurringExpense>> update(String id, RecurringDraft draft);

  /// Pauses or resumes. [lastGenerated] (resume only) moves the bookkeeping
  /// forward so dates that passed while paused are not made up.
  Future<RepoResult<RecurringExpense>> setPaused(
    String id, {
    required bool paused,
    DateTime? lastGenerated,
  });

  /// Records that an expense now exists for [date].
  Future<RepoResult<RecurringExpense>> markGenerated(String id, DateTime date);

  /// Deletes the rule (the expenses it made stay); the [Undo] puts it back.
  Future<RepoResult<Undo>> delete(String id);
}
