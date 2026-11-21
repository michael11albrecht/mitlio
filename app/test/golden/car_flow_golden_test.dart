import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/features/profile/ui/car_cost_chart.dart';
import 'package:mitlio/features/profile/ui/car_fields.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';

import 'golden_matrix.dart';

final _de = AppLocalizationsDe();

/// The result chart of the car flow (PU-T08, PU-T09), light/dark x 1.0/2.0:
/// the cost calculator's categories, and the car's fuel plus flat rate.
Future<void> main() async {
  await matrixGolden(
    'car_cost_chart_categories',
    () => const Padding(
      padding: EdgeInsets.all(16),
      child: CarCostChart(
        segments: [
          (part: CostPart.maintenance, tenths: 32),
          (part: CostPart.tyres, tenths: 8),
          (part: CostPart.depreciation, tenths: 200),
          (part: CostPart.insurance, tenths: 40),
          (part: CostPart.vehicleTax, tenths: 13),
        ],
      ),
    ),
    width: 360,
    height: 520,
  );
  await matrixGolden(
    'car_cost_chart_fuel_flat',
    () => const Padding(
      padding: EdgeInsets.all(16),
      child: CarCostChart(
        segments: [
          (part: CostPart.fuel, tenths: 114),
          (part: CostPart.flat, tenths: 50),
        ],
      ),
    ),
    width: 360,
    height: 300,
  );
  await matrixGolden(
    'car_finish_result',
    () => FinishStep(
      title: _de.carFinishTitle('29,4'),
      summary: [
        _de.carSummaryCar('Golf', _de.carFuelPetrol),
        _de.carSummaryConsumption('6,5', _de.carUnitLitres),
        _de.carSummaryExtraExact('18,0'),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CarCostChart(
            segments: [
              (part: CostPart.fuel, tenths: 114),
              (part: CostPart.insurance, tenths: 120),
              (part: CostPart.maintenance, tenths: 60),
            ],
          ),
          const SizedBox(height: 16),
          CarHint(_de.carHintOperatingCost),
        ],
      ),
      actionLabel: _de.carSave,
      secondaryLabel: _de.carsAnother,
      onAction: () {},
      onSecondary: () {},
      onBack: () {},
    ),
    width: 360,
    height: 800,
  );
}
