import 'package:drift/drift.dart' show Value;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/rides_dao.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/rides/data/repositories/drift_rides_refs.dart';
import 'package:mitlio/features/rides/data/repositories/rides_codec.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// [RidesRepository] backed by Drift.
class DriftRidesRepository implements RidesRepository {
  DriftRidesRepository({
    required AppDatabase db,
    required Clock clock,
    required ExpensesRepository expenses,
  }) : _db = db,
       _dao = db.ridesDao,
       // ignore: prefer_initializing_formals, no private named parameters (new language feature)
       _clock = clock,
       // ignore: prefer_initializing_formals, no private named parameters (new language feature)
       _expenses = expenses;

  final AppDatabase _db;
  final RidesDao _dao;
  final Clock _clock;
  final ExpensesRepository _expenses;

  RepoResult<RideEntry> _map(RideRow row) {
    final passengers = decodeIds(row.passengerIds);
    if (passengers == null) {
      return Err(InvalidData('ride ${row.id}: bad passenger ids'));
    }
    return Ok(
      RideEntry(
        groupId: row.groupId,
        createdAt: row.createdAt.toUtc(),
        settledExpenseId: row.settledExpenseId,
        ride: Ride(
          id: row.id,
          date: calendarDay(row.date),
          distanceMeters: row.distanceMeters,
          roundTrip: row.roundTrip,
          tollsCents: row.tollsCents,
          vehicleId: row.vehicleId,
          driverId: row.driverId,
          passengerIds: Set.unmodifiable(passengers),
          driverCounts: row.driverCounts,
          pricePerUnitMilli: row.pricePerUnitMilli,
          useKmRate: row.useKmRate,
        ),
      ),
    );
  }

  @override
  Stream<List<RideEntry>> watchRides(String groupId, RidePeriod period) => _dao
      .watchRides(groupId)
      .map(
        (rows) => List.unmodifiable([
          for (final r in rows)
            if (period.contains(r.date)) _map(r).orThrow(),
        ]),
      );

  @override
  Future<RepoResult<RideEntry>> get(String id) => guardStorage(() async {
    final row = await _dao.findRide(id);
    return row == null ? Err(NotFound('ride', id)) : _map(row);
  });

  RepositoryError? _invalid(Ride r) =>
      r.distanceMeters < 0 || r.tollsCents < 0 || r.pricePerUnitMilli < 0
      ? InvalidData('ride ${r.id}: distance, tolls and price must be >= 0')
      : null;

  Future<RepositoryError?> _missing(String groupId, Ride r) => missingRef(
    _db,
    groupId,
    vehicleId: r.vehicleId,
    memberIds: [r.driverId, ...r.passengerIds],
  );

  @override
  Future<RepoResult<RideEntry>> log(String groupId, Ride ride) =>
      guardStorage(() async {
        final invalid = _invalid(ride);
        if (invalid != null) return Err(invalid);
        final missing = await _missing(groupId, ride);
        if (missing != null) return Err(missing);
        if (await _dao.findRideAny(ride.id) != null) {
          return const Err(Conflict('ride id already exists'));
        }
        await _dao.insertRide(
          RidesCompanion.insert(
            id: ride.id,
            groupId: groupId,
            createdAt: _clock.now().toUtc(),
            updatedAt: Hlc.now(_clock),
            date: calendarDay(ride.date),
            distanceMeters: ride.distanceMeters,
            roundTrip: Value(ride.roundTrip),
            tollsCents: Value(ride.tollsCents),
            vehicleId: ride.vehicleId,
            driverId: ride.driverId,
            passengerIds: Value(encodeIds(ride.passengerIds)),
            driverCounts: Value(ride.driverCounts),
            pricePerUnitMilli: ride.pricePerUnitMilli,
            useKmRate: Value(ride.useKmRate),
          ),
        );
        return get(ride.id);
      });

  @override
  Future<RepoResult<RideEntry>> update(Ride ride) => guardStorage(() async {
    final invalid = _invalid(ride);
    if (invalid != null) return Err(invalid);
    final row = await _dao.findRide(ride.id);
    if (row == null) return Err(NotFound('ride', ride.id));
    if (row.settledExpenseId != null) return Err(Locked('ride', ride.id));
    final missing = await _missing(row.groupId, ride);
    if (missing != null) return Err(missing);
    await _dao.updateRide(
      ride.id,
      RidesCompanion(
        date: Value(calendarDay(ride.date)),
        distanceMeters: Value(ride.distanceMeters),
        roundTrip: Value(ride.roundTrip),
        tollsCents: Value(ride.tollsCents),
        vehicleId: Value(ride.vehicleId),
        driverId: Value(ride.driverId),
        passengerIds: Value(encodeIds(ride.passengerIds)),
        driverCounts: Value(ride.driverCounts),
        pricePerUnitMilli: Value(ride.pricePerUnitMilli),
        useKmRate: Value(ride.useKmRate),
        updatedAt: Value(Hlc.now(_clock)),
      ),
    );
    return get(ride.id);
  });

