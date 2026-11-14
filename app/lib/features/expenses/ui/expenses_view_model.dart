import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

// The Views name the stored expense type; they may not import data/ themselves.
export 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart'
    show ExpenseEntry;

/// Stored category keys, in the order the form offers them. The labels live
/// in the ARB files; unknown keys are shown as they are.
const expenseCategories = ['food', 'stay', 'transport', 'fun', 'other'];

/// `YYYY-MM-DD` of the UTC calendar day (the form that DebugDrive speaks).
String isoDay(DateTime date) {
  final d = date.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// All expenses of one calendar day.
final class ExpenseDay {
  const ExpenseDay({required this.date, required this.entries});

  /// Midnight UTC of the day.
  final DateTime date;
  final List<ExpenseEntry> entries;
}

sealed class ExpensesState {
  const ExpensesState();
}

final class ExpensesLoading extends ExpensesState {
  const ExpensesLoading();
}

final class ExpensesFailure extends ExpensesState {
  const ExpensesFailure(this.error);

  final RepositoryError error;
}

final class ExpensesLoaded extends ExpensesState {
  const ExpensesLoaded({
    required this.group,
    required this.members,
    required this.entries,
    required this.today,
    this.memberFilter,
    this.categoryFilter,
  });

  final Group group;

  /// In position order.
  final List<GroupMember> members;

  /// Every live expense, newest first.
  final List<ExpenseEntry> entries;

  /// Midnight UTC of the current day (from the injected clock).
  final DateTime today;
  final String? memberFilter;
  final String? categoryFilter;

  bool get hasFilter => memberFilter != null || categoryFilter != null;

  /// No expense at all (a filter that matches nothing is not empty).
  bool get isEmpty => entries.isEmpty;

  /// Entries the filters let through.
  List<ExpenseEntry> get visible => [
    for (final e in entries)
      if ((memberFilter == null ||
              e.expense.payers.containsKey(memberFilter) ||
              (e.expense.shares[memberFilter] ?? 0) > 0) &&
          (categoryFilter == null || e.category == categoryFilter))
        e,
  ];

  /// [visible] grouped by day, newest day first.
  List<ExpenseDay> get days {
    final byDay = <DateTime, List<ExpenseEntry>>{};
    for (final e in visible) {
      final d = e.expense.date.toUtc();
      byDay.putIfAbsent(DateTime.utc(d.year, d.month, d.day), () => []).add(e);
    }
    final keys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) ExpenseDay(date: k, entries: byDay[k]!)];
  }

  /// Categories in use, in the order the form offers them, then the rest.
  List<String> get categories {
    final used = {
      for (final e in entries)
        if (e.category != null) e.category!,
    };
    return [
      for (final c in expenseCategories)
        if (used.remove(c)) c,
      ...(used.toList()..sort()),
    ];
  }

  GroupMember? member(String id) =>
      members.where((m) => m.id == id).firstOrNull;
}

/// Group detail, expenses tab: the list with its filters, plus delete and the
/// add/update commands the form and DebugDrive share.
class ExpensesViewModel extends Notifier<ExpensesState> {
  ExpensesViewModel(this.groupId);

  final String groupId;

  Group? _group;
  var _groupKnown = false;
  List<GroupMember>? _members;
  List<ExpenseEntry>? _entries;
  RepositoryError? _failure;
  String? _memberFilter;
  String? _categoryFilter;

  /// Deleted by the user and gone from the list at once; kept until the
  /// repository stream confirms, or the delete fails.
  final _hidden = <String>{};

