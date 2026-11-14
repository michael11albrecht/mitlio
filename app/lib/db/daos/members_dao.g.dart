// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members_dao.dart';

// ignore_for_file: type=lint
mixin _$MembersDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $MembersTable get members => attachedDatabase.members;
  MembersDaoManager get managers => MembersDaoManager(this);
}

class MembersDaoManager {
  final _$MembersDaoMixin _db;
  MembersDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
}
