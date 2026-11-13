// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/money/currency.dart';

/// Thrown when a [Money] amount would exceed [Money.maxAbsCents].
final class MoneyOverflow implements Exception {
  /// Creates an overflow exception for [cents].
  const MoneyOverflow(this.cents);

  /// The offending amount.
  final int cents;

  @override
  String toString() => 'MoneyOverflow($cents)';
}

/// An amount in integer minor units ("cents") of a [Currency].
final class Money implements Comparable<Money> {
  /// Creates money; throws [MoneyOverflow] if `|cents| > maxAbsCents`.
  Money(this.cents, this.currency) {
    if (cents > maxAbsCents || cents < -maxAbsCents) {
      throw MoneyOverflow(cents);
    }
  }

  /// Largest absolute amount, safe for dart2js (below 2^53).
  static const int maxAbsCents = 999999999999999;

  final int cents;
  final Currency currency;

  Money operator +(Money other) {
    _check(other);
    return Money(cents + other.cents, currency);
  }

  Money operator -(Money other) {
    _check(other);
    return Money(cents - other.cents, currency);
  }

  Money operator -() => Money(-cents, currency);

  bool get isZero => cents == 0;
  bool get isNegative => cents < 0;
  bool get isPositive => cents > 0;

  @override
  int compareTo(Money other) {
    _check(other);
    return cents.compareTo(other.cents);
  }

  void _check(Money other) {
    if (other.currency != currency) {
      throw ArgumentError.value(
        other.currency.code,
        'other',
        'currency mismatch with ${currency.code}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.cents == cents && other.currency == currency;

  @override
  int get hashCode => Object.hash(cents, currency);

  @override
  String toString() => 'Money($cents ${currency.code})';
}
