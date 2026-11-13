// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/money/currency.dart';
import 'package:mitlio_domain/src/money/money.dart';

/// An exchange rate: units of `to` major per 1 `from` major, times 1e6.
final class FxRate {
  /// Creates a rate; throws [ArgumentError] unless [ppm] is positive.
  FxRate(this.ppm) {
    if (ppm <= 0) {
      throw ArgumentError.value(ppm, 'ppm', 'must be > 0');
    }
  }

  /// Parts per million: 1000000 means 1 `from` major = 1 `to` major.
  final int ppm;

  @override
  bool operator ==(Object other) => other is FxRate && other.ppm == ppm;

  @override
  int get hashCode => ppm.hashCode;

  @override
  String toString() => 'FxRate($ppm)';
}

final _million = BigInt.from(1000000);
final _ten = BigInt.from(10);

/// Converts [amount] into [to] at [rate], rounding half-even on the cent.
///
/// Throws [MoneyOverflow] if the result exceeds [Money.maxAbsCents].
Money convert(Money amount, Currency to, FxRate rate) {
  final numerator =
      BigInt.from(amount.cents).abs() *
      BigInt.from(rate.ppm) *
      _ten.pow(to.minorUnits);
  final denominator = _million * _ten.pow(amount.currency.minorUnits);
  var quotient = numerator ~/ denominator;
  final twiceRemainder = (numerator % denominator) * BigInt.two;
  final cmp = twiceRemainder.compareTo(denominator);
  if (cmp > 0 || (cmp == 0 && quotient.isOdd)) {
    quotient += BigInt.one;
  }
  final signed = amount.cents < 0 ? -quotient : quotient;
  if (signed.abs() > BigInt.from(Money.maxAbsCents)) {
    // Money's constructor rejects it; avoid int overflow from toInt().
    throw MoneyOverflow(
      signed.isNegative ? -Money.maxAbsCents - 1 : Money.maxAbsCents + 1,
    );
  }
  return Money(signed.toInt(), to);
}
