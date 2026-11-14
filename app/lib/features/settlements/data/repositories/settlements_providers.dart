import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/settlements/data/repositories/drift_settlements_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';

/// Drift by default; override with `FakeSettlementsRepository` in tests.
final settlementsRepositoryProvider = Provider<SettlementsRepository>(
  (ref) => DriftSettlementsRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
