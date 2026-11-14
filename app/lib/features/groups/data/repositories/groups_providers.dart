import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/groups/data/repositories/drift_groups_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';

/// Drift by default; override with `FakeGroupsRepository` in tests.
final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => DriftGroupsRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
