import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'local_places_dao.g.dart';

/// Local-only saved places (home, work). Nothing here syncs.
@DriftAccessor(tables: [LocalPlaces])
class LocalPlacesDao extends DatabaseAccessor<AppDatabase>
    with _$LocalPlacesDaoMixin {
  LocalPlacesDao(super.attachedDatabase);

  Future<List<LocalPlaceRow>> all() => select(localPlaces).get();

  Future<void> upsert(LocalPlacesCompanion row) =>
      into(localPlaces).insertOnConflictUpdate(row);

  Future<void> deleteKind(String kind) =>
      (delete(localPlaces)..where((p) => p.kind.equals(kind))).go();
}
