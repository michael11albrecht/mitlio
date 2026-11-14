import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'expenses_dao.g.dart';

/// An expense aggregate: root row plus its payer and share children.
class ExpenseWithChildren {
  const ExpenseWithChildren({
    required this.expense,
    required this.payers,
    required this.shares,
  });

  final ExpenseRow expense;
  final List<ExpensePayerRow> payers;
  final List<ExpenseShareRow> shares;
}

@DriftAccessor(tables: [Expenses, ExpensePayers, ExpenseShares])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.attachedDatabase);

  /// Writes the expense and its children atomically; any failure rolls back
  /// everything.
  Future<void> insertExpense(
    ExpensesCompanion expense,
    List<ExpensePayersCompanion> payers,
    List<ExpenseSharesCompanion> shares,
  ) => transaction(() async {
    await into(expenses).insert(expense);
    await _insertChildren(payers, shares);
  });

  /// Replaces the root fields and the complete child sets in one
  /// transaction. Children are an owned part of the aggregate (synced as one
  /// op), so they are replaced, not soft deleted. Returns false if the
  /// expense does not exist or is soft deleted.
  Future<bool> replaceExpense(
    String id,
    ExpensesCompanion expense,
    List<ExpensePayersCompanion> payers,
    List<ExpenseSharesCompanion> shares,
  ) => transaction(() async {
    final n = await (update(
      expenses,
    )..where((e) => e.id.equals(id) & e.deletedAt.isNull())).write(expense);
    if (n == 0) return false;
    await (delete(expensePayers)..where((p) => p.expenseId.equals(id))).go();
    await (delete(expenseShares)..where((s) => s.expenseId.equals(id))).go();
    await _insertChildren(payers, shares);
    return true;
  });

  Future<void> _insertChildren(
    List<ExpensePayersCompanion> payers,
    List<ExpenseSharesCompanion> shares,
  ) async {
    for (final p in payers) {
      await into(expensePayers).insert(p);
    }
    for (final s in shares) {
      await into(expenseShares).insert(s);
    }
  }

  Future<ExpenseWithChildren?> findById(String id) async {
    final expense = await (select(
      expenses,
    )..where((e) => e.id.equals(id) & e.deletedAt.isNull())).getSingleOrNull();
    if (expense == null) return null;
    return _withChildren(expense);
  }

  /// Live expenses of [groupId], newest date first, with children.
  Future<List<ExpenseWithChildren>> listByGroup(String groupId) async {
    final rows = await _byGroup(groupId).get();
    return [for (final e in rows) await _withChildren(e)];
  }

  Stream<List<ExpenseRow>> watchByGroup(String groupId) =>
      _byGroup(groupId).watch();

  SimpleSelectStatement<$ExpensesTable, ExpenseRow> _byGroup(String groupId) =>
      select(expenses)
        ..where((e) => e.groupId.equals(groupId) & e.deletedAt.isNull())
        ..orderBy([
          (e) => OrderingTerm.desc(e.date),
          (e) => OrderingTerm.desc(e.id),
        ]);

  Future<ExpenseWithChildren> _withChildren(ExpenseRow expense) async {
    final payers =
        await (select(expensePayers)
              ..where((p) => p.expenseId.equals(expense.id))
              ..orderBy([(p) => OrderingTerm.asc(p.memberId)]))
            .get();
    final shares =
        await (select(expenseShares)
              ..where((s) => s.expenseId.equals(expense.id))
              ..orderBy([(s) => OrderingTerm.asc(s.memberId)]))
            .get();
    return ExpenseWithChildren(
      expense: expense,
      payers: payers,
      shares: shares,
    );
  }

  /// Soft deletes the expense; children stay for history. Returns true if a
  /// live row was marked deleted.
  Future<bool> softDelete({
    required String id,
    required DateTime deletedAt,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          expenses,
        )..where((e) => e.id.equals(id) & e.deletedAt.isNull())).write(
          ExpensesCompanion(
            deletedAt: Value(deletedAt),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }

  /// Undoes [softDelete]. Returns true if a soft-deleted row was revived.
  Future<bool> restore({
    required String id,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          expenses,
        )..where((r) => r.id.equals(id) & r.deletedAt.isNotNull())).write(
          ExpensesCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }
}
