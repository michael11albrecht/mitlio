import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/routes/data/repositories/places_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Drift implementation on the local-only `local_places` table.
class DriftPlacesRepository implements PlacesRepository {
  DriftPlacesRepository({required this._db, required this._clock});

  final AppDatabase _db;
  final Clock _clock;

  static SavedPlace? _fromRow(LocalPlaceRow row) {
    final kind = PlaceKind.values.asNameMap()[row.kind];
    return kind == null
        ? null
        : SavedPlace(
            kind: kind,
            place: PlaceSuggestion(
              label: row.label,
              lat: row.lat,
              lng: row.lng,
            ),
          );
  }

  Future<SavedPlace?> _find(PlaceKind kind) async {
    for (final row in await _db.localPlacesDao.all()) {
      if (row.kind == kind.name) return _fromRow(row);
    }
    return null;
  }

  Future<void> _put(PlaceKind kind, PlaceSuggestion place) =>
      _db.localPlacesDao.upsert(
        LocalPlacesCompanion.insert(
          kind: kind.name,
          label: place.label,
          lat: place.lat,
          lng: place.lng,
          savedAt: _clock.now().toUtc().toIso8601String(),
        ),
      );

  Undo _restore(PlaceKind kind, SavedPlace? previous) => Undo(
    () => guardStorage(() async {
      if (previous == null) {
        await _db.localPlacesDao.deleteKind(kind.name);
      } else {
        await _put(kind, previous.place);
      }
      return const Ok<void, RepositoryError>(null);
    }),
  );

  @override
  Future<RepoResult<List<SavedPlace>>> all() => guardStorage(() async {
    final rows = await _db.localPlacesDao.all();
    return Ok([
      for (final row in rows) ?_fromRow(row),
    ]);
  });

  @override
  Future<RepoResult<Undo>> save(PlaceKind kind, PlaceSuggestion place) =>
      guardStorage(() async {
        final previous = await _find(kind);
        await _put(kind, place);
        return Ok(_restore(kind, previous));
      });

  @override
  Future<RepoResult<Undo>> remove(PlaceKind kind) => guardStorage(() async {
    final previous = await _find(kind);
    await _db.localPlacesDao.deleteKind(kind.name);
    return Ok(_restore(kind, previous));
  });
}
