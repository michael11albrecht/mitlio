import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Step ids of the cost calculator, in order (PU-T09, ADR-25 §3). Never
/// rename after release: they are the keys of the stored answers.
abstract final class CarCostStep {
  static const annualKm = 'annualKm';
  static const insurance = 'insurance';
  static const vehicleTax = 'vehicleTax';
  static const maintenance = 'maintenance';
  static const tyres = 'tyres';
  static const repairs = 'repairs';
  static const loan = 'loan';
  static const depPurchase = 'depPurchase';
  static const depResale = 'depResale';
  static const depYears = 'depYears';
  static const parking = 'parking';
  static const other = 'other';
  static const basis = 'basis';
}

/// Category steps that take an amount per month or per year.
const costCategorySteps = <String, CostCategory>{
  CarCostStep.insurance: CostCategory.insurance,
  CarCostStep.vehicleTax: CostCategory.vehicleTax,
  CarCostStep.maintenance: CostCategory.maintenance,
  CarCostStep.tyres: CostCategory.tyres,
  CarCostStep.repairs: CostCategory.repairs,
  CarCostStep.loan: CostCategory.loan,
  CarCostStep.parking: CostCategory.parking,
  CarCostStep.other: CostCategory.other,
};

/// Largest amount a single field takes: 1 000 000 in the major unit, far
/// above any car cost, and keeps every sum far from the money limit.
const maxCostCents = 100000000;
const maxAnnualKm = 1000000;
const maxKeepYears = 50;

/// The stored answer of a category step.
Map<String, Object?> costEntryAnswer(int cents, CostPeriod period) => {
  'cents': cents,
  'period': period.name,
};

CostEntry? _entry(Object? answer) {
  if (answer is! Map) return null;
  final cents = answer['cents'];
  final period = CostPeriod.values.asNameMap()[answer['period']];
  if (cents is! int || cents < 0 || cents > maxCostCents || period == null) {
    return null;
  }
  return CostEntry(cents, period);
}

String? _validEntry(Object answer) =>
    _entry(answer) == null ? 'not an amount with a period' : null;

String? _validKm(Object answer) =>
    answer is int && answer > 0 && answer <= maxAnnualKm
    ? null
    : 'annual km must be 1 to $maxAnnualKm';

String? _validCents(Object answer) =>
    answer is int && answer >= 0 && answer <= maxCostCents
    ? null
    : 'not an amount';

String? _validYears(Object answer) =>
    answer is int && answer > 0 && answer <= maxKeepYears
    ? null
    : 'years must be 1 to $maxKeepYears';

String? _validBasis(Object answer) =>
    answer == 'running' || answer == 'full' ? null : 'unknown basis';

/// The cost calculator as a setup flow. Only the annual kilometres are
/// required; every cost is skipped by "Überspringen".
const carCostFlow = SetupFlowConfig(
  id: 'car_cost',
  steps: [
    SetupStepSpec(
      CarCostStep.annualKm,
      skippable: false,
      validate: _validKm,
    ),
    SetupStepSpec(CarCostStep.insurance, validate: _validEntry),
    SetupStepSpec(CarCostStep.vehicleTax, validate: _validEntry),
    SetupStepSpec(CarCostStep.maintenance, validate: _validEntry),
    SetupStepSpec(CarCostStep.tyres, validate: _validEntry),
    SetupStepSpec(CarCostStep.repairs, validate: _validEntry),
    SetupStepSpec(CarCostStep.loan, validate: _validEntry),
    SetupStepSpec(CarCostStep.depPurchase, validate: _validCents),
    SetupStepSpec(CarCostStep.depResale, validate: _validCents),
    SetupStepSpec(CarCostStep.depYears, validate: _validYears),
    SetupStepSpec(CarCostStep.parking, validate: _validEntry),
    SetupStepSpec(CarCostStep.other, validate: _validEntry),
    SetupStepSpec(CarCostStep.basis, skippable: false, validate: _validBasis),
  ],
);

