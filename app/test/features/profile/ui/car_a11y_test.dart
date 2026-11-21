import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/features/profile/ui/car_cost_flow_view.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio/features/profile/ui/car_setup_view.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio/features/profile/ui/my_cars_view.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/a11y.dart';
import 'car_flow_support.dart';

/// Contrast, labelled and large-enough tap targets of the car screens, in
/// light/dark and at text scale 1.0 and 2.0 (plan §2.6). Each screen is
/// opened by saving the flow's progress, as a restart would.
void main() {
  final carAnswers = <String, Object?>{
    CarStep.hasCar: true,
    CarStep.name: carNameAnswer('Golf', CarType.compact),
    CarStep.fuel: 'petrol',
    CarStep.consumption: 6500,
    CarStep.extraCost: ExtraCostChoice.flat,
  };
  final costAnswers = <String, Object?>{
    CarCostStep.annualKm: 15000,
    CarCostStep.insurance: costEntryAnswer(60000, CostPeriod.year),
    CarCostStep.vehicleTax: costEntryAnswer(20000, CostPeriod.year),
    CarCostStep.maintenance: costEntryAnswer(4000, CostPeriod.month),
    CarCostStep.depPurchase: 3000000,
    CarCostStep.depResale: 1500000,
    CarCostStep.depYears: 5,
    CarCostStep.basis: 'full',
  };

  Widget scoped(
    Widget view, {
    SetupFlowConfig? flow,
    int stepIndex = 0,
    Map<String, Object?> answers = const {},
    bool finished = false,
    void Function(CarFlowFakes fakes)? seed,
  }) {
    final fakes = CarFlowFakes();
    if (flow != null) {
      fakes.setup.stored[flow.id] = SetupProgress(
        stepIndex: stepIndex,
        answers: answers,
        finished: finished,
      ).toJson();
      // The car flow's result also reads the calculator's answers.
      fakes.setup.stored[carCostFlow.id] = SetupProgress(
        stepIndex: 12,
        answers: costAnswers,
        finished: true,
      ).toJson();
    }
    seed?.call(fakes);
    return ProviderScope(overrides: fakes.overrides, child: view);
  }

  for (final (name, step) in [
    ('hasCar', 0),
    ('name', 1),
    ('fuel', 2),
    ('consumption', 3),
    ('extraCost', 4),
  ]) {
    forEachMode(
      'car flow: $name',
      () => scoped(
        const CarSetupView(),
        flow: carSetupFlow,
        stepIndex: step,
        answers: carAnswers,
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }

  for (final exact in [false, true]) {
    forEachMode(
      'car flow: result with ${exact ? 'own costs' : 'the flat rate'}',
      () => scoped(
        const CarSetupView(),
        flow: carSetupFlow,
        stepIndex: 4,
        finished: true,
        answers: {
          ...carAnswers,
          CarStep.extraCost: exact
              ? ExtraCostChoice.exact
              : ExtraCostChoice.flat,
        },
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }

  for (final (name, step) in [
    ('annual km', 0),
    ('insurance', 1),
    ('depreciation years', 9),
    ('basis', 12),
  ]) {
    forEachMode(
      'cost calculator: $name',
      () => scoped(
        const CarCostFlowView(),
        flow: carCostFlow,
        stepIndex: step,
        answers: costAnswers,
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }

  forEachMode(
    'cost calculator: result',
    () => scoped(
      const CarCostFlowView(),
      flow: carCostFlow,
      stepIndex: 12,
      finished: true,
      answers: costAnswers,
    ),
    (tester, _, _) => expectAccessible(tester),
  );

  forEachMode(
    'my cars: empty',
    () => scoped(const MyCarsView()),
    (tester, _, _) => expectAccessible(tester),
  );

  forEachMode(
    'my cars: with a car',
    () => scoped(
      const MyCarsView(),
      seed: (fakes) => fakes.cars.add(
        name: 'Golf',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: 6500,
      ),
    ),
    (tester, _, _) => expectAccessible(tester),
  );
}
