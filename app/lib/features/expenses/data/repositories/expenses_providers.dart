import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/expenses/data/repositories/drift_expenses_repository.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';

/// Drift by default; override with `FakeExpensesRepository` in tests.
final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => DriftExpensesRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
