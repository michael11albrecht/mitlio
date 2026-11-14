// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_member_bank_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalMemberBankDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $MembersTable get members => attachedDatabase.members;
  $LocalMemberBankTable get localMemberBank => attachedDatabase.localMemberBank;
  LocalMemberBankDaoManager get managers => LocalMemberBankDaoManager(this);
}

class LocalMemberBankDaoManager {
  final _$LocalMemberBankDaoMixin _db;
  LocalMemberBankDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$LocalMemberBankTableTableManager get localMemberBank =>
      $$LocalMemberBankTableTableManager(
        _db.attachedDatabase,
        _db.localMemberBank,
      );
}
