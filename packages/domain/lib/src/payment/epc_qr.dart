// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/money/currency.dart';
import 'package:mitlio_domain/src/money/money.dart';
import 'package:mitlio_domain/src/payment/iban.dart';

/// Why an EPC QR payload could not be built. Carries no input (PII-safe).
sealed class EpcError {
  const EpcError();
}

/// Name empty or longer than 70 characters after trimming, or contains a
/// line break.
final class InvalidName extends EpcError {
  /// Creates the error.
  const InvalidName();

  @override
  bool operator ==(Object other) => other is InvalidName;

  @override
  int get hashCode => (InvalidName).hashCode;

  @override
  String toString() => 'InvalidName';
}

/// The IBAN failed validation.
final class InvalidIban extends EpcError {
  /// Creates the error wrapping the IBAN [cause].
  const InvalidIban(this.cause);

  /// The underlying IBAN problem.
  final IbanError cause;

  @override
  bool operator ==(Object other) =>
      other is InvalidIban && other.cause == cause;

  @override
  int get hashCode => Object.hash(InvalidIban, cause);

  @override
  String toString() => 'InvalidIban($cause)';
}

/// The BIC is neither 8 nor 11 alphanumeric characters of the right shape.
final class InvalidBic extends EpcError {
  /// Creates the error.
  const InvalidBic();

  @override
  bool operator ==(Object other) => other is InvalidBic;

  @override
  int get hashCode => (InvalidBic).hashCode;

  @override
  String toString() => 'InvalidBic';
}

/// The amount is not in EUR.
final class NotEur extends EpcError {
  /// Creates the error.
  const NotEur();

  @override
  bool operator ==(Object other) => other is NotEur;

  @override
  int get hashCode => (NotEur).hashCode;

  @override
  String toString() => 'NotEur';
}

/// The amount is outside 1..99999999999 cents.
final class AmountOutOfRange extends EpcError {
  /// Creates the error.
  const AmountOutOfRange();

  @override
  bool operator ==(Object other) => other is AmountOutOfRange;

  @override
  int get hashCode => (AmountOutOfRange).hashCode;

  @override
  String toString() => 'AmountOutOfRange';
}

/// The remittance text exceeds 140 characters after trimming.
final class RemittanceTooLong extends EpcError {
  /// Creates the error.
  const RemittanceTooLong();

  @override
  bool operator ==(Object other) => other is RemittanceTooLong;

  @override
  int get hashCode => (RemittanceTooLong).hashCode;

  @override
  String toString() => 'RemittanceTooLong';
}

final _bicFormat = RegExp(r'^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$');
final _lineBreaks = RegExp(r'[\r\n]+');

const _maxName = 70;
const _maxRemittance = 140;
const _maxCents = 99999999999;

/// Builds the EPC069-12 (version 002, UTF-8) "SEPA credit transfer" QR text.
///
/// Validation order (first failure wins): name, iban, bic, amount (currency
/// before range), remittance.
///
/// Lengths count Unicode code points. A [name] containing a line break is
/// [InvalidName]; line breaks in [remittance] are replaced by a single space
/// so the payload always has exactly 11 lines. An empty [bic] after trimming
/// is omitted.
Result<String, EpcError> buildEpcQrPayload({
  required String name,
  required String iban,
  required Money amount,
  String? bic,
  String remittance = '',
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty ||
      trimmedName.runes.length > _maxName ||
      _lineBreaks.hasMatch(trimmedName)) {
    return const Err(InvalidName());
  }

  final String normalizedIban;
  switch (normalizeIban(iban)) {
    case Ok(:final value):
      normalizedIban = value;
    case Err(:final error):
      return Err(InvalidIban(error));
  }

  final normalizedBic = bic?.trim().toUpperCase() ?? '';
  if (normalizedBic.isNotEmpty && !_bicFormat.hasMatch(normalizedBic)) {
    return const Err(InvalidBic());
  }

  if (amount.currency != Currency.eur) return const Err(NotEur());
  if (amount.cents < 1 || amount.cents > _maxCents) {
    return const Err(AmountOutOfRange());
  }

  final text = remittance.trim().replaceAll(_lineBreaks, ' ');
  if (text.runes.length > _maxRemittance) {
    return const Err(RemittanceTooLong());
  }

  final euros = amount.cents ~/ 100;
  final cents = (amount.cents % 100).toString().padLeft(2, '0');
  return Ok(
    [
      'BCD',
      '002',
      '1',
      'SCT',
      normalizedBic,
      trimmedName,
      normalizedIban,
      'EUR$euros.$cents',
      '',
      '',
      text,
    ].join('\n'),
  );
}
