import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/routes/data/route_models.dart';

export 'package:mitlio/features/routes/data/route_models.dart'
    show PlaceKind, PlaceSuggestion, SavedPlace;

/// Saved places "Zuhause" and "Arbeit". Local only: nothing here syncs, and
/// "delete my data" wipes the table with the rest of the database.
abstract interface class PlacesRepository {
  /// The saved places, at most one per [PlaceKind].
  Future<RepoResult<List<SavedPlace>>> all();

  /// Remembers [place] as [kind], replacing the previous one. The [Undo]
  /// brings the previous state (a place or none) back.
  Future<RepoResult<Undo>> save(PlaceKind kind, PlaceSuggestion place);

  /// Forgets the place of [kind]; the [Undo] puts it back.
  Future<RepoResult<Undo>> remove(PlaceKind kind);
}
