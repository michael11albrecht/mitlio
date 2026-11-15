import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/sync/data/drift_sync_state_repository.dart';
import 'package:mitlio/features/sync/data/sync_state_repository.dart';

final syncStateRepositoryProvider = Provider<SyncStateRepository>(
  (ref) => DriftSyncStateRepository(ref.watch(appDatabaseProvider)),
);
