// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/recurring/data/repositories/recurring_providers.dart';
import 'package:mitlio/features/recurring/data/repositories/recurring_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// One rule that could not make an expense, and why.
final class RecurringFailureNote {
  const RecurringFailureNote(this.title, this.error);

  final String title;
  final RepositoryError error;

  @override
  bool operator ==(Object other) =>
      other is RecurringFailureNote &&
      other.title == title &&
      other.error == error;

  @override
  int get hashCode => Object.hash(title, error);
}

/// What one catch-up run did.
final class RecurringCatchUpNotice {
  const RecurringCatchUpNotice({
    this.created = 0,
    this.skipped = 0,
    this.failures = const [],
  });

  /// Expenses made.
  final int created;

  /// Due dates left out because more than 12 were due (the domain cap).
  final int skipped;
  final List<RecurringFailureNote> failures;

  bool get isEmpty => created == 0 && skipped == 0 && failures.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is RecurringCatchUpNotice &&
      other.created == created &&
      other.skipped == skipped &&
      other.failures.length == failures.length &&
      Iterable<int>.generate(
        failures.length,
      ).every((i) => failures[i] == other.failures[i]);

  @override
  int get hashCode => Object.hash(created, skipped, failures.length);
}

/// Makes the expenses that recurring rules owe, on app start and when the app
/// comes back to the foreground. State is the news worth telling the user
/// (null while there is none); the host shows it and calls [consume].
class RecurringCatchUpViewModel extends Notifier<RecurringCatchUpNotice?> {
  var _running = false;

  @override
  RecurringCatchUpNotice? build() => null;

  /// The notice was shown.
  void consume() => state = null;

  /// Creates every due expense of every active rule, oldest first, at most
  /// 12 per rule. Never throws: failures are returned (and
  /// published) as notes. A run that starts while another one is going does
  /// nothing.
  Future<RecurringCatchUpNotice> run() async {
    if (_running) return const RecurringCatchUpNotice();
    _running = true;
    try {
      final notice = await _run();
      if (ref.mounted && !notice.isEmpty) state = notice;
      return notice;
    } on Object catch (e) {
      final notice = RecurringCatchUpNotice(
        failures: [
          RecurringFailureNote('', e is RepositoryError ? e : Storage(e)),
        ],
      );
      if (ref.mounted) state = notice;
      return notice;
    } finally {
      _running = false;
    }
  }

  Future<RecurringCatchUpNotice> _run() async {
    final repository = ref.read(recurringRepositoryProvider);
    final all = await repository.all();
    if (all case Err(:final error)) {
      return RecurringCatchUpNotice(
        failures: [RecurringFailureNote('', error)],
      );
    }
    final now = ref.read(clockProvider).now();
    final today = DateTime.utc(now.year, now.month, now.day);
    var created = 0;
    var skipped = 0;
    final failures = <RecurringFailureNote>[];
    for (final rule
        in (all as Ok<List<RecurringExpense>, RepositoryError>).value) {
      if (rule.paused) continue;
      final dates = rule.due(today);
      if (dates.isEmpty) continue;
      // A group that is gone or archived has nothing to add to: its rules
      // wait (no error: the user did that on purpose).
      final group = await ref.read(groupsRepositoryProvider).get(rule.groupId);
      if (group case Err(error: NotFound())) continue;
      if (group case Err(:final error)) {
        failures.add(RecurringFailureNote(rule.title, error));
        continue;
      }
      final currency = (group as Ok<Group, RepositoryError>).value.currency;
      skipped +=
          rule.rule
              .dueOccurrences(
                lastGenerated: rule.lastGenerated,
                today: today,
                maxCount: 1 << 20,
              )
              .length -
          dates.length;
      for (final date in dates) {
        final made = await _make(rule, currency, date);
        if (made case final error?) {
          failures.add(RecurringFailureNote(rule.title, error));
          break;
        }
        created++;
      }
    }
    return RecurringCatchUpNotice(
      created: created,
      skipped: skipped,
      failures: failures,
    );
  }

  /// One expense for [date], then the bookkeeping. If the bookkeeping fails
  /// the expense is taken back, so the next run does not make it twice.
  Future<RepositoryError?> _make(
    RecurringExpense rule,
    Currency currency,
    DateTime date,
  ) async {
    final expenses = ref.read(expensesRepositoryProvider);
    final made = await expenses.create(
      rule.groupId,
      ExpenseDraft(
        title: rule.title,
        amountCents: rule.amountCents,
        currency: currency,
        date: date,
        payers: rule.payers,
        split: rule.split,
        category: rule.category,
      ),
    );
    if (made case Err(:final error)) return error;
    final entry = (made as Ok<ExpenseEntry, RepositoryError>).value;
    final marked = await ref
        .read(recurringRepositoryProvider)
        .markGenerated(rule.id, date);
    if (marked case Err(:final error)) {
      final undone = await expenses.softDelete(entry.expense.id);
      // Both failed: the user must see that an expense may exist twice later.
      return undone is Err
          ? (undone as Err<Undo, RepositoryError>).error
          : error;
    }
    return null;
  }

  JsonMap debugSnapshot() => {
    'pending': state == null
        ? null
        : {
            'created': state!.created,
            'skipped': state!.skipped,
            'failures': [
              for (final f in state!.failures)
                {'title': f.title, 'error': f.error.toString()},
            ],
          },
  };
}

final recurringCatchUpViewModelProvider =
    NotifierProvider<RecurringCatchUpViewModel, RecurringCatchUpNotice?>(
      RecurringCatchUpViewModel.new,
    );
