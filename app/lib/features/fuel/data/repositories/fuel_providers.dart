import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_prices_repository.dart';
import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart';
import 'package:mitlio/features/fuel/data/services/location_service.dart';

/// No backend by default (chips hidden); `main` overrides it with the HTTP
/// service when `SUPABASE_URL` is set, tests and DebugDrive with the fake.
final fuelPriceServiceProvider = Provider<FuelPriceService>(
  (ref) => const UnavailableFuelPriceService(),
);

/// No location plugin by default (see `NoLocationService`); `main` wires
/// the real one on Android and iOS only.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const NoLocationService(),
);

/// Lives as long as the app, so the last known price survives screens.
final fuelPricesRepositoryProvider = Provider<FuelPricesRepository>(
  (ref) => FuelPricesRepository(
    service: ref.watch(fuelPriceServiceProvider),
    location: ref.watch(locationServiceProvider),
    clock: ref.watch(clockProvider),
  ),
);
