import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/profile/data/repositories/drift_profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/drift_profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/drift_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/own_member_repository.dart';
import 'package:mitlio/features/profile/data/repositories/personal_car_links_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_links_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_payment_details_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/services/profile_photo_services.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';

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

/// In memory by default; `main.dart` overrides it with the file in the
/// private app folder. The photo never leaves the device.
final profilePhotoRepositoryProvider = Provider<ProfilePhotoRepository>(
  (ref) => FakeProfilePhotoRepository(),
);

/// Crop and compress for the profile photo.
final profilePhotoProcessorProvider = Provider<PhotoProcessor>(
  (ref) => const SquareCropPhotoProcessor(),
);

/// The camera and gallery. Null until the platform picker (`image_picker`) is
/// wired: the profile flow then offers no photo.
final photoSourceProvider = Provider<PhotoSource?>((ref) => null);

/// Override the launcher (`linkLauncherProvider`) in tests.
final profileLinksRepositoryProvider = Provider<ProfileLinksRepository>(
  (ref) => ProfileLinksRepository(launcher: ref.watch(linkLauncherProvider)),
);

/// Which members are "Ich" (local only).
final ownMemberRepositoryProvider = Provider<OwnMemberRepository>(
  (ref) => OwnMemberRepository(ref.watch(setupStateRepositoryProvider)),
);

/// Personal cars and their copies in groups.
final personalCarLinksRepositoryProvider = Provider<PersonalCarLinksRepository>(
  (ref) => PersonalCarLinksRepository(
    personal: ref.watch(userVehiclesRepositoryProvider),
    groupVehicles: ref.watch(vehiclesRepositoryProvider),
  ),
);

/// Payment details for paying someone: the own member falls back to the
/// profile. Used where money is paid out; the member forms read the plain
/// repository.
final payoutDetailsRepositoryProvider = Provider<PaymentDetailsRepository>(
  (ref) => ProfilePaymentDetailsRepository(
    inner: ref.watch(paymentDetailsRepositoryProvider),
    own: ref.watch(ownMemberRepositoryProvider),
    profile: ref.watch(profileRepositoryProvider),
    bank: ref.watch(profileBankRepositoryProvider),
  ),
);
