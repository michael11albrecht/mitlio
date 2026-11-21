import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart'
    show UserProfile;
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The calm inline cards that offer a setup flow where its data is needed
/// (ADR-25 §5). The names are stored; never rename after release.
enum EntryCard {
  /// Settle screen while neither PayPal.Me nor IBAN is in the profile.
  settlePayment,

  /// Vehicle list of a group while there is no personal car.
  groupCar,

  /// Creating a group while there is no profile yet.
  newGroupProfile,
}

/// One inline just-in-time card (ADR-25 §5): shown while its data is
/// missing and it was not dismissed; gone for good once dismissed, and gone
/// by itself once the data exists (the flow was finished).
///
/// Starts hidden. A card is only a hint, so when what it depends on cannot be
/// read it stays hidden rather than showing a wrong offer; the screen it sits
/// on shows its own errors. If only the "dismissed" flag cannot be read the
/// card is shown, never silently hidden.
class EntryCardViewModel extends Notifier<bool> {
  EntryCardViewModel(this.card);

  final EntryCard card;

  @override
  bool build() {
    unawaited(refresh());
    return false;
  }

  /// Reads everything again; call after returning from the flow the card
  /// offers.
  Future<void> refresh() async {
    final dismissed = await ref
        .read(entryCardsRepositoryProvider)
        .isDismissed(card.name);
    if (dismissed case Ok(value: true)) return _set(false);
    _set(await _needed());
  }

  void _set(bool visible) {
    if (ref.mounted) state = visible;
  }

  /// "Nicht mehr anzeigen": hides the card for good.
  Future<RepoResult<void>> dismiss() async {
    final saved = await ref
        .read(entryCardsRepositoryProvider)
        .dismiss(card.name);
    if (saved is Ok) _set(false);
    return saved;
  }

  Future<bool> _needed() async {
    final profile = await ref.read(profileRepositoryProvider).get();
    final UserProfile? me;
    switch (profile) {
      case Err():
        return false;
      case Ok(:final value):
        me = value;
    }
    switch (card) {
      case EntryCard.settlePayment:
        if (me?.paypalMe != null) return false;
        final bank = await ref.read(profileBankRepositoryProvider).get();
        return switch (bank) {
          Ok(:final value) => value == null,
          Err() => false,
        };
      case EntryCard.groupCar:
        final cars = await _first(
          ref.read(userVehiclesRepositoryProvider).watchVehicles(),
        );
        return cars != null && cars.isEmpty;
      case EntryCard.newGroupProfile:
        if (me != null) return false;
        final groups = await _first(
          ref.read(groupsRepositoryProvider).watchGroups(),
        );
        return groups != null && groups.isNotEmpty;
    }
  }

  /// The current list; null if the stream fails (the card then stays hidden,
  /// see the class comment).
  Future<List<T>?> _first<T>(Stream<List<T>> stream) async {
    try {
      return await stream.first;
    } on Object {
      return null;
    }
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final entryCardViewModelProvider = NotifierProvider.autoDispose
    .family<EntryCardViewModel, bool, EntryCard>(EntryCardViewModel.new);
