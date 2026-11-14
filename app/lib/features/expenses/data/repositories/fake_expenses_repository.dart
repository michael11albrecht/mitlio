import 'dart:async';

import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [ExpensesRepository] with the same behaviour as the Drift one.
/// Group and member lookups go through the given fakes.
class FakeExpensesRepository implements ExpensesRepository {
  FakeExpensesRepository({
    required this._groups,
    required this._members,
    required this._clock,
    required this._ids,
  });

  final GroupsRepository _groups;
  final MembersRepository _members;
  final Clock _clock;
  final IdGenerator _ids;
  final _entries = <String, ExpenseEntry>{};
  final _deleted = <String>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  ExpenseEntry? _live(String id) => _deleted.contains(id) ? null : _entries[id];

  @override
  Stream<List<ExpenseEntry>> watchExpenses(String groupId) => watchSnapshots(
    _changes.stream,
    () =>
        [
          for (final e in _entries.values)
            if (e.groupId == groupId && !_deleted.contains(e.expense.id)) e,
        ]..sort((a, b) {
          final byDate = b.expense.date.compareTo(a.expense.date);
          return byDate != 0 ? byDate : b.expense.id.compareTo(a.expense.id);
        }),
  );

  @override
  Future<RepoResult<ExpenseEntry>> get(String id) async {
    final e = _live(id);
    return e == null ? Err(NotFound('expense', id)) : Ok(e);
  }

  Future<RepoResult<Expense>> _validate(
    String groupId,
    String id,
    ExpenseDraft draft,
  ) async {
    final group = switch (await _groups.get(groupId)) {
      Ok<Group, RepositoryError>(:final value) => value,
      Err<Group, RepositoryError>() => null,
    };
    if (group == null) return Err(NotFound('group', groupId));
    final members = (await _members.list(
      groupId,
    ) as Ok<List<GroupMember>, RepositoryError>).value;
    return buildExpense(
      id: id,
      draft: draft,
      groupCurrency: group.currency,
      members: [for (final m in members) m.toDomain()],
    );
  }

  @override
  Future<RepoResult<ExpenseEntry>> create(
    String groupId,
    ExpenseDraft draft,
  ) async {
    final id = _ids.newId();
    final built = await _validate(groupId, id, draft);
    if (built case Err(:final error)) return Err(error);
    final entry = ExpenseEntry(
      groupId: groupId,
      expense: (built as Ok<Expense, RepositoryError>).value,
      split: _normalised(draft.split),
      category: draft.category,
      tripMeta: draft.tripMeta,
      foreign: draft.foreign,
      createdAt: _clock.now().toUtc(),
    );
    _entries[id] = entry;
    _changes.add(null);
    return Ok(entry);
  }

  @override
  Future<RepoResult<ExpenseEntry>> update(String id, ExpenseDraft draft) async {
    final current = _live(id);
    if (current == null) return Err(NotFound('expense', id));
    final built = await _validate(current.groupId, id, draft);
    if (built case Err(:final error)) return Err(error);
    final entry = ExpenseEntry(
      groupId: current.groupId,
      expense: (built as Ok<Expense, RepositoryError>).value,
      split: _normalised(draft.split),
      category: draft.category,
      tripMeta: draft.tripMeta,
      foreign: draft.foreign,
      createdAt: current.createdAt,
    );
    _entries[id] = entry;
    _changes.add(null);
    return Ok(entry);
  }

  /// Same normalisation the Drift implementation gets from storing weights.
  SplitSpec _normalised(SplitSpec split) {
    final ids = switch (split) {
      EqualSplit(:final participants) => participants,
      SharesSplit(:final weights) => weights.keys,
      PercentSplit(:final basisPoints) => basisPoints.keys,
      ExactSplit(:final cents) => cents.keys,
    };
    return splitFromWeights(splitModeOf(split), {
      for (final m in ids) m: splitWeightOf(split, m),
    })!;
  }

  @override
  Future<RepoResult<Undo>> softDelete(String id) async {
    if (_live(id) == null) return Err(NotFound('expense', id));
    _deleted.add(id);
    _changes.add(null);
    return Ok(Undo(() => restore(id)));
  }

  @override
  Future<RepoResult<void>> restore(String id) async {
    if (!_entries.containsKey(id)) return Err(NotFound('expense', id));
    if (!_deleted.remove(id)) {
      return const Err(Conflict('expense is not deleted'));
    }
    _changes.add(null);
    return const Ok(null);
  }
}
