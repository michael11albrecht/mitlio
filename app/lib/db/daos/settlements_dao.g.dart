// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlements_dao.dart';

// ignore_for_file: type=lint
mixin _$SettlementsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $MembersTable get members => attachedDatabase.members;
  $SettlementsTable get settlements => attachedDatabase.settlements;
  SettlementsDaoManager get managers => SettlementsDaoManager(this);
}

class SettlementsDaoManager {
  final _$SettlementsDaoMixin _db;
  SettlementsDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$SettlementsTableTableManager get settlements =>
      $$SettlementsTableTableManager(_db.attachedDatabase, _db.settlements);
}
