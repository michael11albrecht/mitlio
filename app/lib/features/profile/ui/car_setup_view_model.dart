import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Step ids of the car flow (PU-T08). Never rename after release.
abstract final class CarStep {
  static const hasCar = 'hasCar';
  static const name = 'name';
  static const fuel = 'fuel';
  static const consumption = 'consumption';
  static const extraCost = 'extraCost';
}

/// The two answers of the extra cost step.
abstract final class ExtraCostChoice {
  static const flat = 'flat';
  static const exact = 'exact';
}

/// The stored answer of the name step: the name and the body type.
Map<String, Object?> carNameAnswer(String name, CarType type) => {
  'name': name,
  'type': type.name,
};

({String name, CarType type})? _nameAnswer(Object? answer) {
  if (answer is! Map) return null;
  final name = answer['name'];
  if (name is! String || name.trim().isEmpty) return null;
  return (
    name: name.trim(),
    type: CarType.values.asNameMap()[answer['type']] ?? CarType.compact,
  );
}

String? _validName(Object answer) =>
    _nameAnswer(answer) == null ? 'name is blank' : null;

String? _validFuel(Object answer) =>
    FuelType.values.asNameMap()[answer] == null ? 'unknown fuel' : null;

String? _validConsumption(Object answer) =>
    answer is int && answer > 0 && answer <= 100000
    ? null
    : 'consumption must be above 0';

String? _validChoice(Object answer) =>
    answer == ExtraCostChoice.flat || answer == ExtraCostChoice.exact
    ? null
    : 'unknown choice';

/// The car flow. Everything but the question "Hast du ein Auto?" is needed
/// for a car to work, so nothing here can be skipped; the cost calculator is
/// its own flow ([carCostFlow]).
const carSetupFlow = SetupFlowConfig(
  id: 'car_setup',
  steps: [
    SetupStepSpec(CarStep.hasCar, skippable: false),
    SetupStepSpec(CarStep.name, skippable: false, validate: _validName),
    SetupStepSpec(CarStep.fuel, skippable: false, validate: _validFuel),
    SetupStepSpec(
      CarStep.consumption,
      skippable: false,
      validate: _validConsumption,
    ),
    SetupStepSpec(CarStep.extraCost, skippable: false, validate: _validChoice),
  ],
);

/// The flows DebugDrive can drive (`ext.mitlio.setup.*`).
const Map<String, SetupFlowConfig> carFlowConfigs = {
  'car_setup': carSetupFlow,
  'car_cost': carCostFlow,
};

/// Parts of the cost per km the result chart stacks.
enum CostPart {
  fuel,
  flat,
  insurance,
  vehicleTax,
  maintenance,
  tyres,
  repairs,
  loan,
  depreciation,
  parking,
  other;

  static CostPart of(CostCategory c) => switch (c) {
    CostCategory.insurance => insurance,
    CostCategory.vehicleTax => vehicleTax,
    CostCategory.maintenance => maintenance,
    CostCategory.tyres => tyres,
    CostCategory.repairs => repairs,
    CostCategory.loan => loan,
    CostCategory.depreciation => depreciation,
    CostCategory.parking => parking,
    CostCategory.other => other,
  };
}

/// One bar segment: a part and its tenths of a cent per km.
typedef CostSegment = ({CostPart part, int tenths});

/// The car as set up so far, and what it costs per km.
final class CarSetupSummary {
  const CarSetupSummary({
    required this.name,
    required this.type,
    required this.fuelType,
    required this.consumptionMilli,
    required this.exact,
    required this.wearMilli,
    required this.fuelTenths,
    required this.totalTenths,
    required this.segments,
    required this.check,
    this.cost,
  });

  final String name;
  final CarType type;
  final FuelType fuelType;
  final int consumptionMilli;

  /// Extra cost from the calculator ([cost]) instead of the flat default.
  final bool exact;
  final int wearMilli;

  /// Tenths of a cent per km: fuel, and fuel plus extra cost.
  final int fuelTenths;
  final int totalTenths;
  final List<CostSegment> segments;

  /// PBefG and typo hints (PU-T15); never block anything.
  final OperatingCostCheck check;
  final CarCostResult? cost;
}

