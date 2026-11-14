import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/fx/data/repositories/fx_rates_repository.dart';
import 'package:mitlio/features/fx/data/services/fx_rate_service.dart';

/// No backend by default (no suggestion); `main` overrides it with the HTTP
/// service when `SUPABASE_URL` is set, tests and DebugDrive with the fake.
final fxRateServiceProvider = Provider<FxRateService>(
  (ref) => const UnavailableFxRateService(),
);

/// Lives as long as the app, so rates survive screens.
final fxRatesRepositoryProvider = Provider<FxRatesRepository>(
  (ref) => FxRatesRepository(
    service: ref.watch(fxRateServiceProvider),
    clock: ref.watch(clockProvider),
  ),
);
