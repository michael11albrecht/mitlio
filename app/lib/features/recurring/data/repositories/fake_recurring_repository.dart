import 'dart:async';

import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/recurring/data/recurring_models.dart'
    show validateRecurringDraft;
import 'package:mitlio/features/recurring/data/repositories/recurring_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [RecurringRepository] for tests and DebugDrive.
class FakeRecurringRepository implements RecurringRepository {
  FakeRecurringRepository({Clock? clock, IdGenerator? ids})
    : _clock = clock ?? FixedClock(DateTime.utc(2026)),
      _ids = ids ?? SequentialIdGenerator(prefix: 'rec');

  final Clock _clock;
  final IdGenerator _ids;
  final _rules = <String, RecurringExpense>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  /// Fails every command with this error while set.
  RepositoryError? failWith;

  /// Fails only [markGenerated] while set (the second step of a catch-up).
  RepositoryError? failMarkWith;

  List<RecurringExpense> _sorted() {
    final all = _rules.values.toList()
      ..sort((a, b) {
        final c = a.createdAt.compareTo(b.createdAt);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    return all;
  }

  void _put(RecurringExpense rule) {
    _rules[rule.id] = rule;
    _changes.add(null);
  }

  RecurringExpense _copy(
    RecurringExpense r, {
    bool? paused,
    DateTime? lastGenerated,
  }) => RecurringExpense(
    id: r.id,
    groupId: r.groupId,
    title: r.title,
    amountCents: r.amountCents,
    payers: r.payers,
    split: r.split,
    category: r.category,
    rule: r.rule,
    lastGenerated: lastGenerated ?? r.lastGenerated,
    paused: paused ?? r.paused,
    createdAt: r.createdAt,
  );

  RecurringExpense _fromDraft(
    String id,
    String groupId,
    RecurringDraft d, {
    required DateTime createdAt,
    required bool paused,
    required DateTime? lastGenerated,
  }) => RecurringExpense(
    id: id,
    groupId: groupId,
    title: d.title.trim(),
    amountCents: d.amountCents,
    payers: Map.of(d.payers),
    split: d.split,
    category: d.category,
    rule: d.rule,
    lastGenerated: lastGenerated,
    paused: paused,
    createdAt: createdAt,
  );

  @override
  Stream<List<RecurringExpense>> watchRules(String groupId) => watchSnapshots(
    _changes.stream,
    () => [
      for (final r in _sorted())
        if (r.groupId == groupId) r,
    ],
  );

  @override
  Future<RepoResult<List<RecurringExpense>>> all() async {
    if (failWith case final e?) return Err(e);
    return Ok(_sorted());
  }

  @override
  Future<RepoResult<RecurringExpense>> create(
    String groupId,
    RecurringDraft draft,
  ) async {
    if (failWith case final e?) return Err(e);
    final problem = validateRecurringDraft(draft);
    if (problem != null) return Err(InvalidData(problem));
    final rule = _fromDraft(
      _ids.newId(),
      groupId,
      draft,
      createdAt: _clock.now().toUtc(),
      paused: false,
      lastGenerated: draft.lastGenerated,
    );
    _put(rule);
    return Ok(rule);
  }

  @override
  Future<RepoResult<RecurringExpense>> update(
    String id,
    RecurringDraft draft,
  ) async {
    if (failWith case final e?) return Err(e);
    final problem = validateRecurringDraft(draft);
    if (problem != null) return Err(InvalidData(problem));
    final old = _rules[id];
    if (old == null) return Err(NotFound('recurring', id));
    final rule = _fromDraft(
      id,
      old.groupId,
      draft,
      createdAt: old.createdAt,
      paused: old.paused,
      lastGenerated: old.lastGenerated,
    );
    _put(rule);
    return Ok(rule);
  }

  @override
  Future<RepoResult<RecurringExpense>> setPaused(
    String id, {
    required bool paused,
    DateTime? lastGenerated,
  }) async {
    if (failWith case final e?) return Err(e);
    final old = _rules[id];
    if (old == null) return Err(NotFound('recurring', id));
    final rule = _copy(old, paused: paused, lastGenerated: lastGenerated);
    _put(rule);
    return Ok(rule);
  }

  @override
  Future<RepoResult<RecurringExpense>> markGenerated(
    String id,
    DateTime date,
  ) async {
    if (failWith case final e?) return Err(e);
    if (failMarkWith case final e?) return Err(e);
    final old = _rules[id];
    if (old == null) return Err(NotFound('recurring', id));
    final rule = _copy(old, lastGenerated: date);
    _put(rule);
    return Ok(rule);
  }

  @override
  Future<RepoResult<Undo>> delete(String id) async {
    if (failWith case final e?) return Err(e);
    final old = _rules.remove(id);
    if (old == null) return Err(NotFound('recurring', id));
    _changes.add(null);
    return Ok(
      Undo(() async {
        _put(old);
        return const Ok<void, RepositoryError>(null);
      }),
    );
  }
}
