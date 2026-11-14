import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/settings/data/repositories/data_deletion_repository.dart';
import 'package:mitlio/features/settings/data/services/server_data_service.dart';

/// Inert until accounts exist; override with `FakeServerDataService` in tests.
final serverDataServiceProvider = Provider<ServerDataService>(
  (ref) => const InertServerDataService(),
);

/// Drift by default; override with `FakeDataDeletionRepository` in tests.
final dataDeletionRepositoryProvider = Provider<DataDeletionRepository>(
  (ref) => DriftDataDeletionRepository(
    db: ref.watch(appDatabaseProvider),
    cipher: ref.watch(ibanCipherProvider),
    crashReporter: ref.watch(crashReporterProvider),
    server: ref.watch(serverDataServiceProvider),
  ),
);
