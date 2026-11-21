// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_vehicles_dao.dart';

// ignore_for_file: type=lint
mixin _$UserVehiclesDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserVehiclesTable get userVehicles => attachedDatabase.userVehicles;
  $UserVehicleCostsTable get userVehicleCosts =>
      attachedDatabase.userVehicleCosts;
  UserVehiclesDaoManager get managers => UserVehiclesDaoManager(this);
}

class UserVehiclesDaoManager {
  final _$UserVehiclesDaoMixin _db;
  UserVehiclesDaoManager(this._db);
  $$UserVehiclesTableTableManager get userVehicles =>
      $$UserVehiclesTableTableManager(_db.attachedDatabase, _db.userVehicles);
  $$UserVehicleCostsTableTableManager get userVehicleCosts =>
      $$UserVehicleCostsTableTableManager(
        _db.attachedDatabase,
        _db.userVehicleCosts,
      );
}
