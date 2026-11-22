import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/recurring/data/recurring_models.dart'
    show recurringDay;
import 'package:mitlio/features/recurring/data/repositories/recurring_providers.dart';
import 'package:mitlio/features/recurring/data/repositories/recurring_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

export 'package:mitlio/features/recurring/data/repositories/recurring_repository.dart'
    show RecurringDraft, RecurringExpense;

sealed class RecurringState {
  const RecurringState();
}

final class RecurringLoading extends RecurringState {
  const RecurringLoading();
}

final class RecurringFailure extends RecurringState {
  const RecurringFailure(this.error);

  final RepositoryError error;
}

/// The rules of one group, oldest first.
final class RecurringLoaded extends RecurringState {
  const RecurringLoaded({
    required this.group,
    required this.rules,
    required this.today,
  });

  final Group group;
  final List<RecurringExpense> rules;

  /// Midnight UTC of the current day (from the injected clock).
  final DateTime today;

  bool get isEmpty => rules.isEmpty;
}

/// "Wiederkehrende Ausgaben" of one group: create, edit, pause and delete a
/// rule. Generating the expenses is the job of `RecurringCatchUpViewModel`.
class RecurringViewModel extends Notifier<RecurringState> {
  RecurringViewModel(this.groupId);

  final String groupId;

  Group? _group;
  List<RecurringExpense>? _rules;
  RepositoryError? _failure;

  @override
  RecurringState build() {
    _group = null;
    _rules = null;
    _failure = null;
    final sub = ref
        .watch(recurringRepositoryProvider)
        .watchRules(groupId)
        .listen(
          (rules) {
            _rules = rules;
            _emit();
          },
          onError: (Object e) {
            _failure = e is RepositoryError ? e : Storage(e);
            _emit();
          },
        );
    ref.onDispose(() => unawaited(sub.cancel()));
    unawaited(_loadGroup());
    return const RecurringLoading();
  }

  Future<void> _loadGroup() async {
    try {
      final got = await ref.read(groupsRepositoryProvider).get(groupId);
      if (!ref.mounted) return;
      switch (got) {
        case Ok(:final value):
          _group = value;
        case Err(:final error):
          _failure = error;
      }
    } on Object catch (e) {
      _failure = e is RepositoryError ? e : Storage(e);
    }
    _emit();
  }

  DateTime _today() {
    final now = ref.read(clockProvider).now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  void _emit() {
    if (!ref.mounted) return;
    final rules = _rules;
    final group = _group;
    if (_failure != null) {
      state = RecurringFailure(_failure!);
    } else if (rules == null || group == null) {
      state = const RecurringLoading();
    } else {
      state = RecurringLoaded(group: group, rules: rules, today: _today());
    }
  }

  void retry() {
    state = const RecurringLoading();
    ref.invalidateSelf();
  }

  /// The domain's verdict on what [draft] would create: the same checks as
  /// for a single expense, so a rule can never hold something that would
  /// fail on every start.
  Future<RepositoryError?> _check(RecurringDraft draft) async {
    final group = await ref.read(groupsRepositoryProvider).get(groupId);
    if (group case Err(:final error)) return error;
    final members = await ref.read(membersRepositoryProvider).list(groupId);
    if (members case Err(:final error)) return error;
    final created = Expense.create(
      id: 'preview',
      title: draft.title,
      amountCents: draft.amountCents,
      currency: (group as Ok<Group, RepositoryError>).value.currency,
      date: draft.rule.start,
      payers: draft.payers,
      split: draft.split,
      members: [
        for (final m
            in (members as Ok<List<GroupMember>, RepositoryError>).value)
          m.toDomain(),
      ],
    );
    return created is Err<Expense, ExpenseError>
        ? InvalidData(created.error.toString())
        : null;
  }

  /// Validates and stores a new rule. It creates nothing by itself; the next
  /// catch-up does.
  Future<RepoResult<RecurringExpense>> create(RecurringDraft draft) async {
    if (await _check(draft) case final error?) return Err(error);
    return ref.read(recurringRepositoryProvider).create(groupId, draft);
  }

  /// Replaces what rule [id] creates and when; what it generated so far
  /// stays as it is.
  Future<RepoResult<RecurringExpense>> update(
    String id,
    RecurringDraft draft,
  ) async {
    if (await _check(draft) case final error?) return Err(error);
    return ref.read(recurringRepositoryProvider).update(id, draft);
  }

  /// Pauses or resumes rule [id]. Resuming skips the dates that passed
  /// meanwhile: nothing is made up. The [Undo] flips it back.
  Future<RepoResult<Undo>> setPaused(String id, {required bool paused}) async {
    final repository = ref.read(recurringRepositoryProvider);
    DateTime? skipTo;
    if (!paused) {
      final rule = await _find(id);
      if (rule case Err(:final error)) return Err(error);
      final stored = (rule as Ok<RecurringExpense, RepositoryError>).value;
      final passed = stored.rule.occurrencesBetween(
        stored.rule.start,
        _today(),
      );
      if (passed.isNotEmpty) skipTo = passed.last;
      if (skipTo != null &&
          stored.lastGenerated != null &&
          !skipTo.isAfter(stored.lastGenerated!)) {
        skipTo = null;
      }
    }
    final result = await repository.setPaused(
      id,
      paused: paused,
      lastGenerated: skipTo,
    );
    return switch (result) {
      Ok() => Ok(
        Undo(() async {
          final back = await repository.setPaused(id, paused: !paused);
          return switch (back) {
            Ok() => const Ok<void, RepositoryError>(null),
            Err(:final error) => Err<void, RepositoryError>(error),
          };
        }),
      ),
      Err(:final error) => Err(error),
    };
  }

  Future<RepoResult<RecurringExpense>> _find(String id) async {
    final all = await ref.read(recurringRepositoryProvider).all();
    if (all case Err(:final error)) return Err(error);
    final found = (all as Ok<List<RecurringExpense>, RepositoryError>).value
        .where((r) => r.id == id)
        .firstOrNull;
    return found == null ? Err(NotFound('recurring', id)) : Ok(found);
  }

  /// Deletes rule [id]; the expenses it made stay. The [Undo] puts it back.
  Future<RepoResult<Undo>> delete(String id) =>
      ref.read(recurringRepositoryProvider).delete(id);

  JsonMap debugSnapshot() => switch (state) {
    RecurringLoading() => {'status': 'loading', 'groupId': groupId},
    RecurringFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    RecurringLoaded(:final rules, :final today) => {
      'status': rules.isEmpty ? 'empty' : 'data',
      'groupId': groupId,
      'rules': [for (final r in rules) recurringJson(r, today)],
    },
  };
}

/// JSON shape of a rule in snapshots and DebugDrive results.
JsonMap recurringJson(RecurringExpense r, DateTime today) => {
  'id': r.id,
  'groupId': r.groupId,
  'title': r.title,
  'amountCents': r.amountCents,
  'payers': r.payers,
  'category': r.category,
  'frequency': r.rule.frequency.name,
  'interval': r.rule.interval,
  'start': recurringDay(r.rule.start),
  'end': r.rule.end == null ? null : recurringDay(r.rule.end!),
  'lastGenerated': r.lastGenerated == null
      ? null
      : recurringDay(r.lastGenerated!),
  'next': r.nextAfter(today) == null ? null : recurringDay(r.nextAfter(today)!),
  'paused': r.paused,
};

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final recurringViewModelProvider =
    NotifierProvider.family<RecurringViewModel, RecurringState, String>(
      RecurringViewModel.new,
    );
