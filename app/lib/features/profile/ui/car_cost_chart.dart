import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// One stacked bar of the cost per km, split by kind (fuel, flat rate or the
/// cost categories), with a legend row per segment. Colours come from the
/// theme; every row repeats its value in text, so colour is never the only
/// signal (a11y).
class CarCostChart extends StatelessWidget {
  const CarCostChart({required this.segments, super.key});

  final List<CostSegment> segments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    final shown = [
      for (final s in segments)
        if (s.tenths > 0) s,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();
    final colors = _colors(theme.colorScheme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.carChartLabel,
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: Radii.smAll,
              child: SizedBox(
                height: Sizes.stackedBar,
                child: Row(
                  children: [
                    for (final (i, s) in shown.indexed) ...[
                      if (i > 0)
                        SizedBox(
                          width: Spacing.xs / 2,
                          height: Sizes.stackedBar,
                          child: ColoredBox(color: theme.colorScheme.surface),
                        ),
                      Expanded(
                        flex: s.tenths,
                        // A ColoredBox without child collapses to nothing.
                        child: SizedBox.expand(
                          child: ColoredBox(color: colors[s.part]!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        for (final s in shown)
          Semantics(
            label: l10n.carPartValue(
              partLabel(l10n, s.part),
              formatTenths(s.tenths, separator),
            ),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Row(
                children: [
                  Container(
                    width: Sizes.legendDot,
                    height: Sizes.legendDot,
                    decoration: BoxDecoration(
                      color: colors[s.part],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: Text(partLabel(l10n, s.part))),
                  Text(
                    l10n.carPerKm(formatTenths(s.tenths, separator)),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A distinct theme colour per part; the fuel is always the primary colour.
Map<CostPart, Color> _colors(ColorScheme s) => {
  CostPart.fuel: s.primary,
  CostPart.flat: s.secondary,
  CostPart.insurance: s.tertiary,
  CostPart.vehicleTax: s.outline,
  CostPart.maintenance: s.primaryContainer,
  CostPart.tyres: s.secondaryContainer,
  CostPart.repairs: s.tertiaryContainer,
  CostPart.loan: s.inversePrimary,
  CostPart.depreciation: s.onSurfaceVariant,
  CostPart.parking: s.outlineVariant,
  CostPart.other: s.surfaceTint,
};

String partLabel(AppLocalizations l10n, CostPart part) => switch (part) {
  CostPart.fuel => l10n.carPartFuel,
  CostPart.flat => l10n.carPartFlat,
  CostPart.insurance => l10n.carPartInsurance,
  CostPart.vehicleTax => l10n.carPartVehicleTax,
  CostPart.maintenance => l10n.carPartMaintenance,
  CostPart.tyres => l10n.carPartTyres,
  CostPart.repairs => l10n.carPartRepairs,
  CostPart.loan => l10n.carPartLoan,
  CostPart.depreciation => l10n.carPartDepreciation,
  CostPart.parking => l10n.carPartParking,
  CostPart.other => l10n.carPartOther,
};
