import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/qr_share_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What "Mein QR-Code teilen" shows.
sealed class MyQrState {
  const MyQrState();
}

final class MyQrLoading extends MyQrState {
  const MyQrLoading();
}

final class MyQrFailure extends MyQrState {
  const MyQrFailure(this.error);

  final RepositoryError error;
}

/// No profile or no IBAN saved: there is nothing to share yet.
final class MyQrNoIban extends MyQrState {
  const MyQrNoIban();
}

/// [payload] is the EPC text without amount (PII: not in `toString`).
final class MyQrLoaded extends MyQrState {
  const MyQrLoaded({required this.name, required this.payload});

  /// The account holder shown under the code.
  final String name;
  final String payload;

  @override
  String toString() => 'MyQrLoaded(name: $name)';
}

/// "Mein QR-Code teilen" (PU-T16, ADR-25 §1): the profile's IBAN as an EPC QR
/// without amount, shared as a PNG through the share sheet. Pure client side:
/// the IBAN never goes to a server, only to the app the user picks.
class MyQrViewModel extends Notifier<MyQrState> {
  @override
  MyQrState build() {
    unawaited(load());
    return const MyQrLoading();
  }

  /// Reads the profile and builds the QR text; also the retry after a failure.
  Future<void> load() async {
    final next = await _read();
    if (ref.mounted) state = next;
  }

  Future<MyQrState> _read() async {
    final bankResult = await ref.read(profileBankRepositoryProvider).get();
    final profileResult = await ref.read(profileRepositoryProvider).get();
    if (bankResult case Err(:final error)) return MyQrFailure(error);
    if (profileResult case Err(:final error)) return MyQrFailure(error);
    final bank = (bankResult as Ok<ProfileBank?, RepositoryError>).value;
    final profile = (profileResult as Ok<UserProfile?, RepositoryError>).value;
    if (bank == null || profile == null) return const MyQrNoIban();
    final holder = bank.accountName ?? profile.displayName;
    return switch (buildEpcQrPayload(
      name: holder,
      iban: bank.iban,
      bic: bank.bic,
      amount: null,
    )) {
      Ok(:final value) => MyQrLoaded(name: holder, payload: value),
      Err() => const MyQrFailure(InvalidData('qr: name')),
    };
  }

  /// Renders the code as PNG and opens the share sheet. An error comes back
  /// as `Err` for the screen to show.
  Future<RepoResult<void>> share() async {
    final current = state;
    if (current is! MyQrLoaded) {
      return const Err(NotFound('profile_bank', 'me'));
    }
    return ref.read(qrShareRepositoryProvider).sharePng(current.payload);
  }
}

// ignore: specify_nonobvious_property_types, the autoDispose provider type is not exported
final myQrViewModelProvider =
    NotifierProvider.autoDispose<MyQrViewModel, MyQrState>(
      MyQrViewModel.new,
    );
