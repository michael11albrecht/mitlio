import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Source of truth for a group's ride templates ("Arbeit", "Training").
/// Lists are ordered by creation time, then id.
abstract interface class RideTemplatesRepository {
  /// Live templates; emits the current list first, then after every change.
  Stream<List<RideTemplate>> watchTemplates(String groupId);

  Future<RepoResult<RideTemplate>> get(String id);

  /// `name` is trimmed and must not be empty, distance and tolls must be
  /// >= 0 ([InvalidData]). The group, vehicle and default driver/passengers
  /// must exist in the group ([NotFound]). The id of [template] is ignored;
  /// the stored template gets a fresh id.
  Future<RepoResult<RideTemplate>> add(String groupId, RideTemplate template);

  /// Replaces every field of the template with [template]'s id.
  Future<RepoResult<RideTemplate>> update(RideTemplate template);

  /// Soft delete; call the returned [Undo] to bring the template back.
  Future<RepoResult<Undo>> softDelete(String id);

  /// [NotFound] for unknown ids, [Conflict] if the template is not deleted.
  Future<RepoResult<void>> restore(String id);
}

/// Trimmed copy of [t] under [id], or [InvalidData] for a blank name or a
/// negative distance or toll.
RepoResult<RideTemplate> buildTemplate(String id, RideTemplate t) {
  final name = t.name.trim();
  if (name.isEmpty) return const Err(InvalidData('name must not be empty'));
  if (t.distanceMeters < 0 || t.tollsCents < 0) {
    return const Err(InvalidData('distance and tolls must be >= 0'));
  }
  return Ok(
    RideTemplate(
      id: id,
      name: name,
      distanceMeters: t.distanceMeters,
      vehicleId: t.vehicleId,
      roundTrip: t.roundTrip,
      defaultDriverId: t.defaultDriverId,
      defaultPassengerIds: Set.unmodifiable(t.defaultPassengerIds),
      tollsCents: t.tollsCents,
    ),
  );
}
