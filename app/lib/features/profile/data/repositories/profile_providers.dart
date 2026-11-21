import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/profile/data/repositories/drift_profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/drift_profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/drift_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';

/// Drift by default; override with `FakeProfileRepository` in tests.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => DriftProfileRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Drift by default; override with `FakeProfileBankRepository` in tests.
final profileBankRepositoryProvider = Provider<ProfileBankRepository>(
  (ref) => DriftProfileBankRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    cipher: ref.watch(ibanCipherProvider),
  ),
);

/// Drift by default; override with `FakeUserVehiclesRepository` in tests.
final userVehiclesRepositoryProvider = Provider<UserVehiclesRepository>(
  (ref) => DriftUserVehiclesRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
