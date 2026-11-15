// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_places_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalPlacesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPlacesTable get localPlaces => attachedDatabase.localPlaces;
  LocalPlacesDaoManager get managers => LocalPlacesDaoManager(this);
}

class LocalPlacesDaoManager {
  final _$LocalPlacesDaoMixin _db;
  LocalPlacesDaoManager(this._db);
  $$LocalPlacesTableTableManager get localPlaces =>
      $$LocalPlacesTableTableManager(_db.attachedDatabase, _db.localPlaces);
}
