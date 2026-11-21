import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/core/ui/setup_flow/yes_no_step.dart';
import 'package:mitlio/features/profile/ui/car_cost_chart.dart';
import 'package:mitlio/features/profile/ui/car_fields.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio/features/rides/ui/milli_field.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart'
    show formatMilli;
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Hast du ein Auto?" to the finish screen (PU-T08, ADR-25 §4): name and
/// type, fuel, consumption, then a flat extra cost or the cost calculator
/// (`CarCostFlowView`, pushed by the last step). The finish screen shows what
/// a kilometre costs and saves the car into "Meine Autos".
class CarSetupView extends ConsumerWidget {
  const CarSetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    final summary = ref.watch(carSetupSummaryProvider);

    Future<bool> save() async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await ref.read(carSetupViewModelProvider.notifier).save();
      if (result case Err(:final error)) {
        showErrorSnackBar(messenger, l10n, error);
        return false;
      }
      return true;
    }

    return SetupFlowView(
      config: carSetupFlow,
      stepBuilder: (context, s) => switch (s.step.id) {
        CarStep.hasCar => YesNoStep(
          current: s.current,
          total: s.total,
          title: l10n.carHasCarTitle,
          visual: const CarVisualSlot(Icons.directions_car_outlined),
          selected: s.answer as bool?,
          // Nothing to set up without a car: leave.
          onAnswer: (yes) => yes ? s.onNext(true) : context.pop(),
          onBack: s.onBack,
        ),
        CarStep.name => _NameStep(step: s),
        CarStep.fuel => _FuelStep(step: s),
        CarStep.consumption => _ConsumptionStep(step: s),
        _ => _ExtraCostStep(step: s),
      },
      finishBuilder: (context, back) {
        if (summary == null) return const SizedBox.shrink();
        final unit = _unit(l10n, summary.fuelType);
        return FinishStep(
          title: l10n.carFinishTitle(
            formatTenths(summary.totalTenths, separator),
          ),
          summary: [
            l10n.carSummaryCar(summary.name, _fuelName(l10n, summary.fuelType)),
            l10n.carSummaryConsumption(
              formatMilli(summary.consumptionMilli, separator: separator),
              unit,
            ),
            if (summary.exact)
              l10n.carSummaryExtraExact(
                formatTenths(summary.wearMilli, separator),
              )
            else
              l10n.carSummaryExtraFlat(
                formatTenths(summary.wearMilli, separator),
              ),
          ],
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CarCostChart(segments: summary.segments),
              ...carHints(l10n, summary.check),
            ],
          ),
          actionLabel: l10n.carSave,
          onAction: () => unawaited(
            save().then((saved) {
              if (saved && context.mounted) context.pop();
            }),
          ),
          secondaryLabel: l10n.carsAnother,
          onSecondary: () => unawaited(save()),
          onBack: back,
        );
      },
    );
  }
}

String _fuelName(AppLocalizations l10n, FuelType fuel) => switch (fuel) {
  FuelType.petrol => l10n.carFuelPetrol,
  FuelType.diesel => l10n.carFuelDiesel,
  FuelType.electric => l10n.carFuelElectric,
  FuelType.other => l10n.carFuelOther,
};

String _unit(AppLocalizations l10n, FuelType fuel) =>
    fuel == FuelType.electric ? l10n.carUnitKwh : l10n.carUnitLitres;

String _typeName(AppLocalizations l10n, CarType type) => switch (type) {
  CarType.small => l10n.carTypeSmall,
  CarType.compact => l10n.carTypeCompact,
  CarType.suv => l10n.carTypeSuv,
  CarType.van => l10n.carTypeVan,
};

/// What a stored vehicle looks like in a list: "Benzin, 6,5 l/100 km".
String carRowSubtitle(
  AppLocalizations l10n,
  String separator,
  FuelType fuel,
  int consumptionMilli,
) => l10n.carRowSubtitle(
  _fuelName(l10n, fuel),
  '${formatMilli(consumptionMilli, separator: separator)} ${_unit(l10n, fuel)}',
);

/// Name and body type (two related values).
class _NameStep extends StatefulWidget {
  const _NameStep({required this.step});

