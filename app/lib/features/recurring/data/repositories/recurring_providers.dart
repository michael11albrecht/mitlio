import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/recurring/data/repositories/drift_recurring_repository.dart';
import 'package:mitlio/features/recurring/data/repositories/recurring_repository.dart';

/// Drift by default; override with `FakeRecurringRepository` in tests.
final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => DriftRecurringRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
