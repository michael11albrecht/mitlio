// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/allocation/allocate.dart';
import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/money/currency.dart';
import 'package:mitlio_domain/src/money/money.dart';

/// A cost category of owning a car. See docs/domain-rules.md,
/// "Vehicle extra cost per km".
enum CostCategory {
  insurance(running: false),
  vehicleTax(running: false),
  maintenance(running: true),
  tyres(running: true),
  repairs(running: true),
  loan(running: false),
  depreciation(running: true),
  parking(running: false),
  other(running: false);

  const CostCategory({required this.running});

  /// Running costs depend on kilometres driven; fixed costs do not.
  final bool running;
}

/// Which categories count towards the extra cost per km.
enum CostBasis {
  /// Running categories only (default; PBefG operating costs).
  running,

  /// Running and fixed categories.
  full,
}

/// Whether a [CostEntry] amount is per month or per year.
enum CostPeriod { month, year }

/// One cost amount in minor units for a [CostPeriod].
final class CostEntry {
  const CostEntry(this.amountCents, this.period);

  final int amountCents;
  final CostPeriod period;

  @override
  bool operator ==(Object other) =>
      other is CostEntry &&
      other.amountCents == amountCents &&
      other.period == period;

  @override
  int get hashCode => Object.hash(amountCents, period);
}

/// Depreciation = (purchase - resale) / keepYears per year.
final class Depreciation {
  const Depreciation({
    required this.purchaseCents,
    required this.resaleCents,
    required this.keepYears,
  });

  final int purchaseCents;
  final int resaleCents;
  final int keepYears;

  @override
  bool operator ==(Object other) =>
      other is Depreciation &&
      other.purchaseCents == purchaseCents &&
      other.resaleCents == resaleCents &&
      other.keepYears == keepYears;

  @override
  int get hashCode => Object.hash(purchaseCents, resaleCents, keepYears);
}

/// What a user told us about the real costs of a car.
final class VehicleCostProfile {
  const VehicleCostProfile({
    required this.annualKm,
    required this.currency,
    this.costs = const {},
    this.depreciation,
  });

  /// Kilometres driven per year; must be > 0.
  final int annualKm;
  final Currency currency;

  /// Entered costs. A [CostCategory.depreciation] key is ignored; use
  /// [depreciation] instead.
  final Map<CostCategory, CostEntry> costs;

  /// Replaces a [CostCategory.depreciation] entry.
  final Depreciation? depreciation;
}

/// Why an extra cost per km could not be computed.
sealed class VehicleCostError {
  const VehicleCostError();
}

/// `annualKm` is zero or negative.
final class NonPositiveAnnualKm extends VehicleCostError {
  const NonPositiveAnnualKm();

  @override
  bool operator ==(Object other) => other is NonPositiveAnnualKm;

  @override
  int get hashCode => (NonPositiveAnnualKm).hashCode;

  @override
  String toString() => 'NonPositiveAnnualKm()';
}

/// A cost named [field] is negative.
final class VehicleCostNegativeValue extends VehicleCostError {
  const VehicleCostNegativeValue(this.field);

  final String field;

  @override
  bool operator ==(Object other) =>
      other is VehicleCostNegativeValue && other.field == field;

  @override
  int get hashCode => Object.hash(VehicleCostNegativeValue, field);

  @override
  String toString() => 'VehicleCostNegativeValue($field)';
}

/// `keepYears` is not positive or the resale value exceeds the purchase price.
final class InvalidDepreciation extends VehicleCostError {
  const InvalidDepreciation();

  @override
  bool operator ==(Object other) => other is InvalidDepreciation;

  @override
  int get hashCode => (InvalidDepreciation).hashCode;

  @override
  String toString() => 'InvalidDepreciation()';
}

/// The extra cost per km and where it comes from.
final class VehicleExtraCost {
  const VehicleExtraCost({
    required this.wearMilliPerKm,
    required this.breakdownMilliPerKm,
  });

  /// Thousandths of the major currency unit per km; feeds
  /// `Vehicle.wearMilliPerKm`.
  final int wearMilliPerKm;

  /// Share of [wearMilliPerKm] per counted category (all counted categories
  /// are present, also with 0); the values sum to [wearMilliPerKm].
  final Map<CostCategory, int> breakdownMilliPerKm;
}

// Round half up for non-negative numerator and positive denominator.
BigInt _roundHalfUp(BigInt n, BigInt d) =>
    (n * BigInt.two + d) ~/ (d * BigInt.two);

/// Turns [profile] into `wear_milli_per_km` for the given [basis].
///
/// Validation order (the first failure wins): [NonPositiveAnnualKm], negative
/// values ([VehicleCostNegativeValue], in [CostCategory] order, then
/// `depreciation`), [InvalidDepreciation].
///
/// Throws [MoneyOverflow] if the result exceeds [Money.maxAbsCents].
Result<VehicleExtraCost, VehicleCostError> vehicleExtraCostPerKm(
  VehicleCostProfile profile,
  CostBasis basis,
) {
  if (profile.annualKm <= 0) return const Err(NonPositiveAnnualKm());
  for (final c in CostCategory.values) {
    final e = profile.costs[c];
    if (c != CostCategory.depreciation && e != null && e.amountCents < 0) {
      return Err(VehicleCostNegativeValue(c.name));
    }
  }
  final dep = profile.depreciation;
  if (dep != null) {
    if (dep.purchaseCents < 0 || dep.resaleCents < 0) {
      return const Err(VehicleCostNegativeValue('depreciation'));
    }
    if (dep.keepYears <= 0 || dep.resaleCents > dep.purchaseCents) {
      return const Err(InvalidDepreciation());
    }
  }

  // Annual cost per counted category in minor units.
  final annual = <CostCategory, BigInt>{};
  for (final c in CostCategory.values) {
    if (basis == CostBasis.running && !c.running) continue;
    if (c == CostCategory.depreciation) {
      annual[c] = dep == null
          ? BigInt.zero
          : _roundHalfUp(
              BigInt.from(dep.purchaseCents - dep.resaleCents),
              BigInt.from(dep.keepYears),
            );
      continue;
    }
    final e = profile.costs[c];
    annual[c] = e == null
        ? BigInt.zero
        : BigInt.from(e.amountCents) *
              BigInt.from(e.period == CostPeriod.month ? 12 : 1);
  }

  final k = BigInt.from(10).pow(3 - profile.currency.minorUnits);
  final sum = annual.values.fold(BigInt.zero, (a, b) => a + b);
  final totalBig = _roundHalfUp(sum * k, BigInt.from(profile.annualKm));
  if (totalBig > BigInt.from(Money.maxAbsCents)) {
    throw const MoneyOverflow(Money.maxAbsCents + 1);
  }
  final total = totalBig.toInt();

  final cats = annual.keys.toList();
  final parts = sum == BigInt.zero
      ? List<int>.filled(cats.length, 0)
      : allocate(total, [for (final c in cats) annual[c]!.toInt()]);
  return Ok(
    VehicleExtraCost(
      wearMilliPerKm: total,
      breakdownMilliPerKm: Map.unmodifiable({
        for (var i = 0; i < cats.length; i++) cats[i]: parts[i],
      }),
    ),
  );
}
