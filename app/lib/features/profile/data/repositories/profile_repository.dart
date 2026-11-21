// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The device owner's profile "Ich" (ADR-25). Local only; PII.
final class UserProfile {
  const UserProfile({
    required this.displayName,
    this.avatarColor,
    this.avatarEmoji,
    this.paypalMe,
  });

  final String displayName;

  /// ARGB colour of the initials avatar; null = derived default.
  final int? avatarColor;
  final String? avatarEmoji;

  /// Normalised handle (no `@`, no URL parts).
  final String? paypalMe;

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.displayName == displayName &&
      other.avatarColor == avatarColor &&
      other.avatarEmoji == avatarEmoji &&
      other.paypalMe == paypalMe;

  @override
  int get hashCode =>
      Object.hash(displayName, avatarColor, avatarEmoji, paypalMe);

  @override
  String toString() => 'UserProfile(paypal: ${paypalMe != null})';
}

/// The personal profile of this device. At most one exists. The full IBAN is
/// not here: see `ProfileBankRepository`.
abstract interface class ProfileRepository {
  /// Live profile; emits the current value (null if none yet), then after
  /// every change.
  Stream<UserProfile?> watchProfile();

  /// Null while no profile was saved.
  Future<RepoResult<UserProfile?>> get();

  /// Creates or replaces the profile. [displayName] is trimmed, 1..60 chars;
  /// [paypalMe] accepts any form and is normalised ([InvalidData] otherwise,
  /// naming the field only).
  Future<RepoResult<UserProfile>> save({
    required String displayName,
    int? avatarColor,
    String? avatarEmoji,
    String? paypalMe,
  });
}

/// Validates and normalises profile input.
RepoResult<UserProfile> buildUserProfile({
  required String displayName,
  int? avatarColor,
  String? avatarEmoji,
  String? paypalMe,
}) {
  final name = displayName.trim();
  if (name.isEmpty || name.length > 60) {
    return const Err(InvalidData('invalid: displayName'));
  }
  final emoji = avatarEmoji?.trim();
  final details = normalizePaymentDetails('me', paypalMe: paypalMe);
  return switch (details) {
    Err() => const Err(InvalidData('invalid: paypalMe')),
    Ok(:final value) => Ok(
      UserProfile(
        displayName: name,
        avatarColor: avatarColor,
        avatarEmoji: emoji == null || emoji.isEmpty ? null : emoji,
        paypalMe: value.paypalMe,
      ),
    ),
  };
}
