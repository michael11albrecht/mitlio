import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/setup/data/drift_setup_state_repository.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';

final setupStateRepositoryProvider = Provider<SetupStateRepository>(
  (ref) => DriftSetupStateRepository(ref.watch(appDatabaseProvider)),
);
