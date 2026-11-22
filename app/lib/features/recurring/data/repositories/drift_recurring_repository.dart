import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/recurring/data/recurring_models.dart';
import 'package:mitlio/features/recurring/data/repositories/recurring_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

DateTime _parseDay(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) throw FormatException('bad day', s);
  return DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

/// Drift implementation on the local-only `local_recurring_expenses` table.
class DriftRecurringRepository implements RecurringRepository {
  DriftRecurringRepository({
    required this._db,
    required this._clock,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  static RecurringExpense _fromRow(RecurringExpenseRow row) {
    final split = splitFromWeights(
      row.splitMode,
      (jsonDecode(row.splitWeightsJson) as Map).cast<String, int>(),
    );
    final frequency = RecurrenceFrequency.values.asNameMap()[row.frequency];
    if (split == null || frequency == null) {
      throw FormatException('bad recurring row', row.id);
    }
    final created = RecurrenceRule.create(
      start: _parseDay(row.startDate),
      frequency: frequency,
      interval: row.intervalCount,
      end: row.endDate == null ? null : _parseDay(row.endDate!),
    );
    if (created is! Ok<RecurrenceRule, RecurrenceError>) {
      throw FormatException('bad recurring rule', row.id);
    }
    final rule = created.value;
    return RecurringExpense(
      id: row.id,
      groupId: row.groupId,
      title: row.title,
      amountCents: row.amountCents,
      payers: (jsonDecode(row.payersJson) as Map).cast<String, int>(),
      split: split,
      category: row.category,
      rule: rule,
      lastGenerated: row.lastGenerated == null
          ? null
          : _parseDay(row.lastGenerated!),
      paused: row.paused,
      createdAt: row.createdAt,
    );
  }

  static LocalRecurringExpensesCompanion _toCompanion({
    required String id,
    required String groupId,
    required RecurringDraft draft,
    required DateTime createdAt,
    required bool paused,
    required DateTime? lastGenerated,
  }) => LocalRecurringExpensesCompanion.insert(
    id: id,
    groupId: groupId,
    title: draft.title.trim(),
    amountCents: draft.amountCents,
    payersJson: jsonEncode(draft.payers),
    splitMode: splitModeOf(draft.split),
    splitWeightsJson: jsonEncode({
      for (final m in _memberIds(draft)) m: splitWeightOf(draft.split, m),
    }),
    category: Value(draft.category),
    frequency: draft.rule.frequency.name,
    intervalCount: draft.rule.interval,
    startDate: recurringDay(draft.rule.start),
    endDate: Value(
      draft.rule.end == null ? null : recurringDay(draft.rule.end!),
    ),
    lastGenerated: Value(
      lastGenerated == null ? null : recurringDay(lastGenerated),
    ),
    paused: Value(paused),
    createdAt: createdAt,
  );

  static Set<String> _memberIds(RecurringDraft draft) => switch (draft.split) {
    EqualSplit(:final participants) => participants,
    SharesSplit(:final weights) => weights.keys.toSet(),
    PercentSplit(:final basisPoints) => basisPoints.keys.toSet(),
    ExactSplit(:final cents) => cents.keys.toSet(),
  };

  Future<RecurringExpenseRow?> _row(String id) => _db.recurringDao.find(id);

  Undo _restore(RecurringExpenseRow? previous, String id) => Undo(
    () => guardStorage(() async {
      if (previous == null) {
        await _db.recurringDao.deleteById(id);
      } else {
        await _db.recurringDao.upsert(previous.toCompanion(false));
      }
      return const Ok<void, RepositoryError>(null);
    }),
  );

  @override
  Stream<List<RecurringExpense>> watchRules(String groupId) => _db.recurringDao
      .watchByGroup(groupId)
      .map((rows) => [for (final r in rows) _fromRow(r)]);

  @override
  Future<RepoResult<List<RecurringExpense>>> all() => guardStorage(
    () async => Ok([
      for (final r in await _db.recurringDao.all()) _fromRow(r),
    ]),
  );

  @override
  Future<RepoResult<RecurringExpense>> create(
    String groupId,
    RecurringDraft draft,
  ) => guardStorage(() async {
    final problem = validateRecurringDraft(draft);
    if (problem != null) return Err(InvalidData(problem));
    final id = _ids.newId();
    await _db.recurringDao.upsert(
      _toCompanion(
        id: id,
        groupId: groupId,
        draft: draft,
        createdAt: _clock.now().toUtc(),
        paused: false,
        lastGenerated: draft.lastGenerated,
      ),
    );
    return Ok(_fromRow((await _row(id))!));
  });

  @override
  Future<RepoResult<RecurringExpense>> update(
    String id,
    RecurringDraft draft,
  ) => guardStorage(() async {
    final problem = validateRecurringDraft(draft);
    if (problem != null) return Err(InvalidData(problem));
    final old = await _row(id);
    if (old == null) return Err(NotFound('recurring', id));
    await _db.recurringDao.upsert(
      _toCompanion(
        id: id,
        groupId: old.groupId,
        draft: draft,
        createdAt: old.createdAt,
        paused: old.paused,
        lastGenerated: old.lastGenerated == null
            ? null
            : _parseDay(old.lastGenerated!),
      ),
    );
    return Ok(_fromRow((await _row(id))!));
  });

  @override
  Future<RepoResult<RecurringExpense>> setPaused(
    String id, {
    required bool paused,
    DateTime? lastGenerated,
  }) => guardStorage(() async {
    final old = await _row(id);
    if (old == null) return Err(NotFound('recurring', id));
    await _db.recurringDao.upsert(
      old
          .copyWith(
            paused: paused,
            lastGenerated: lastGenerated == null
                ? const Value.absent()
                : Value(recurringDay(lastGenerated)),
          )
          .toCompanion(false),
    );
    return Ok(_fromRow((await _row(id))!));
  });

  @override
  Future<RepoResult<RecurringExpense>> markGenerated(
    String id,
    DateTime date,
  ) => guardStorage(() async {
    final old = await _row(id);
    if (old == null) return Err(NotFound('recurring', id));
    await _db.recurringDao.upsert(
      old.copyWith(lastGenerated: Value(recurringDay(date))).toCompanion(false),
    );
    return Ok(_fromRow((await _row(id))!));
  });

  @override
  Future<RepoResult<Undo>> delete(String id) => guardStorage(() async {
    final old = await _row(id);
    if (old == null) return Err(NotFound('recurring', id));
    await _db.recurringDao.deleteById(id);
    return Ok(_restore(old, id));
  });
}