  @override
  Future<RepoResult<Undo>> softDelete(String id) => guardStorage(() async {
    final row = await _dao.findRide(id);
    if (row == null) return Err(NotFound('ride', id));
    if (row.settledExpenseId != null) return Err(Locked('ride', id));
    await _dao.updateRide(
      id,
      RidesCompanion(
        deletedAt: Value(_clock.now().toUtc()),
        updatedAt: Value(Hlc.now(_clock)),
      ),
    );
    return Ok(Undo(() => restore(id)));
  });

  @override
  Future<RepoResult<void>> restore(String id) => guardStorage(() async {
    if (await _dao.restoreRide(id, Hlc.now(_clock))) return const Ok(null);
    return await _dao.findRide(id) != null
        ? const Err(Conflict('ride is not deleted'))
        : Err(NotFound('ride', id));
  });

  @override
  Future<RepoResult<void>> markSettled(
    List<String> rideIds,
    String expenseId,
  ) => guardStorage(
    () => _db.transaction(() async {
      if (await _db.expensesDao.findById(expenseId) == null) {
        return Err<void, RepositoryError>(NotFound('expense', expenseId));
      }
      final rows = {for (final r in await _dao.findRides(rideIds)) r.id: r};
      for (final id in rideIds) {
        final row = rows[id];
        if (row == null || row.deletedAt != null) {
          return Err<void, RepositoryError>(NotFound('ride', id));
        }
        if (row.settledExpenseId != null) {
          return Err<void, RepositoryError>(Locked('ride', id));
        }
      }
      final hlc = Hlc.now(_clock);
      for (final id in rideIds) {
        await _dao.updateRide(
          id,
          RidesCompanion(
            settledExpenseId: Value(expenseId),
            updatedAt: Value(hlc),
          ),
        );
      }
      return const Ok<void, RepositoryError>(null);
    }),
  );

  @override
  Future<RepoResult<List<ExpenseEntry>>> settlePeriod(
    String groupId,
    List<PeriodSettlement> items,
  ) => guardStorage(() async {
    for (final item in items) {
      if (item.rideIds.isEmpty) {
        return const Err(InvalidData('a settlement needs at least one ride'));
      }
    }
    try {
      return await _db.transaction(() async {
        final created = <ExpenseEntry>[];
        for (final item in items) {
          final entry = switch (await _expenses.create(groupId, item.draft)) {
            Ok<ExpenseEntry, RepositoryError>(:final value) => value,
            Err<ExpenseEntry, RepositoryError>(:final error) => throw _Rollback(
              error,
            ),
          };
          final marked = await markSettled(item.rideIds, entry.expense.id);
          if (marked case Err<void, RepositoryError>(:final error)) {
            throw _Rollback(error);
          }
          created.add(entry);
        }
        return Ok<List<ExpenseEntry>, RepositoryError>(
          List.unmodifiable(created),
        );
      });
    } on _Rollback catch (e) {
      return Err(e.error);
    }
  });

  @override
  Future<RepoResult<void>> unsettle(List<String> expenseIds) =>
      guardStorage(() async {
        try {
          return await _db.transaction(() async {
            for (final id in expenseIds) {
              final deleted = await _expenses.softDelete(id);
              if (deleted case Err<Undo, RepositoryError>(:final error)) {
                throw _Rollback(error);
              }
            }
            final hlc = Hlc.now(_clock);
            for (final row in await _dao.findSettledBy(expenseIds)) {
              await _dao.updateRide(
                row.id,
                RidesCompanion(
                  settledExpenseId: const Value(null),
                  updatedAt: Value(hlc),
                ),
              );
            }
            return const Ok<void, RepositoryError>(null);
          });
        } on _Rollback catch (e) {
          return Err(e.error);
        }
      });
}

/// Thrown inside a transaction to roll it back with a typed error.
final class _Rollback implements Exception {
  const _Rollback(this.error);

  final RepositoryError error;
}
