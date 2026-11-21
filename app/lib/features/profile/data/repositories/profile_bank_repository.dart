// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The profile's bank details. [iban] is PII: never logged, never synced and
/// never part of `toString`.
final class ProfileBank {
  const ProfileBank({required this.iban, this.bic, this.accountName});

  /// Normalised IBAN, upper case without spaces.
  final String iban;
  final String? bic;
  final String? accountName;

  @override
  bool operator ==(Object other) =>
      other is ProfileBank &&
      other.iban == iban &&
      other.bic == bic &&
      other.accountName == accountName;

  @override
  int get hashCode => Object.hash(iban, bic, accountName);

  @override
  String toString() => 'ProfileBank(iban: set)';
}

/// IBAN of the profile; stays on the device (plan §8), optionally encrypted
/// at rest. Sync code must never use this (architecture test).
abstract interface class ProfileBankRepository {
  /// Null if none is stored.
  Future<RepoResult<ProfileBank?>> get();

  /// Validates, normalises and replaces the stored details. [NotFound] if no
  /// profile exists yet; [InvalidData] names the failing fields only, never
  /// their content.
  Future<RepoResult<ProfileBank>> save({
    required String iban,
    String? bic,
    String? accountName,
  });

  /// Removes the stored details; fine if there are none.
  Future<RepoResult<void>> clear();
}

/// Validates and normalises bank input with the member payment rules.
RepoResult<ProfileBank> buildProfileBank({
  required String iban,
  String? bic,
  String? accountName,
}) {
  final r = normalizePaymentDetails(
    'me',
    iban: iban,
    bic: bic,
    accountName: accountName,
  );
  return switch (r) {
    Err(:final error) => Err(
      InvalidData('invalid: ${error.keys.map((f) => f.name).join(', ')}'),
    ),
    Ok(:final value) when value.iban == null => const Err(
      InvalidData('invalid: iban'),
    ),
    Ok(:final value) => Ok(
      ProfileBank(
        iban: value.iban!,
        bic: value.bic,
        accountName: value.accountName,
      ),
    ),
  };
}
