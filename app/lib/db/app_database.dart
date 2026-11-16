import 'package:drift/drift.dart';
import 'package:mitlio/db/daos/expenses_dao.dart';
import 'package:mitlio/db/daos/groups_dao.dart';
import 'package:mitlio/db/daos/local_member_bank_dao.dart';
import 'package:mitlio/db/daos/local_places_dao.dart';
import 'package:mitlio/db/daos/members_dao.dart';
import 'package:mitlio/db/daos/rides_dao.dart';
import 'package:mitlio/db/daos/settlements_dao.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
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
    LocalDriverPrompts,
    LocalPlaces,
    Vehicles,
    RideTemplates,
    Rides,
    ExpenseRevisions,
    LocalGroupSync,
    LocalSyncCursor,
    LocalSettings,
  ],
  daos: [
    GroupsDao,
    MembersDao,
    ExpensesDao,
    SettlementsDao,
    LocalMemberBankDao,
    LocalPlacesDao,
    RidesDao,
    SyncStateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await _from1To2(m);
      if (from < 3) await _from2To3(m);
      if (from < 4) await _from3To4(m);
      if (from < 5) await _from4To5(m);
      if (from < 6) await _from5To6(m);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// v6: local sync state (P6-T09a). `local_outbox` was never written, so it
  /// is recreated with the new columns instead of migrated.
  Future<void> _from5To6(Migrator m) async {
    await m.drop(localOutbox);
    await m.createTable(localOutbox);
    await m.createTable(localGroupSync);
    await m.createTable(localSyncCursor);
    await m.createTable(localSettings);
  }

  /// v5: saved places for the ride distance lookup (P9-T08), local only.
  Future<void> _from4To5(Migrator m) async {
    await m.createTable(localPlaces);
  }

  /// v4: who drives, per member, and the local "already asked" flags.
  Future<void> _from3To4(Migrator m) async {
    await m.addColumn(members, members.canDrive);
    await m.createTable(localDriverPrompts);
  }

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
