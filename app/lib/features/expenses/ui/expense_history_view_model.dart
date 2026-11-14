import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/expense_revision.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

// The View renders the diff, so it names these change types.
export 'package:mitlio/features/expenses/data/expense_revision.dart'
    show
        AmountChange,
        CategoryChange,
        DateChange,
        ExpenseChange,
        PaidChange,
        ParticipantAdded,
        ParticipantRemoved,
        PayerAdded,
        PayerRemoved,
        RateChange,
        ShareChange,
        SplitModeChange,
        TitleChange,
        TripDetailsChange;

/// One entry of the history sheet: what a single change did.
final class ExpenseHistoryItem {
  const ExpenseHistoryItem({
    required this.revisionId,
    required this.revision,
    required this.changedAt,
    required this.changes,
    this.authorName,
  });

  final String revisionId;
  final int revision;

  /// UTC.
  final DateTime changedAt;

  /// Null while nobody is signed in (no accounts yet).
  final String? authorName;

  /// Fields that differ between the state before this change and the state
  /// after it. Empty for a delete that was undone.
  final List<ExpenseChange> changes;
}

sealed class ExpenseHistoryState {
  const ExpenseHistoryState();
}

final class ExpenseHistoryLoading extends ExpenseHistoryState {
  const ExpenseHistoryLoading();
}

final class ExpenseHistoryFailure extends ExpenseHistoryState {
  const ExpenseHistoryFailure(this.error);

  final RepositoryError error;
}

final class ExpenseHistoryLoaded extends ExpenseHistoryState {
  const ExpenseHistoryLoaded({
    required this.items,
    required this.currency,
    required this.memberNames,
  });

  /// Newest first.
  final List<ExpenseHistoryItem> items;

  /// The group currency, for share lines.
  final Currency currency;

  /// Member id to name, deleted members included.
  final Map<String, String> memberNames;

  bool get isEmpty => items.isEmpty;
}

/// "Verlauf" of one expense: the changes newest first, each with its diff,
/// and "restore this version".
class ExpenseHistoryViewModel extends Notifier<ExpenseHistoryState> {
  ExpenseHistoryViewModel(this.expenseId);

  final String expenseId;

  @override
  ExpenseHistoryState build() {
    unawaited(Future.microtask(_load));
    return const ExpenseHistoryLoading();
  }

  Future<void> _load() async {
    final expenses = ref.read(expensesRepositoryProvider);
    final entry = switch (await expenses.get(expenseId)) {
      Ok<ExpenseEntry, RepositoryError>(:final value) => value,
      Err<ExpenseEntry, RepositoryError>(:final error) => _fail(error),
    };
    if (entry == null) return;
    final history = switch (await expenses.revisions(expenseId)) {
      Ok<List<ExpenseRevision>, RepositoryError>(:final value) => value,
      Err<List<ExpenseRevision>, RepositoryError>(:final error) => _fail(error),
    };
    if (history == null) return;
    final members = switch (await ref
        .read(membersRepositoryProvider)
        .list(entry.groupId, includeDeleted: true)) {
      Ok<List<GroupMember>, RepositoryError>(:final value) => value,
      Err<List<GroupMember>, RepositoryError>(:final error) => _fail(error),
    };
    if (members == null || !ref.mounted) return;
    final names = {for (final m in members) m.id: m.name};
    final items = <ExpenseHistoryItem>[];
    // Each change is diffed against the state that followed it: the next
    // newer snapshot, or the live expense for the newest change.
    var after = snapshotOfEntry(entry);
    for (final r in history) {
      items.add(
        ExpenseHistoryItem(
          revisionId: r.id,
          revision: r.revision,
          changedAt: r.changedAt,
          authorName: names[r.authorMemberId],
          changes: diffSnapshots(r.snapshot, after),
        ),
      );
      after = r.snapshot;
    }
    state = ExpenseHistoryLoaded(
      items: List.unmodifiable(items),
      currency: entry.expense.currency,
      memberNames: names,
    );
  }

  /// Publishes the failure; always returns null so callers can bail out.
  Never? _fail(RepositoryError error) {
    if (ref.mounted) state = ExpenseHistoryFailure(error);
    return null;
  }

  void retry() {
    state = const ExpenseHistoryLoading();
    unawaited(_load());
  }

  /// Puts the expense back to the state before [revisionId] changed it, as a
  /// normal update (which adds a revision of its own). The returned [Undo]
  /// reverts the restore.
  Future<RepoResult<Undo>> restore(String revisionId) => ref
      .read(expensesRepositoryProvider)
      .restoreRevision(expenseId, revisionId);

  /// The history as of now (for DebugDrive; the UI watches the state).
  Future<RepoResult<List<ExpenseRevision>>> list() =>
      ref.read(expensesRepositoryProvider).revisions(expenseId);

  JsonMap debugSnapshot() => switch (state) {
    ExpenseHistoryLoading() => {'status': 'loading', 'expenseId': expenseId},
    ExpenseHistoryFailure(:final error) => {
      'status': 'error',
      'expenseId': expenseId,
      'error': error.toString(),
    },
    ExpenseHistoryLoaded(:final items) => {
      'status': items.isEmpty ? 'empty' : 'data',
      'expenseId': expenseId,
      'revisions': [
        for (final i in items)
          {
            'id': i.revisionId,
            'revision': i.revision,
            'changedAt': i.changedAt.toIso8601String(),
            'changes': i.changes.length,
          },
      ],
    },
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final expenseHistoryViewModelProvider =
    NotifierProvider.family<
      ExpenseHistoryViewModel,
      ExpenseHistoryState,
      String
    >(ExpenseHistoryViewModel.new);
