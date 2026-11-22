// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalRecurringExpensesTable get localRecurringExpenses =>
      attachedDatabase.localRecurringExpenses;
  RecurringDaoManager get managers => RecurringDaoManager(this);
}

class RecurringDaoManager {
  final _$RecurringDaoMixin _db;
  RecurringDaoManager(this._db);
  $$LocalRecurringExpensesTableTableManager get localRecurringExpenses =>
      $$LocalRecurringExpensesTableTableManager(
        _db.attachedDatabase,
        _db.localRecurringExpenses,
      );
}
