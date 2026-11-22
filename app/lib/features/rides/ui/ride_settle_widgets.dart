import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/features/rides/ui/ride_settlement.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Oktober" in the ambient language.
String monthName(BuildContext context, Month month) => DateFormat.MMMM(
  Localizations.localeOf(context).toString(),
).format(DateTime.utc(month.year, month.month));

/// "Oktober 2026" in the ambient language.
String monthYearName(BuildContext context, Month month) =>
    MaterialLocalizations.of(
      context,
    ).formatMonthYear(DateTime.utc(month.year, month.month));

/// The calm nudge at the end of a month: "Oktober abrechnen · 20 Fahrten".
/// One tap opens the preview; nothing is settled before that sheet's button.
class SettleCard extends StatelessWidget {
  const SettleCard({required this.plan, required this.onOpen, super.key});

  final SettlementPlan plan;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final title = l10n.ridesSettleCardTitle(
      monthName(context, plan.period),
      plan.rideCount,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonal(
                onPressed: onOpen,
                child: Text(l10n.ridesSettleCardAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One driver of a settlement: "Anna bekommt 46,80 € für 12 Fahrten", then
/// who owes what.
class SettleDriverBlock extends StatelessWidget {
  const SettleDriverBlock({
    required this.line,
    required this.driverId,
    required this.driverName,
    required this.state,
    required this.shares,
    super.key,
  });

  final String line;
  final String driverId;
  final String driverName;
  final RidesLoaded state;
  final List<RideShare> shares;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = MoneyFormat.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MemberAvatar(
                memberId: driverId,
                name: driverName,
                size: Sizes.avatarSmall,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(line, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          for (final share in shares)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: Sizes.avatarSmall + Spacing.sm,
                top: Spacing.xs,
              ),
              child: Text(
                l10n.ridesOwes(
                  state.member(share.memberId)?.name ?? '',
                  money.format(share.cents, state.group.currency),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Per person: km driven vs km ridden in the shown month and the net, plus
/// who is up next (the quick log's driver rule).
class FairnessSection extends StatefulWidget {
  const FairnessSection({required this.state, super.key});

  final RidesLoaded state;

  @override
  State<FairnessSection> createState() => _FairnessSectionState();
}

class _FairnessSectionState extends State<FairnessSection> {
  var _explaining = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    final next = state.member(state.nextDriverId ?? '');
    final rows = state.fairness;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Spacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.ridesFairnessTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (next != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Text(
                  l10n.ridesFairnessNext(next.name),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            Wrap(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: Text(l10n.ridesFairnessHow),
                  onPressed: () => setState(() => _explaining = !_explaining),
                ),
                TextButton(
                  onPressed: () => unawaited(
                    context.push('/groups/${state.group.id}/rides/settings'),
                  ),
                  child: Text(l10n.ridesFairnessChangeDrivers),
                ),
              ],
            ),
            if (_explaining)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Text(
                  l10n.ridesFairnessHowText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: Spacing.xs),
            for (final row in rows)
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  child: Row(
                    children: [
                      MemberAvatar(
                        memberId: row.memberId,
                        name: state.member(row.memberId)?.name ?? '',
                        size: Sizes.avatarSmall,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.member(row.memberId)?.name ?? '',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              l10n.ridesFairnessKm(
                                formatMilli(
                                  row.metersDriven,
                                  separator: separator,
                                ),
                                formatMilli(
                                  row.metersRidden,
                                  separator: separator,
                                ),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (!row.isDriverCandidate)
                              Text(
                                l10n.ridesFairnessNotDriving,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      MoneyText(
                        cents: row.netCents,
                        currency: state.group.currency,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: row.netCents < 0
                              ? theme.colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
