import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/routes/data/repositories/places_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [PlacesRepository] for tests and DebugDrive.
class FakePlacesRepository implements PlacesRepository {
  final _places = <PlaceKind, PlaceSuggestion>{};

  /// Fails every command with this error while set.
  RepositoryError? failWith;

  Undo _restore(PlaceKind kind, PlaceSuggestion? previous) => Undo(() async {
    if (previous == null) {
      _places.remove(kind);
    } else {
      _places[kind] = previous;
    }
    return const Ok<void, RepositoryError>(null);
  });

  @override
  Future<RepoResult<List<SavedPlace>>> all() async {
    final error = failWith;
    if (error != null) return Err(error);
    return Ok([
      for (final e in _places.entries) SavedPlace(kind: e.key, place: e.value),
    ]);
  }

  @override
  Future<RepoResult<Undo>> save(PlaceKind kind, PlaceSuggestion place) async {
    final error = failWith;
    if (error != null) return Err(error);
    final previous = _places[kind];
    _places[kind] = place;
    return Ok(_restore(kind, previous));
  }

  @override
  Future<RepoResult<Undo>> remove(PlaceKind kind) async {
    final error = failWith;
    if (error != null) return Err(error);
    final previous = _places.remove(kind);
    return Ok(_restore(kind, previous));
  }
}
