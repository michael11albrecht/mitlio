import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'recurring_dao.g.dart';

/// Local-only recurring expense rules. Nothing here syncs.
@DriftAccessor(tables: [LocalRecurringExpenses])
class RecurringDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringDaoMixin {
  RecurringDao(super.attachedDatabase);

  /// Rules of [groupId], oldest first.
  Stream<List<RecurringExpenseRow>> watchByGroup(String groupId) =>
      (select(localRecurringExpenses)
            ..where((r) => r.groupId.equals(groupId))
            ..orderBy([
              (r) => OrderingTerm.asc(r.createdAt),
              (r) => OrderingTerm.asc(r.id),
            ]))
          .watch();

  /// Every rule, oldest first.
  Future<List<RecurringExpenseRow>> all() =>
      (select(localRecurringExpenses)..orderBy([
            (r) => OrderingTerm.asc(r.createdAt),
            (r) => OrderingTerm.asc(r.id),
          ]))
          .get();

  Future<RecurringExpenseRow?> find(String id) => (select(
    localRecurringExpenses,
  )..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<void> upsert(LocalRecurringExpensesCompanion row) =>
      into(localRecurringExpenses).insertOnConflictUpdate(row);

  Future<void> deleteById(String id) => (delete(
    localRecurringExpenses,
  )..where((r) => r.id.equals(id))).go();
}
