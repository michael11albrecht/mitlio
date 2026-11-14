import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/rides/data/repositories/drift_ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/drift_rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/drift_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';

/// Drift by default; override with `FakeVehiclesRepository` in tests.
final vehiclesRepositoryProvider = Provider<VehiclesRepository>(
  (ref) => DriftVehiclesRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

/// Drift by default; override with `FakeRideTemplatesRepository` in tests.
final rideTemplatesRepositoryProvider = Provider<RideTemplatesRepository>(
  (ref) => DriftRideTemplatesRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

/// Drift by default; override with `FakeRidesRepository` in tests.
final ridesRepositoryProvider = Provider<RidesRepository>(
  (ref) => DriftRidesRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);
