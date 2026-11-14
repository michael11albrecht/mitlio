// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A stored [Ride] with its storage metadata.
final class RideEntry {
  const RideEntry({
    required this.groupId,
    required this.ride,
    required this.createdAt,
    this.settledExpenseId,
  });

  final String groupId;
  final Ride ride;

  /// UTC.
  final DateTime createdAt;

  /// Set once a period settlement turned this ride into an expense; the
  /// ride is then locked (no edit, no delete).
  final String? settledExpenseId;

  bool get isSettled => settledExpenseId != null;

  @override
  bool operator ==(Object other) =>
      other is RideEntry &&
      other.groupId == groupId &&
      other.createdAt == createdAt &&
      other.settledExpenseId == settledExpenseId &&
      other.ride.id == ride.id &&
      other.ride.date == ride.date &&
      other.ride.distanceMeters == ride.distanceMeters &&
      other.ride.roundTrip == ride.roundTrip &&
      other.ride.tollsCents == ride.tollsCents &&
      other.ride.vehicleId == ride.vehicleId &&
      other.ride.driverId == ride.driverId &&
      other.ride.driverCounts == ride.driverCounts &&
      other.ride.pricePerUnitMilli == ride.pricePerUnitMilli &&
      other.ride.useKmRate == ride.useKmRate &&
      other.ride.passengerIds.length == ride.passengerIds.length &&
      other.ride.passengerIds.containsAll(ride.passengerIds);

  @override
  int get hashCode => Object.hash(
    groupId,
    ride.id,
    ride.date,
    ride.vehicleId,
    ride.driverId,
    settledExpenseId,
  );

  @override
  String toString() => 'RideEntry(${ride.id}, ${ride.date})';
}

/// Source of truth for logged rides. Lists are ordered by date, then id.
///
/// A ride's date is stored as a calendar day (UTC midnight); only year,
/// month and day of the given date are kept.
abstract interface class RidesRepository {
  /// Live rides of [groupId] inside [period]; emits the current list first,
  /// then after every change.
  Stream<List<RideEntry>> watchRides(String groupId, RidePeriod period);

  Future<RepoResult<RideEntry>> get(String id);

  /// Stores [ride] using its own id (generate it with an `IdGenerator`).
  /// [Conflict] if the id exists, [NotFound] if group, vehicle, driver or a
  /// passenger is unknown to the group, [InvalidData] for negative numbers.
  Future<RepoResult<RideEntry>> log(String groupId, Ride ride);

  /// Replaces every field of the ride with [ride]'s id. [Locked] if the
  /// ride is settled.
  Future<RepoResult<RideEntry>> update(Ride ride);

  /// Soft delete; call the returned [Undo] to bring the ride back. [Locked]
  /// if the ride is settled.
  Future<RepoResult<Undo>> softDelete(String id);

  /// [NotFound] for unknown ids, [Conflict] if the ride is not deleted.
  Future<RepoResult<void>> restore(String id);

  /// Locks [rideIds] under [expenseId] in one step. Nothing is changed
  /// unless all rides exist and are unsettled ([NotFound], [Locked]); the
  /// expense must exist ([NotFound]).
  Future<RepoResult<void>> markSettled(List<String> rideIds, String expenseId);
}
