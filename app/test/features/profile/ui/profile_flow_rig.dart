import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/fake_platform.dart';

/// A profile repository that can be made to fail.
class FlakyProfile extends FakeProfileRepository {
  RepositoryError? failSaveWith;

  @override
  Future<RepoResult<UserProfile>> save({
    required String displayName,
    int? avatarColor,
    String? avatarEmoji,
    String? paypalMe,
  }) async {
    final failure = failSaveWith;
    if (failure != null) return Err(failure);
    return super.save(
      displayName: displayName,
      avatarColor: avatarColor,
      avatarEmoji: avatarEmoji,
      paypalMe: paypalMe,
    );
  }
}

/// A bank repository that can be made to fail.
class FlakyBank extends FakeProfileBankRepository {
  FlakyBank({required super.profile});

  RepositoryError? failSaveWith;
  RepositoryError? failGetWith;

  @override
  Future<RepoResult<ProfileBank?>> get() async {
    final failure = failGetWith;
    return failure != null ? Err(failure) : super.get();
  }

  @override
  Future<RepoResult<ProfileBank>> save({
    required String iban,
    String? bic,
    String? accountName,
  }) async {
    final failure = failSaveWith;
    if (failure != null) return Err(failure);
    return super.save(iban: iban, bic: bic, accountName: accountName);
  }
}

/// All the profile flow's collaborators in memory, wired by [overrides].
class ProfileFlowRig {
  /// [launcher]: one the surrounding `FakeApp` already installs.
  ProfileFlowRig({FakeLinkLauncher? launcher})
    : _ownsLauncher = launcher == null,
      launcher = launcher ?? FakeLinkLauncher() {
    bank = FlakyBank(profile: profile);
  }

  final bool _ownsLauncher;

  final setup = FakeSetupStateRepository();
  final profile = FlakyProfile();
  late final FlakyBank bank;
  final FakeLinkLauncher launcher;

  List<Override> get overrides => [
    setupStateRepositoryProvider.overrideWithValue(setup),
    profileRepositoryProvider.overrideWithValue(profile),
    profileBankRepositoryProvider.overrideWithValue(bank),
    if (_ownsLauncher) linkLauncherProvider.overrideWithValue(launcher),
    setupFlowConfigsProvider.overrideWithValue({
      profileSetupFlow.id: profileSetupFlow,
    }),
  ];

  /// The rig's fakes into an app that has slots for them.
  void install(FakeApp app) {
    app
      ..profile = profile
      ..profileBank = bank
      ..setupState = setup;
  }

  /// What an app that [install]ed the rig still needs.
  List<Override> get flowOverrides => [
    setupFlowConfigsProvider.overrideWithValue({
      profileSetupFlow.id: profileSetupFlow,
    }),
  ];

  /// The saved profile; null if none.
  Future<UserProfile?> storedProfile() async =>
      (await profile.get() as Ok<UserProfile?, RepositoryError>).value;

  /// The saved bank details; null if none.
  Future<ProfileBank?> storedBank() async =>
      (await bank.get() as Ok<ProfileBank?, RepositoryError>).value;

  /// A container like a fresh app start (a "kill" is a new one).
  ProviderContainer container() => ProviderContainer(overrides: overrides);
}
