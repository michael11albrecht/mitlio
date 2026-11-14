/// Why a decimal user input could not be converted to a domain unit.
enum ScaleFailure {
  /// Not finite, or too large to convert exactly.
  invalid,

  /// Below zero.
  negative,
}

/// Outcome of [scaleDecimal]: exactly one of [units] and [failure] is set.
final class Scaled {
  /// A converted value.
  const Scaled.ok(int this.units) : failure = null;

  /// A rejected value.
  const Scaled.failed(ScaleFailure this.failure) : units = null;

  /// The value in domain units, or null on [failure].
  final int? units;

  /// Why the conversion failed, or null on success.
  final ScaleFailure? failure;
}

/// Scale from km to metres (`distanceMeters`).
const kmToMeters = 1000;

/// Scale from a major unit to thousandths (consumption, price per unit,
/// wear, km rate).
const unitToMilli = 1000;

/// Scale from a major currency unit to cents (tolls, ferry), for currencies
/// with two minor-unit digits.
const eurToCents = 100;

/// Largest converted integer accepted; keeps every intermediate exact.
const maxScaledUnits = 1e12;

/// Boundary conversion of a decimal user input to the integer domain units of
/// docs/domain-rules.md "Trip cost": `value * scale` rounded half up.
///
/// Binary float noise is stripped first (`1.005 * 100` is
/// `100.49999999999999`, which must still round to 101). Negative values are
/// [ScaleFailure.negative]; NaN, infinities and results above
/// [maxScaledUnits] are [ScaleFailure.invalid].
Scaled scaleDecimal(num value, int scale) {
  if (value.isNaN || value.isInfinite) {
    return const Scaled.failed(ScaleFailure.invalid);
  }
  if (value < 0) return const Scaled.failed(ScaleFailure.negative);
  final scaled = value * scale;
  if (scaled > maxScaledUnits) {
    return const Scaled.failed(ScaleFailure.invalid);
  }
  return Scaled.ok(double.parse(scaled.toStringAsFixed(6)).round());
}
