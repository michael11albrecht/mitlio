import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/app_config.dart';
import 'package:mitlio/core/app_version.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_providers.dart';
import 'package:mitlio/features/fuel/data/services/eu_oil_bulletin_service.dart';
import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart';
import 'package:mitlio/features/fuel/data/services/geolocator_location_service.dart';
import 'package:mitlio/features/fx/data/repositories/fx_providers.dart';
import 'package:mitlio/features/fx/data/services/fx_rate_service.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart'
    show carFlowConfigs;
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio/features/push/data/push_providers.dart';
import 'package:mitlio/features/push/data/push_state_store.dart';
import 'package:mitlio/features/routes/data/repositories/route_providers.dart';
import 'package:mitlio/features/routes/data/services/route_distance_service.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment();
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final db = AppDatabase(
    NativeDatabase.createInBackground(File('${dir.path}/mitlio.sqlite')),
  );
  final crashReporter = CrashReporter(
    // Empty in the repo (flavor config files): empty means no Sentry.
    dsn: config.sentryDsn,
    store: FileCrashReportingStore(File('${dir.path}/crash_reporting_on')),
  );
  await crashReporter.start();
  final remoteBackend = await RemoteBackend.initialize(
    config,
    store: const FlutterSecretStore(),
    logger: const DeveloperLogger(),
  );
  final appVersion = await _readAppVersion(const DeveloperLogger());
  final container = ProviderContainer(
    overrides: [
      remoteBackendProvider.overrideWithValue(remoteBackend),
      // Read once for the version gate (P6-T16). Unreadable: null, so the
      // gate cannot compare and does not block.
      appVersionProvider.overrideWithValue(appVersion),
      // With a backend: its Edge Function (national, postcode, nearby).
      // Without: the national average straight from the EU Weekly Oil
      // Bulletin, cached in a file; no postcode, no location.
      fuelPriceServiceProvider.overrideWithValue(
        config.hasBackend
            ? HttpFuelPriceService(
                baseUrl: config.supabaseUrl,
                anonKey: config.supabaseAnonKey,
              )
            : EuOilBulletinService(
                clock: const SystemClock(),
                cacheFile: File('${dir.path}/eu_oil_bulletin.json'),
              ),
      ),
      // Coarse location only on the shipped mobile targets; the Linux harness
      // keeps the no-op service.
      if (Platform.isAndroid || Platform.isIOS)
        locationServiceProvider.overrideWithValue(
          const GeolocatorLocationService(),
        ),
      // Same for "Strecke berechnen": without a backend the forms show only
      // the manual kilometre field.
      if (config.hasBackend)
        routeDistanceServiceProvider.overrideWithValue(
          HttpRouteDistanceService(
            baseUrl: config.supabaseUrl,
            anonKey: config.supabaseAnonKey,
          ),
        ),
      // Same for the ECB rate suggestion in the expense form.
      if (config.hasBackend)
        fxRateServiceProvider.overrideWithValue(
          HttpFxRateService(
            baseUrl: config.supabaseUrl,
            anonKey: config.supabaseAnonKey,
          ),
        ),
      // The guided flows DebugDrive can drive (`ext.mitlio.setup.*`).
      setupFlowConfigsProvider.overrideWithValue({
        profileSetupFlow.id: profileSetupFlow,
        ...carFlowConfigs,
      }),
      appDatabaseProvider.overrideWithValue(db),
      crashReporterProvider.overrideWithValue(crashReporter),
      // No pushServiceProvider override: Firebase arrives with P6b-T01, until
      // then the app reports "no push in this build" (UnavailablePushService).
      pushStateStoreProvider.overrideWithValue(
        FilePushStateStore(File('${dir.path}/push_state.json')),
      ),
    ],
  );
  // One node id per install, created on first start (plan 2.4, ADR-07).
  Hlc.init(
    await db.syncStateDao.hlcNodeId(container.read(idGeneratorProvider)),
  );
  container.read(errorSinkProvider).install();
  // Syncs shared groups on start and on resume; with none, no network call
  // and no sign-in happen.
  unawaited(container.read(syncCoordinatorProvider).start());
  if (kDebugMode) registerDebugDrive(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const MitlioApp()),
  );
}

/// The app's version from the platform; null (and logged) when unreadable.
Future<String?> _readAppVersion(Logger logger) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Object catch (e, st) {
    logger.error('cannot read the app version, version gate is open', e, st);
    return null;
  }
}
