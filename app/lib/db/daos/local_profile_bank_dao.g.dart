// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_profile_bank_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalProfileBankDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProfileTable get profile => attachedDatabase.profile;
  $LocalProfileBankTable get localProfileBank =>
      attachedDatabase.localProfileBank;
  LocalProfileBankDaoManager get managers => LocalProfileBankDaoManager(this);
}

class LocalProfileBankDaoManager {
  final _$LocalProfileBankDaoMixin _db;
  LocalProfileBankDaoManager(this._db);
  $$ProfileTableTableManager get profile =>
      $$ProfileTableTableManager(_db.attachedDatabase, _db.profile);
  $$LocalProfileBankTableTableManager get localProfileBank =>
      $$LocalProfileBankTableTableManager(
        _db.attachedDatabase,
        _db.localProfileBank,
      );
}
