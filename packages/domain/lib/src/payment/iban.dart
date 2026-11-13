// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/core/result.dart';

/// Why an IBAN was rejected. Carries no input, so it is safe to log (PII).
sealed class IbanError {
  const IbanError();
}

/// Not `CC dd` plus 11-30 alphanumerics (total 15-34 characters).
final class InvalidFormat extends IbanError {
  /// Creates the error.
  const InvalidFormat();

  @override
  bool operator ==(Object other) => other is InvalidFormat;

  @override
  int get hashCode => (InvalidFormat).hashCode;

  @override
  String toString() => 'InvalidFormat';
}

/// Format is fine but the ISO 7064 mod-97 check fails.
final class InvalidChecksum extends IbanError {
  /// Creates the error.
  const InvalidChecksum();

  @override
  bool operator ==(Object other) => other is InvalidChecksum;

  @override
  int get hashCode => (InvalidChecksum).hashCode;

  @override
  String toString() => 'InvalidChecksum';
}

final _ibanFormat = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$');
final _whitespace = RegExp(r'\s+');

/// Removes all whitespace, upper-cases and validates [input] as an IBAN
/// (format, then mod-97). Returns the normalized IBAN.
Result<String, IbanError> normalizeIban(String input) {
  final iban = input.replaceAll(_whitespace, '').toUpperCase();
  if (!_ibanFormat.hasMatch(iban)) return const Err(InvalidFormat());
  if (_mod97(iban) != 1) return const Err(InvalidChecksum());
  return Ok(iban);
}

/// Mod-97 of the rearranged IBAN, digit by digit (letters expand to two
/// digits), so intermediate values stay tiny.
int _mod97(String iban) {
  final rearranged = iban.substring(4) + iban.substring(0, 4);
  var rem = 0;
  for (final unit in rearranged.codeUnits) {
    if (unit >= 0x41) {
      rem = (rem * 100 + (unit - 0x41 + 10)) % 97;
    } else {
      rem = (rem * 10 + (unit - 0x30)) % 97;
    }
  }
  return rem;
}
