import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What the settings row "Mein Profil" says about the profile: the one place
/// that shows how complete it is (ADR-25 §5: no badges elsewhere).
enum ProfileSummary {
  /// No profile yet, or it could not be read (the row then offers the setup).
  none,

  /// A profile without PayPal.Me and IBAN.
  noPayment,
  paypal,
  iban,
  both,
}

/// The completeness of the profile for the settings row. A failing read is
/// [ProfileSummary.none]: the row then shows the plain invitation, and
/// opening it shows the profile flow with its own error handling.
class ProfileEntryViewModel extends Notifier<ProfileSummary> {
  @override
  ProfileSummary build() {
    unawaited(refresh());
    return ProfileSummary.none;
  }

  /// Reads the profile again; call after returning from the profile flow.
  Future<void> refresh() async {
    final profile = await ref.read(profileRepositoryProvider).get();
    final bank = await ref.read(profileBankRepositoryProvider).get();
    if (!ref.mounted) return;
    final me = switch (profile) {
      Ok(:final value) => value,
      Err() => null,
    };
    final hasIban = switch (bank) {
      Ok(:final value) => value != null,
      Err() => false,
    };
    final hasPaypal = me?.paypalMe != null;
    state = switch ((me, hasPaypal, hasIban)) {
      (null, _, _) => ProfileSummary.none,
      (_, true, true) => ProfileSummary.both,
      (_, true, false) => ProfileSummary.paypal,
      (_, false, true) => ProfileSummary.iban,
      _ => ProfileSummary.noPayment,
    };
  }
}

// ignore: specify_nonobvious_property_types, the autoDispose provider type is not exported
final profileEntryViewModelProvider =
    NotifierProvider.autoDispose<ProfileEntryViewModel, ProfileSummary>(
      ProfileEntryViewModel.new,
    );
