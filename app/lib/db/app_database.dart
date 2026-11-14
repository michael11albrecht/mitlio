import 'package:drift/drift.dart';
import 'package:mitlio/db/daos/expenses_dao.dart';
import 'package:mitlio/db/daos/groups_dao.dart';
import 'package:mitlio/db/daos/local_member_bank_dao.dart';
import 'package:mitlio/db/daos/members_dao.dart';
import 'package:mitlio/db/daos/settlements_dao.dart';
import 'package:mitlio/db/tables.dart';

part 'app_database.g.dart';

/// Local-first source of truth (ADR-04). Schema changes need an explicit
/// migration plus `make db-schema` (see `drift_schemas/`).
@DriftDatabase(
  tables: [
    Groups,
    Members,
    Expenses,
    ExpensePayers,
    ExpenseShares,
    Settlements,
    LocalMemberBank,
    LocalOutbox,
  ],
  daos: [
    GroupsDao,
    MembersDao,
    ExpensesDao,
    SettlementsDao,
    LocalMemberBankDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
