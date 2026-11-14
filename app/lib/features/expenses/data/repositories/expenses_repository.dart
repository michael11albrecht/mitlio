// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What was actually paid in a foreign currency, and the rate frozen on the
/// expense. The group-currency amount is derived from it (`convert`).
final class ForeignAmount {
  const ForeignAmount({
    required this.currency,
    required this.amountCents,
    required this.ratePpm,
  });

  final Currency currency;

  /// Minor units of [currency].
  final int amountCents;

  /// Units of the group currency per 1 [currency], times 1e6.
  final int ratePpm;

  /// The amount in [group], rounded half-even on the cent. Throws
  /// [ArgumentError] for a rate <= 0 and `MoneyOverflow` when too large.
  Money toGroup(Currency group) =>
      convert(Money(amountCents, currency), group, FxRate(ratePpm));

  @override
  bool operator ==(Object other) =>
      other is ForeignAmount &&
      other.currency == currency &&
      other.amountCents == amountCents &&
      other.ratePpm == ratePpm;

  @override
  int get hashCode => Object.hash(currency, amountCents, ratePpm);

  @override
  String toString() =>
      'ForeignAmount($amountCents ${currency.code} @ $ratePpm)';
}

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
    this.tripMeta,
    this.foreign,
  });

  final String title;

  /// In the group currency: the split and the payers are computed on it.
  final int amountCents;

  /// Must equal the group currency; a foreign payment goes in [foreign].
  final Currency currency;
  final DateTime date;

  /// Member id to paid cents.
  final Map<String, int> payers;
  final SplitSpec split;
  final String? category;

  /// JSON of the trip inputs for a trip expense (stored as type `trip`, so
  /// it can be re-edited); null for a regular expense.
  final String? tripMeta;

  /// Set when the amount was paid in another currency; `foreign.toGroup`
  /// must equal [amountCents].
  final ForeignAmount? foreign;
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
    this.tripMeta,
    this.foreign,
  });

  final String groupId;

  /// Always in the group currency.
  final Expense expense;

  /// The original amount and frozen rate of a foreign-currency expense.
  final ForeignAmount? foreign;
  final SplitSpec split;
  final String? category;

  /// See `ExpenseDraft.tripMeta`.
  final String? tripMeta;

  /// UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is ExpenseEntry &&
      other.groupId == groupId &&
      other.expense == expense &&
      other.split == split &&
      other.category == category &&
      other.tripMeta == tripMeta &&
      other.foreign == foreign &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    groupId,
    expense,
    split,
    category,
    tripMeta,
    foreign,
    createdAt,
  );

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
  final foreign = draft.foreign;
  if (foreign != null) {
    final problem = _foreignProblem(foreign, draft, groupCurrency);
    if (problem != null) return Err(InvalidData(problem));
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

String? _foreignProblem(
  ForeignAmount foreign,
  ExpenseDraft draft,
  Currency groupCurrency,
) {
  if (foreign.currency == groupCurrency) {
    return 'foreign currency equals the group currency';
  }
  if (foreign.amountCents <= 0 || foreign.ratePpm <= 0) {
    return 'foreign amount and rate must be positive';
  }
  try {
    if (foreign.toGroup(groupCurrency).cents != draft.amountCents) {
      return 'amount does not match the converted foreign amount';
    }
  } on MoneyOverflow {
    return 'foreign amount too large';
  }
  return null;
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