/// Car flow answers read once; null while a required step is unanswered.
CarSetupSummary? evaluateCarSetup(
  Map<String, Object?> answers,
  CarCostResult? cost,
) {
  final named = _nameAnswer(answers[CarStep.name]);
  final fuel = FuelType.values.asNameMap()[answers[CarStep.fuel]];
  final consumption = answers[CarStep.consumption];
  if (named == null ||
      fuel == null ||
      consumption is! int ||
      _validConsumption(consumption) != null) {
    return null;
  }
  final exactCost = answers[CarStep.extraCost] == ExtraCostChoice.exact
      ? cost
      : null;
  final wear = exactCost?.chosen.wearMilliPerKm ?? flatWearMilliPerKm;
  final vehicle = Vehicle(
    id: 'preview',
    name: named.name,
    fuelType: fuel,
    consumptionMilliPer100km: consumption,
    wearMilliPerKm: wear,
  );
  final ride = referenceRideCost(vehicle);
  // 100 km: cents are hundredths of a cent per km; tenths round half up.
  int tenths(int cents) => (cents + 5) ~/ 10;
  return CarSetupSummary(
    name: named.name,
    type: named.type,
    fuelType: fuel,
    consumptionMilli: consumption,
    exact: exactCost != null,
    wearMilli: wear,
    fuelTenths: tenths(ride.fuelCents),
    totalTenths: tenths(ride.totalCents),
    segments: [
      (part: CostPart.fuel, tenths: tenths(ride.fuelCents)),
      if (exactCost == null)
        (part: CostPart.flat, tenths: tenths(ride.wearCents))
      else
        for (final MapEntry(:key, :value)
            in exactCost.chosen.breakdownMilliPerKm.entries)
          if (value > 0) (part: CostPart.of(key), tenths: value),
    ],
    check: referenceCheck(
      vehicle,
      runningWearMilliPerKm:
          exactCost?.running.wearMilliPerKm ?? flatWearMilliPerKm,
    ),
    cost: exactCost,
  );
}

/// The car as the flow answers describe it; null until the name, fuel and
/// consumption are given.
final carSetupSummaryProvider = Provider<CarSetupSummary?>(
  (ref) => evaluateCarSetup(
    ref.watch(setupFlowViewModelProvider(carSetupFlow)).answers,
    ref.watch(carCostResultProvider),
  ),
);

UserVehicleCostCategory _storedCategory(CostCategory c) => switch (c) {
  CostCategory.insurance => UserVehicleCostCategory.insurance,
  CostCategory.vehicleTax => UserVehicleCostCategory.tax,
  CostCategory.maintenance => UserVehicleCostCategory.maintenance,
  CostCategory.tyres => UserVehicleCostCategory.tyres,
  CostCategory.repairs => UserVehicleCostCategory.repairs,
  CostCategory.loan => UserVehicleCostCategory.loan,
  CostCategory.depreciation => UserVehicleCostCategory.depreciation,
  CostCategory.parking => UserVehicleCostCategory.parking,
  CostCategory.other => UserVehicleCostCategory.other,
};

/// Saves the car of the finished flow into "Meine Autos". The step flows
/// hold the answers; this is the one command the finish screen runs.
class CarSetupViewModel extends Notifier<bool> {
  /// True while [save] runs, so a double tap cannot add the car twice.
  @override
  bool build() => false;

  /// Stores the car (and its costs when the calculator was used), then
  /// clears both flows so "Noch ein Auto?" starts fresh. [Conflict] while
  /// the answers are incomplete.
  Future<RepoResult<Vehicle>> save() async {
    final summary = ref.read(carSetupSummaryProvider);
    if (summary == null) return const Err(Conflict('car setup is incomplete'));
    if (state) return const Err(Conflict('already saving'));
    state = true;
    try {
      final repo = ref.read(userVehiclesRepositoryProvider);
      final added = await repo.add(
        name: summary.name,
        fuelType: summary.fuelType,
        consumptionMilliPer100km: summary.consumptionMilli,
        wearMilliPerKm: summary.wearMilli,
      );
      if (added case Err(:final error)) return Err(error);
      final vehicle = (added as Ok<Vehicle, RepositoryError>).value;
      final cost = summary.cost;
      if (cost != null) {
        final saved = await repo.saveCosts(
          vehicle.id,
          UserVehicleCostDetails(
            annualKm: cost.annualKm,
            shareBasis: cost.basis == CostBasis.full
                ? UserVehicleShareBasis.full
                : UserVehicleShareBasis.running,
            annualCents: {
              for (final MapEntry(:key, :value) in cost.annualCents.entries)
                _storedCategory(key): value,
            },
          ),
        );
        if (saved case Err(:final error)) {
          // No car without the costs the user just entered: take it back.
          await repo.softDelete(vehicle.id);
          return Err(error);
        }
      }
      await _clearFlows();
      return Ok(vehicle);
    } finally {
      state = false;
    }
  }

  /// Back to the first step for both flows.
  Future<void> _clearFlows() async {
    final store = ref.read(setupStateRepositoryProvider);
    for (final flow in [carSetupFlow, carCostFlow]) {
      // Documented reason for ignoring a failure: the car is saved already;
      // old progress only means the next "Auto hinzufügen" resumes on a
      // finished flow, and reporting an error would suggest the car was lost.
      await store.save(flow.id, const SetupProgress());
      ref.invalidate(setupFlowViewModelProvider(flow));
    }
  }
}

final carSetupViewModelProvider = NotifierProvider<CarSetupViewModel, bool>(
  CarSetupViewModel.new,
);
