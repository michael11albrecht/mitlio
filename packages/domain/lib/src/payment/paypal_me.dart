// Justification: no fields; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/money/money.dart';

/// Why a PayPal.Me link could not be built.
sealed class PayPalError {
  const PayPalError();
}

/// The handle is empty, too long or contains characters outside `A-Za-z0-9`.
final class InvalidHandle extends PayPalError {
  const InvalidHandle();

  @override
  bool operator ==(Object other) => other is InvalidHandle;

  @override
  int get hashCode => (InvalidHandle).hashCode;

  @override
  String toString() => 'InvalidHandle()';
}

/// The amount is zero or negative.
final class NonPositiveAmount extends PayPalError {
  const NonPositiveAmount();

  @override
  bool operator ==(Object other) => other is NonPositiveAmount;

  @override
  int get hashCode => (NonPositiveAmount).hashCode;

  @override
  String toString() => 'NonPositiveAmount()';
}

final _handlePattern = RegExp(r'^[A-Za-z0-9]{1,20}$');

/// A validated PayPal.Me handle (1 to 20 characters of `A-Za-z0-9`).
///
/// See docs/domain-rules.md "PayPal.Me handle and link (P2-T09, PU-T02)".
final class PaypalMeHandle {
  const PaypalMeHandle._(this.value);

  /// The bare handle, e.g. `maxmuster`. Case is preserved.
  final String value;

  /// Accepts `x`, `@x`, `paypal.me/x`, `https://www.paypal.me/x/?a=b` and
  /// similar forms; returns [InvalidHandle] for anything else.
  static Result<PaypalMeHandle, PayPalError> parse(String input) {
    final normalized = _normalizeHandle(input);
    if (!_handlePattern.hasMatch(normalized)) {
      return const Err(InvalidHandle());
    }
    return Ok(PaypalMeHandle._(normalized));
  }

  /// The canonical short form `paypal.me/<handle>`; `parse(format())` returns
  /// an equal handle.
  String format() => 'paypal.me/$value';

  /// `https://paypal.me/<handle>`, or with [amount]
  /// `https://paypal.me/<handle>/<amount><CODE>`. A non-positive [amount]
  /// returns [NonPositiveAmount].
  Result<Uri, PayPalError> link({Money? amount}) {
    if (amount == null) return Ok(Uri.parse('https://paypal.me/$value'));
    if (!amount.isPositive) return const Err(NonPositiveAmount());
    final path = '$value/${_formatMajor(amount)}${amount.currency.code}';
    return Ok(Uri.parse('https://paypal.me/$path'));
  }

  @override
  bool operator ==(Object other) =>
      other is PaypalMeHandle && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PaypalMeHandle($value)';
}

/// Builds `https://paypal.me/<handle>/<amount><CODE>`.
///
/// See docs/domain-rules.md "PayPal.Me handle and link (P2-T09, PU-T02)".
Result<Uri, PayPalError> buildPayPalMeLink({
  required String handle,
  required Money amount,
}) => switch (PaypalMeHandle.parse(handle)) {
  Ok(:final value) => value.link(amount: amount),
  Err(:final error) => Err(error),
};

String _normalizeHandle(String input) {
  var h = input.trim();
  // Share links carry tracking parameters; the handle ends before them.
  final cut = h.indexOf(RegExp('[?#]'));
  if (cut >= 0) h = h.substring(0, cut);
  if (h.startsWith('@')) h = h.substring(1);
  for (final prefix in const ['https://', 'http://', 'www.', 'paypal.me/']) {
    if (h.toLowerCase().startsWith(prefix)) h = h.substring(prefix.length);
  }
  if (h.endsWith('/')) h = h.substring(0, h.length - 1);
  return h;
}

/// Major units with exactly `minorUnits` decimals; integer arithmetic only.
String _formatMajor(Money amount) {
  final digits = amount.currency.minorUnits;
  final cents = amount.cents;
  if (digits == 0) return '$cents';
  var divisor = 1;
  for (var i = 0; i < digits; i++) {
    divisor *= 10;
  }
  final fraction = (cents % divisor).toString().padLeft(digits, '0');
  return '${cents ~/ divisor}.$fraction';
}
