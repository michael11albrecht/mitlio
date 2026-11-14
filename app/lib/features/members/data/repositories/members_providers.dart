import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/members/data/repositories/drift_members_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';

/// Drift by default; override with `FakeMembersRepository` in tests.
final membersRepositoryProvider = Provider<MembersRepository>(
  (ref) => DriftMembersRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
