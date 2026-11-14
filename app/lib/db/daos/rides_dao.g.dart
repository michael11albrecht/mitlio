// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rides_dao.dart';

// ignore_for_file: type=lint
mixin _$RidesDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $VehiclesTable get vehicles => attachedDatabase.vehicles;
  $MembersTable get members => attachedDatabase.members;
  $RideTemplatesTable get rideTemplates => attachedDatabase.rideTemplates;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  $RidesTable get rides => attachedDatabase.rides;
  RidesDaoManager get managers => RidesDaoManager(this);
}

class RidesDaoManager {
  final _$RidesDaoMixin _db;
  RidesDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db.attachedDatabase, _db.vehicles);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$RideTemplatesTableTableManager get rideTemplates =>
      $$RideTemplatesTableTableManager(_db.attachedDatabase, _db.rideTemplates);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
  $$RidesTableTableManager get rides =>
      $$RidesTableTableManager(_db.attachedDatabase, _db.rides);
}
