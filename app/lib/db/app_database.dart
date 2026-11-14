import 'package:drift/drift.dart';
import 'package:mitlio/db/daos/expenses_dao.dart';
import 'package:mitlio/db/daos/groups_dao.dart';
import 'package:mitlio/db/daos/local_member_bank_dao.dart';
import 'package:mitlio/db/daos/members_dao.dart';
import 'package:mitlio/db/daos/rides_dao.dart';
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
    Vehicles,
    RideTemplates,
    Rides,
    ExpenseRevisions,
  ],
  daos: [
    GroupsDao,
    MembersDao,
    ExpensesDao,
    SettlementsDao,
    LocalMemberBankDao,
    RidesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await _from1To2(m);
      if (from < 3) await _from2To3(m);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// v3: expense edit history (P7-T03).
  Future<void> _from2To3(Migrator m) async {
    await m.createTable(expenseRevisions);
    await m.createIndex(expenseRevisionsExpenseRevision);
    await m.createIndex(expenseRevisionsGroupId);
  }

  /// v2: rides slice (P3r-T03).
  Future<void> _from1To2(Migrator m) async {
    await m.createTable(vehicles);
    await m.createTable(rideTemplates);
    await m.createTable(rides);
    await m.createIndex(vehiclesGroupId);
    await m.createIndex(rideTemplatesGroupId);
    await m.createIndex(ridesGroupDate);
  }
}