  @override
  ExpensesState build() {
    _group = null;
    _groupKnown = false;
    _members = null;
    _entries = null;
    _failure = null;
    _hidden.clear();
    final subs = [
      _listen(ref.watch(groupsRepositoryProvider).watchGroups(), (groups) {
        _group = groups.where((g) => g.id == groupId).firstOrNull;
        _groupKnown = true;
      }),
      _listen(
        ref.watch(membersRepositoryProvider).watchMembers(groupId),
        (members) => _members = members,
      ),
      _listen(
        ref.watch(expensesRepositoryProvider).watchExpenses(groupId),
        (entries) {
          _entries = entries;
          _hidden.retainAll({for (final e in entries) e.expense.id});
        },
      ),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    return const ExpensesLoading();
  }

  StreamSubscription<T> _listen<T>(Stream<T> stream, void Function(T) onData) =>
      stream.listen(
        (data) {
          onData(data);
          _emit();
        },
        onError: (Object e) {
          _failure = e is RepositoryError ? e : Storage(e);
          _emit();
        },
      );

  void _emit() {
    if (!ref.mounted) return;
    final members = _members;
    final entries = _entries;
    if (_failure != null) {
      state = ExpensesFailure(_failure!);
    } else if (!_groupKnown || members == null || entries == null) {
      state = const ExpensesLoading();
    } else if (_group == null) {
      state = ExpensesFailure(NotFound('group', groupId));
    } else {
      final now = ref.read(clockProvider).now();
      state = ExpensesLoaded(
        group: _group!,
        members: members,
        entries: [
          for (final e in entries)
            if (!_hidden.contains(e.expense.id)) e,
        ],
        today: DateTime.utc(now.year, now.month, now.day),
        memberFilter: _memberFilter,
        categoryFilter: _categoryFilter,
      );
    }
  }

  void retry() {
    state = const ExpensesLoading();
    ref.invalidateSelf();
  }

  /// Shows only expenses [memberId] paid or takes part in; null shows all.
  void setMemberFilter(String? memberId) {
    _memberFilter = memberId;
    _emit();
  }

  /// Shows only expenses of [category]; null shows all.
  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _emit();
  }

  void clearFilters() {
    _memberFilter = null;
    _categoryFilter = null;
    _emit();
  }

  /// Soft delete; the returned [Undo] brings the expense back. The row
  /// disappears at once and comes back if the repository refuses.
  Future<RepoResult<Undo>> delete(String id) async {
    _hidden.add(id);
    _emit();
    final result = await ref.read(expensesRepositoryProvider).softDelete(id);
    if (result is Err) {
      _hidden.remove(id);
      _emit();
    }
    return result;
  }

  /// Validates through the domain and stores the expense.
  Future<RepoResult<ExpenseEntry>> add(ExpenseDraft draft) =>
      ref.read(expensesRepositoryProvider).create(groupId, draft);

  /// Replaces the stored expense [id] as a whole.
  Future<RepoResult<ExpenseEntry>> update(String id, ExpenseDraft draft) =>
      ref.read(expensesRepositoryProvider).update(id, draft);

  /// The expenses as of now (for DebugDrive; the UI watches the state).
  Future<RepoResult<List<ExpenseEntry>>> list() async {
    try {
      return Ok(
        await ref.read(expensesRepositoryProvider).watchExpenses(groupId).first,
      );
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  JsonMap debugSnapshot() => switch (state) {
    ExpensesLoading() => {'status': 'loading', 'groupId': groupId},
    ExpensesFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    ExpensesLoaded(
      :final group,
      :final entries,
      :final visible,
      :final memberFilter,
      :final categoryFilter,
    ) =>
      {
        'status': entries.isEmpty ? 'empty' : 'data',
        'groupId': group.id,
        'currency': group.currency.code,
        'filter': {'memberId': memberFilter, 'category': categoryFilter},
        'visible': visible.length,
        'expenses': [for (final e in visible) expenseJson(e)],
      },
  };
}

/// JSON shape of an expense in snapshots and DebugDrive results.
JsonMap expenseJson(ExpenseEntry e) => {
  'id': e.expense.id,
  'title': e.expense.title,
  'amountCents': e.expense.amountCents,
  'currency': e.expense.currency.code,
  'date': isoDay(e.expense.date),
  'category': e.category,
  'payers': e.expense.payers,
  'shares': e.expense.shares,
  'splitMode': splitModeOf(e.split),
  if (e.foreign case final f?)
    'foreign': {
      'currency': f.currency.code,
      'amountCents': f.amountCents,
      'fxRatePpm': f.ratePpm,
    },
};

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final expensesViewModelProvider =
    NotifierProvider.family<ExpensesViewModel, ExpensesState, String>(
      ExpensesViewModel.new,
    );