/// What the cost calculator amounts to: the extra cost per km for both bases
/// and the yearly amounts to store.
final class CarCostResult {
  const CarCostResult({
    required this.annualKm,
    required this.basis,
    required this.running,
    required this.full,
    required this.annualCents,
    required this.check,
  });

  final int annualKm;

  /// The chosen basis; running costs only unless the user picked full.
  final CostBasis basis;
  final VehicleExtraCost running;
  final VehicleExtraCost full;

  /// Yearly cents per answered category (depreciation included).
  final Map<CostCategory, int> annualCents;

  /// PBefG hint for the chosen basis on a typical car (PU-T15).
  final OperatingCostCheck check;

  VehicleExtraCost get chosen => basis == CostBasis.full ? full : running;

  /// Tenths of a cent per km are the same number as thousandths of a euro.
  int get chosenTenthsPerKm => chosen.wearMilliPerKm;
  int get runningTenthsPerKm => running.wearMilliPerKm;
  int get fullTenthsPerKm => full.wearMilliPerKm;
}

// Round half up for non-negative numerator and positive denominator.
int _roundHalfUp(int n, int d) => (n * 2 + d) ~/ (d * 2);

/// The result of [answers] of [carCostFlow]; null while the annual
/// kilometres are missing. Skipped or invalid steps count as no cost.
CarCostResult? evaluateCarCost(Map<String, Object?> answers) {
  final km = answers[CarCostStep.annualKm];
  if (km is! int || _validKm(km) != null) return null;

  final costs = <CostCategory, CostEntry>{};
  for (final MapEntry(:key, :value) in costCategorySteps.entries) {
    final entry = _entry(answers[key]);
    if (entry != null) costs[value] = entry;
  }
  final purchase = answers[CarCostStep.depPurchase];
  final resale = answers[CarCostStep.depResale];
  final years = answers[CarCostStep.depYears];
  Depreciation? depreciation;
  if (purchase is int &&
      years is int &&
      _validCents(purchase) == null &&
      _validYears(years) == null) {
    final resaleCents = resale is int && _validCents(resale) == null
        ? resale
        : 0;
    depreciation = Depreciation(
      purchaseCents: purchase,
      // A resale value above the price is not depreciation.
      resaleCents: resaleCents > purchase ? purchase : resaleCents,
      keepYears: years,
    );
  }

  final profile = VehicleCostProfile(
    annualKm: km,
    currency: carCurrency,
    costs: costs,
    depreciation: depreciation,
  );
  // The profile is valid by construction, so both are Ok.
  final running = vehicleExtraCostPerKm(profile, CostBasis.running);
  final full = vehicleExtraCostPerKm(profile, CostBasis.full);
  if (running is! Ok<VehicleExtraCost, VehicleCostError> ||
      full is! Ok<VehicleExtraCost, VehicleCostError>) {
    return null;
  }

  final basis = answers[CarCostStep.basis] == 'full'
      ? CostBasis.full
      : CostBasis.running;
  final chosen = basis == CostBasis.full ? full.value : running.value;
  return CarCostResult(
    annualKm: km,
    basis: basis,
    check: referenceCheck(
      Vehicle(
        id: 'preview',
        name: 'preview',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: typicalConsumptionMilli(
          CarType.compact,
          FuelType.petrol,
        ),
        wearMilliPerKm: chosen.wearMilliPerKm,
      ),
      runningWearMilliPerKm: running.value.wearMilliPerKm,
    ),
    running: running.value,
    full: full.value,
    annualCents: {
      for (final MapEntry(:key, :value) in costs.entries)
        key: value.amountCents * (value.period == CostPeriod.month ? 12 : 1),
      if (depreciation != null)
        CostCategory.depreciation: _roundHalfUp(
          depreciation.purchaseCents - depreciation.resaleCents,
          depreciation.keepYears,
        ),
    },
  );
}

/// The cost calculator's live result, read from the flow's answers; null
/// until the annual kilometres are given. Recomputed with every keystroke.
final carCostResultProvider = Provider<CarCostResult?>(
  (ref) => evaluateCarCost(
    ref.watch(setupFlowViewModelProvider(carCostFlow)).answers,
  ),
);
