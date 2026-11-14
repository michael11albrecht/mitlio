// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The inputs of the payment details form.
enum PaymentField { paypalMe, iban, bic, accountName }

/// Why one field was rejected. Never carries the input (IBAN is PII).
enum PaymentFieldError { invalid, checksum }

/// A member's payment details. [iban] is PII: it is never logged, never
/// synced and never part of `toString`.
final class PaymentDetails {
  const PaymentDetails({
    required this.memberId,
    this.paypalMe,
    this.iban,
    this.bic,
    this.accountName,
  });

  final String memberId;

  /// Normalised handle (no `@`, no URL parts). Synced with the member.
  final String? paypalMe;

  /// Normalised IBAN, upper case without spaces. Local only.
  final String? iban;
  final String? bic;
  final String? accountName;

  /// Masked IBAN for synced storage and lists: `DE89 •••• 3000`.
  String? get ibanHint => maskIban(iban);

  @override
  bool operator ==(Object other) =>
      other is PaymentDetails &&
      other.memberId == memberId &&
      other.paypalMe == paypalMe &&
      other.iban == iban &&
      other.bic == bic &&
      other.accountName == accountName;

  @override
  int get hashCode => Object.hash(memberId, paypalMe, iban, bic, accountName);

  @override
  String toString() =>
      'PaymentDetails($memberId, paypal: ${paypalMe != null}, '
      'iban: ${iban != null})';
}

/// `DE89 •••• 3000` for a normalised IBAN; null for null or a short value.
String? maskIban(String? iban) => iban == null || iban.length < 8
    ? null
    : '${iban.substring(0, 4)} •••• ${iban.substring(iban.length - 4)}';

final _bicPattern = RegExp(r'^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$');

String? _blankToNull(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

/// Validates and normalises raw form input. Blank means "not set". BIC and
/// account name need an IBAN (they are dropped from the result otherwise, but
/// given without an IBAN they are an error on the IBAN field).
Result<PaymentDetails, Map<PaymentField, PaymentFieldError>>
normalizePaymentDetails(
  String memberId, {
  String? paypalMe,
  String? iban,
  String? bic,
  String? accountName,
}) {
  final errors = <PaymentField, PaymentFieldError>{};

  String? handle;
  final rawHandle = _blankToNull(paypalMe);
  if (rawHandle != null) {
    final link = buildPayPalMeLink(
      handle: rawHandle,
      amount: Money(1, Currency.eur),
    );
    switch (link) {
      case Ok(:final value):
        handle = value.pathSegments.first;
      case Err():
        errors[PaymentField.paypalMe] = PaymentFieldError.invalid;
    }
  }

  String? normalizedIban;
  final rawIban = _blankToNull(iban);
  if (rawIban != null) {
    switch (normalizeIban(rawIban)) {
      case Ok(:final value):
        normalizedIban = value;
      case Err(error: InvalidChecksum()):
        errors[PaymentField.iban] = PaymentFieldError.checksum;
      case Err():
        errors[PaymentField.iban] = PaymentFieldError.invalid;
    }
  }

  final rawBic = _blankToNull(bic)?.toUpperCase();
  if (rawBic != null && !_bicPattern.hasMatch(rawBic)) {
    errors[PaymentField.bic] = PaymentFieldError.invalid;
  }
  final name = _blankToNull(accountName);
  if (name != null && (name.length > 70 || name.contains('\n'))) {
    errors[PaymentField.accountName] = PaymentFieldError.invalid;
  }
  if (rawIban == null && (rawBic != null || name != null)) {
    errors[PaymentField.iban] = PaymentFieldError.invalid;
  }

  if (errors.isNotEmpty) return Err(errors);
  return Ok(
    PaymentDetails(
      memberId: memberId,
      paypalMe: handle,
      iban: normalizedIban,
      bic: normalizedIban == null ? null : rawBic,
      accountName: normalizedIban == null ? null : name,
    ),
  );
}

/// Payment details of members. The PayPal.Me handle and the masked IBAN hint
/// live on the synced member; IBAN, BIC and account name are local only
/// (plan §8) and optionally encrypted at rest.
abstract interface class PaymentDetailsRepository {
  /// [NotFound] if the member does not exist. Empty details if none are set.
  Future<RepoResult<PaymentDetails>> get(String memberId);

  /// Replaces all details of the member after normalising them. Blank values
  /// clear a field; no IBAN clears the local bank row. [InvalidData] names
  /// the failing fields only, never their content.
  Future<RepoResult<PaymentDetails>> save(
    String memberId, {
    String? paypalMe,
    String? iban,
    String? bic,
    String? accountName,
  });
}
