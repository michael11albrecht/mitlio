import 'dart:async';

import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_rides_refs.dart';
import 'package:mitlio/features/rides/data/repositories/rides_codec.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [RidesRepository] with the same behaviour as the Drift one.
/// Group, member, vehicle and expense lookups go through the given fakes.
class FakeRidesRepository implements RidesRepository {
  FakeRidesRepository({
    required this._groups,
    required this._members,
    required this._vehicles,
    required this._expenses,
    required this._clock,
  });

  final GroupsRepository _groups;
  final MembersRepository _members;
  final VehiclesRepository _vehicles;
  final ExpensesRepository _expenses;
  final Clock _clock;
  final _entries = <String, RideEntry>{};
  final _deleted = <String>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  RideEntry? _live(String id) => _deleted.contains(id) ? null : _entries[id];

  @override
  Stream<List<RideEntry>> watchRides(String groupId, RidePeriod period) =>
      watchSnapshots(
        _changes.stream,
        () =>
            [
              for (final e in _entries.values)
                if (e.groupId == groupId &&
                    !_deleted.contains(e.ride.id) &&
                    period.contains(e.ride.date))
                  e,
            ]..sort((a, b) {
              final byDate = a.ride.date.compareTo(b.ride.date);
              return byDate != 0 ? byDate : a.ride.id.compareTo(b.ride.id);
            }),
      );

  @override
  Future<RepoResult<RideEntry>> get(String id) async {
    final e = _live(id);
    return e == null ? Err(NotFound('ride', id)) : Ok(e);
  }

  RepositoryError? _invalid(Ride r) =>
      r.distanceMeters < 0 || r.tollsCents < 0 || r.pricePerUnitMilli < 0
      ? InvalidData('ride ${r.id}: distance, tolls and price must be >= 0')
      : null;

  Future<RepositoryError?> _missing(String groupId, Ride r) => fakeMissingRef(
    groups: _groups,
    members: _members,
    vehicles: _vehicles,
    groupId: groupId,
    vehicleId: r.vehicleId,
    memberIds: [r.driverId, ...r.passengerIds],
  );

  Ride _normalized(Ride r) => Ride(
    id: r.id,
    date: calendarDay(r.date),
    distanceMeters: r.distanceMeters,
    roundTrip: r.roundTrip,
    tollsCents: r.tollsCents,
    vehicleId: r.vehicleId,
    driverId: r.driverId,
    passengerIds: Set.unmodifiable(r.passengerIds),
    driverCounts: r.driverCounts,
    pricePerUnitMilli: r.pricePerUnitMilli,
    useKmRate: r.useKmRate,
  );

  @override
  Future<RepoResult<RideEntry>> log(String groupId, Ride ride) async {
    final invalid = _invalid(ride);
    if (invalid != null) return Err(invalid);
    final missing = await _missing(groupId, ride);
    if (missing != null) return Err(missing);
    if (_entries.containsKey(ride.id)) {
      return const Err(Conflict('ride id already exists'));
    }
    final entry = RideEntry(
      groupId: groupId,
      ride: _normalized(ride),
      createdAt: _clock.now().toUtc(),
    );
    _entries[ride.id] = entry;
    _changes.add(null);
    return Ok(entry);
  }

  @override
  Future<RepoResult<RideEntry>> update(Ride ride) async {
    final invalid = _invalid(ride);
    if (invalid != null) return Err(invalid);
    final old = _live(ride.id);
    if (old == null) return Err(NotFound('ride', ride.id));
    if (old.isSettled) return Err(Locked('ride', ride.id));
    final missing = await _missing(old.groupId, ride);
    if (missing != null) return Err(missing);
    final entry = RideEntry(
      groupId: old.groupId,
      ride: _normalized(ride),
      createdAt: old.createdAt,
    );
    _entries[ride.id] = entry;
    _changes.add(null);
    return Ok(entry);
  }

  @override
  Future<RepoResult<Undo>> softDelete(String id) async {
    final e = _live(id);
    if (e == null) return Err(NotFound('ride', id));
    if (e.isSettled) return Err(Locked('ride', id));
    _deleted.add(id);
    _changes.add(null);
    return Ok(Undo(() => restore(id)));
  }

  @override
  Future<RepoResult<void>> restore(String id) async {
    if (!_entries.containsKey(id)) return Err(NotFound('ride', id));
    if (!_deleted.remove(id)) {
      return const Err(Conflict('ride is not deleted'));
    }
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<RepoResult<void>> markSettled(
    List<String> rideIds,
    String expenseId,
  ) async {
    if (await _expenses.get(expenseId) case Err<ExpenseEntry, RepositoryError>(
      :final error,
    )) {
      return Err(error);
    }
    for (final id in rideIds) {
      final e = _live(id);
      if (e == null) return Err(NotFound('ride', id));
      if (e.isSettled) return Err(Locked('ride', id));
    }
    for (final id in rideIds) {
      final e = _entries[id]!;
      _entries[id] = RideEntry(
        groupId: e.groupId,
        ride: e.ride,
        createdAt: e.createdAt,
        settledExpenseId: expenseId,
      );
    }
    _changes.add(null);
    return const Ok(null);
  }
}
