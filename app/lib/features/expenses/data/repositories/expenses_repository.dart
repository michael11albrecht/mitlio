// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// User input for creating or replacing an expense. Validated by the domain
/// (`Expense.create`) inside the repository.
final class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.amountCents,
    required this.currency,
    required this.date,
    required this.payers,
    required this.split,
    this.category,
  });

  final String title;
  final int amountCents;

  /// Must equal the group currency (foreign currencies land with FX, later).
  final Currency currency;
  final DateTime date;

  /// Member id to paid cents.
  final Map<String, int> payers;
  final SplitSpec split;
  final String? category;
}

/// A stored expense: the validated domain aggregate plus what it needs for
/// re-editing and display. [split] is normalised: participants with weight 0
/// are omitted.
final class ExpenseEntry {
  const ExpenseEntry({
    required this.groupId,
    required this.expense,
    required this.split,
    required this.createdAt,
    this.category,
  });

  final String groupId;
  final Expense expense;
  final SplitSpec split;
  final String? category;

  /// UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is ExpenseEntry &&
      other.groupId == groupId &&
      other.expense == expense &&
      other.split == split &&
      other.category == category &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(groupId, expense, split, category, createdAt);

  @override
  String toString() => 'ExpenseEntry($groupId, ${expense.title})';
}

/// Source of truth for expenses. Lists are ordered by date descending, then
/// id descending.
abstract interface class ExpensesRepository {
  /// Live expenses of [groupId]; emits the current list first, then after
  /// every change. A corrupted stored row surfaces as a [RepositoryError]
  /// stream error, never as an invalid aggregate.
  Stream<List<ExpenseEntry>> watchExpenses(String groupId);

  Future<RepoResult<ExpenseEntry>> get(String id);

  /// [NotFound] if the group is missing; [InvalidData] for domain violations
  /// (empty title, bad split, payers mismatch, unknown member, foreign
  /// currency).
  Future<RepoResult<ExpenseEntry>> create(String groupId, ExpenseDraft draft);

  /// Replaces the whole aggregate (payers and shares included).
  Future<RepoResult<ExpenseEntry>> update(String id, ExpenseDraft draft);

  /// Soft delete; call the returned [Undo] to bring the expense back.
  Future<RepoResult<Undo>> softDelete(String id);

  /// [NotFound] for unknown ids, [Conflict] if the expense is not deleted.
  Future<RepoResult<void>> restore(String id);
}

/// Validates [draft] against the domain. Shared by every implementation so
/// they reject exactly the same inputs.
RepoResult<Expense> buildExpense({
  required String id,
  required ExpenseDraft draft,
  required Currency groupCurrency,
  required List<Member> members,
}) {
  if (draft.currency != groupCurrency) {
    return Err(
      InvalidData(
        'currency ${draft.currency.code} differs from group currency '
        '${groupCurrency.code}',
      ),
    );
  }
  return switch (Expense.create(
    id: id,
    title: draft.title,
    amountCents: draft.amountCents,
    currency: draft.currency,
    date: draft.date.toUtc(),
    payers: draft.payers,
    split: draft.split,
    members: members,
  )) {
    Ok<Expense, ExpenseError>(:final value) => Ok(value),
    Err<Expense, ExpenseError>(:final error) => Err(InvalidData('$error')),
  };
}

/// Persisted name of the split mode (`expenses.split_mode`).
String splitModeOf(SplitSpec split) => switch (split) {
  EqualSplit() => 'equal',
  SharesSplit() => 'shares',
  PercentSplit() => 'percent',
  ExactSplit() => 'exact',
};

/// Per-member weight persisted in `expense_shares.weight` so the split can be
/// re-edited: 1/0 for equal, weights, basis points or exact cents otherwise.
int splitWeightOf(SplitSpec split, String memberId) => switch (split) {
  EqualSplit(:final participants) => participants.contains(memberId) ? 1 : 0,
  SharesSplit(:final weights) => weights[memberId] ?? 0,
  PercentSplit(:final basisPoints) => basisPoints[memberId] ?? 0,
  ExactSplit(:final cents) => cents[memberId] ?? 0,
};

/// Inverse of [splitModeOf] / [splitWeightOf]; null for an unknown [mode].
SplitSpec? splitFromWeights(String mode, Map<String, int> weights) {
  final active = {
    for (final e in weights.entries)
      if (e.value > 0) e.key: e.value,
  };
  return switch (mode) {
    'equal' => EqualSplit(active.keys.toSet()),
    'shares' => SharesSplit(active),
    'percent' => PercentSplit(active),
    'exact' => ExactSplit(active),
    _ => null,
  };
}
