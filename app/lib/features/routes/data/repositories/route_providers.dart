import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/routes/data/repositories/drift_places_repository.dart';
import 'package:mitlio/features/routes/data/repositories/places_repository.dart';
import 'package:mitlio/features/routes/data/repositories/route_distance_repository.dart';
import 'package:mitlio/features/routes/data/services/route_distance_service.dart';

/// No backend by default (the forms show only the manual kilometre field);
/// `main` overrides it with the HTTP service when `SUPABASE_URL` is set,
/// tests and DebugDrive with the fake.
final routeDistanceServiceProvider = Provider<RouteDistanceService>(
  (ref) => const UnavailableRouteDistanceService(),
);

final routeDistanceRepositoryProvider = Provider<RouteDistanceRepository>(
  (ref) => RouteDistanceRepository(ref.watch(routeDistanceServiceProvider)),
);

/// Drift by default; override with `FakePlacesRepository` in tests.
final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => DriftPlacesRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);