  final SetupStepContext step;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  late final TextEditingController _name;
  late CarType _type;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    final answer = widget.step.answer;
    _name = TextEditingController(
      text: answer is Map ? '${answer['name'] ?? ''}' : '',
    );
    _type =
        (answer is Map ? CarType.values.asNameMap()[answer['type']] : null) ??
        CarType.compact;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _publish() => widget.step.onAnswer(
    _name.text.trim().isEmpty ? null : carNameAnswer(_name.text, _type),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StepScaffold(
      current: widget.step.current,
      total: widget.step.total,
      title: l10n.carNameTitle,
      visual: const CarVisualSlot(Icons.directions_car_outlined),
      onBack: widget.step.onBack,
      onNext: () {
        if (_name.text.trim().isEmpty) {
          setState(() => _showError = true);
        } else {
          widget.step.onNext(carNameAnswer(_name.text, _type));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.carNameLabel,
              errorText: _showError ? l10n.carNameRequired : null,
            ),
            onChanged: (_) {
              setState(() => _showError = false);
              _publish();
            },
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final type in CarType.values)
                ChoiceChip(
                  label: Text(_typeName(l10n, type)),
                  selected: type == _type,
                  onSelected: (_) {
                    setState(() => _type = type);
                    _publish();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fuel as an icon grid; one tap answers and moves on.
class _FuelStep extends StatelessWidget {
  const _FuelStep({required this.step});

  final SetupStepContext step;

  static const Map<FuelType, IconData> _icons = {
    FuelType.petrol: Icons.local_gas_station_outlined,
    FuelType.diesel: Icons.oil_barrel_outlined,
    FuelType.electric: Icons.bolt_outlined,
    FuelType.other: Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StepScaffold(
      current: step.current,
      total: step.total,
      title: l10n.carFuelTitle,
      visual: const CarVisualSlot(Icons.local_gas_station_outlined),
      onBack: step.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final fuel in FuelType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: CarChoiceCard(
                label: _fuelName(l10n, fuel),
                icon: _icons[fuel],
                selected: step.answer == fuel.name,
                onTap: () => step.onNext(fuel.name),
              ),
            ),
        ],
      ),
    );
  }
}

/// Consumption as a number field with a slider; "Weiß ich nicht" takes the
/// typical value for the body type and fuel.
class _ConsumptionStep extends ConsumerStatefulWidget {
  const _ConsumptionStep({required this.step});

  final SetupStepContext step;

  @override
  ConsumerState<_ConsumptionStep> createState() => _ConsumptionStepState();
}

class _ConsumptionStepState extends ConsumerState<_ConsumptionStep> {
  int? _milli;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _milli = widget.step.answer as int?;
  }

  void _set(int? milli) {
    setState(() {
      _milli = milli;
      _showError = false;
    });
    widget.step.onAnswer(milli);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    final answers = ref.watch(setupFlowViewModelProvider(carSetupFlow)).answers;
    final fuel =
        FuelType.values.asNameMap()[answers[CarStep.fuel]] ?? FuelType.petrol;
    final type = switch (answers[CarStep.name]) {
      final Map<String, Object?> m =>
        CarType.values.asNameMap()[m['type']] ?? CarType.compact,
      _ => CarType.compact,
    };
    final typical = typicalConsumptionMilli(type, fuel);
    final range = consumptionRangeMilli(fuel);
    final unit = _unit(l10n, fuel);
    final milli = _milli;
    final tooHigh = milli != null && milli > 30000;
    return StepScaffold(
      current: widget.step.current,
      total: widget.step.total,
      title: l10n.carConsumptionTitle,
      visual: const CarVisualSlot(Icons.speed_outlined),
      onBack: widget.step.onBack,
      result: tooHigh ? CarHint(l10n.carHintCheck) : null,
      onNext: () {
        final current = _milli;
        if (current == null || current <= 0) {
          setState(() => _showError = true);
        } else {
          widget.step.onNext(current);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MilliField(
            label: l10n.carConsumptionLabel,
            suffix: unit,
            milli: milli,
            autofocus: true,
            helper: l10n.carConsumptionTypical(
              formatMilli(typical, separator: separator),
              unit,
            ),
            errorText: _showError ? l10n.carConsumptionInvalid : null,
            onChanged: _set,
          ),
          Slider(
            value: (milli ?? typical).clamp(range.min, range.max).toDouble(),
            min: range.min.toDouble(),
            max: range.max.toDouble(),
            divisions: (range.max - range.min) ~/ 100,
            onChanged: (v) => _set((v.round() ~/ 100) * 100),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _set(typical),
              child: Text(l10n.carConsumptionDontKnow),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat default or the cost calculator, shown as two cards with their ct/km.
class _ExtraCostStep extends StatelessWidget {
  const _ExtraCostStep({required this.step});

  final SetupStepContext step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    return StepScaffold(
      current: step.current,
      total: step.total,
      title: l10n.carExtraTitle,
      visual: const CarVisualSlot(Icons.calculate_outlined),
      onBack: step.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarChoiceCard(
            label: l10n.carExtraFlat(
              formatTenths(flatWearMilliPerKm, separator),
            ),
            hint: l10n.carExtraFlatHint,
            selected: step.answer == ExtraCostChoice.flat,
            onTap: () => step.onNext(ExtraCostChoice.flat),
          ),
          const SizedBox(height: Spacing.sm),
          CarChoiceCard(
            label: l10n.carExtraExact,
            hint: l10n.carExtraExactHint,
            selected: step.answer == ExtraCostChoice.exact,
            onTap: () => unawaited(_calculate(context)),
          ),
        ],
      ),
    );
  }

  /// Opens the cost calculator; the choice only counts once its result was
  /// taken over (it pops with `true`).
  Future<void> _calculate(BuildContext context) async {
    final took = await context.push<bool>('/settings/cars/new/costs');
    if (took ?? false) step.onNext(ExtraCostChoice.exact);
  }
}
