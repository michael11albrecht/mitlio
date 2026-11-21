import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/features/profile/ui/car_cost_chart.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart';
import 'package:mitlio/features/profile/ui/car_fields.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// The cost calculator (PU-T09): annual kilometres, one cost per screen, the
/// share basis, then the result with its chart. Pops with `true` when the
/// user takes the result over; leaving earlier keeps the progress.
class CarCostFlowView extends ConsumerWidget {
  const CarCostFlowView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    final result = ref.watch(carCostResultProvider);

    Widget? soFar() => result == null
        ? null
        : Text(
            l10n.carCostSoFar(
              formatTenths(result.chosenTenthsPerKm, separator),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          );

    Widget amount(
      SetupStepContext s,
      String title,
      IconData icon, {
      bool perPeriod = true,
    }) => CarAmountStep(
      step: s,
      title: title,
      visual: icon,
      perPeriod: perPeriod,
      result: soFar(),
    );

    return SetupFlowView(
      config: carCostFlow,
      stepBuilder: (context, s) => switch (s.step.id) {
        CarCostStep.annualKm => CarIntStep(
          step: s,
          title: l10n.carCostKmTitle,
          label: l10n.carCostKmLabel,
          invalidText: l10n.carCostKmInvalid,
          max: maxAnnualKm,
          visual: Icons.route_outlined,
          initial: 15000,
          presets: const [5000, 10000, 15000, 20000],
          presetLabel: (v) => l10n.carCostKmPreset(v ~/ 1000),
          sliderStep: 1000,
          result: soFar(),
        ),
        CarCostStep.insurance => amount(
          s,
          l10n.carCostInsuranceTitle,
          Icons.shield_outlined,
        ),
        CarCostStep.vehicleTax => amount(
          s,
          l10n.carCostTaxTitle,
          Icons.receipt_long_outlined,
        ),
        CarCostStep.maintenance => amount(
          s,
          l10n.carCostMaintenanceTitle,
          Icons.build_outlined,
        ),
        CarCostStep.tyres => amount(
          s,
          l10n.carCostTyresTitle,
          Icons.tire_repair_outlined,
        ),
        CarCostStep.repairs => amount(
          s,
          l10n.carCostRepairsTitle,
          Icons.car_repair_outlined,
        ),
        CarCostStep.loan => amount(
          s,
          l10n.carCostLoanTitle,
          Icons.account_balance_outlined,
        ),
        CarCostStep.depPurchase => amount(
          s,
          l10n.carCostPurchaseTitle,
          Icons.sell_outlined,
          perPeriod: false,
        ),
        CarCostStep.depResale => amount(
          s,
          l10n.carCostResaleTitle,
          Icons.trending_down,
          perPeriod: false,
        ),
        CarCostStep.depYears => CarIntStep(
          step: s,
          title: l10n.carCostYearsTitle,
          label: l10n.carCostYearsLabel,
          invalidText: l10n.carCostYearsInvalid,
          max: maxKeepYears,
          visual: Icons.event_outlined,
          initial: 5,
          result: soFar(),
        ),
        CarCostStep.parking => amount(
          s,
          l10n.carCostParkingTitle,
          Icons.local_parking_outlined,
        ),
        CarCostStep.other => amount(
          s,
          l10n.carCostOtherTitle,
          Icons.more_horiz,
        ),
        _ => _BasisStep(step: s),
      },
      finishBuilder: (context, back) => result == null
          ? const SizedBox.shrink()
          : FinishStep(
              title: l10n.carCostResultTitle(
                formatTenths(result.chosenTenthsPerKm, separator),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CarCostChart(
                    segments: [
                      for (final MapEntry(:key, :value)
                          in result.chosen.breakdownMilliPerKm.entries)
                        (part: CostPart.of(key), tenths: value),
                    ],
                  ),
                  ...carHints(l10n, result.check),
                ],
              ),
              actionLabel: l10n.carCostResultAccept,
              onAction: () => context.pop(true),
              onBack: back,
            ),
    );
  }
}

/// Running costs only (default, recommended) or all costs, each with its
/// ct/km, plus the PBefG note. One tap answers.
class _BasisStep extends ConsumerWidget {
  const _BasisStep({required this.step});

  final SetupStepContext step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    final result = ref.watch(carCostResultProvider);
    String ctKm(int? tenths) => formatTenths(tenths ?? 0, separator);
    final answer = step.answer;
    return StepScaffold(
      current: step.current,
      total: step.total,
      title: l10n.carCostBasisTitle,
      visual: const CarVisualSlot(Icons.balance_outlined),
      onBack: step.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarChoiceCard(
            label: l10n.carCostBasisRunning(ctKm(result?.runningTenthsPerKm)),
            hint: l10n.carCostBasisRunningHint,
            selected: answer == 'running',
            onTap: () => step.onNext('running'),
          ),
          const SizedBox(height: Spacing.sm),
          CarChoiceCard(
            label: l10n.carCostBasisFull(ctKm(result?.fullTenthsPerKm)),
            hint: l10n.carCostBasisFullHint,
            selected: answer == 'full',
            onTap: () => step.onNext('full'),
          ),
          const SizedBox(height: Spacing.md),
          CarHint(l10n.carHintOperatingCost),
        ],
      ),
    );
  }
}
