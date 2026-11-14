import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/rides/ui/milli_field.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Maria zahlt 2,34 €, Ben zahlt 2,34 €" (or the calm "no passengers" line).
String owesText(
  BuildContext context,
  List<({String name, int cents})> owes,
  Currency currency,
) {
  final l10n = AppLocalizations.of(context);
  if (owes.isEmpty) return l10n.ridesNobodyOwes;
  final money = MoneyFormat.of(context);
  return owes
      .map((o) => l10n.ridesOwes(o.name, money.format(o.cents, currency)))
      .join(', ');
}

/// "20 km" or "2 × 20 km" for [meters] one way.
String distanceText(
  BuildContext context,
  int meters, {
  required bool roundTrip,
}) {
  final l10n = AppLocalizations.of(context);
  final km = formatMilli(
    meters,
    separator: MoneyFormat.of(context).decimalSeparator,
  );
  return roundTrip
      ? l10n.ridesDistanceRoundTrip(km)
      : l10n.ridesDistanceOneWay(km);
}

/// The headline feature: "Heute gefahren". One card at the top of the rides
/// tab with everything pre-set (the only template, the fair driver, the
/// template's passengers, the frozen fuel price), so a ride is one save tap;
/// with several templates it is a pick plus the save. The result shows in
/// the undo snackbar.
class QuickLogCard extends StatefulWidget {
  const QuickLogCard({
    required this.groupId,
    required this.state,
    required this.vm,
    super.key,
  });

  final String groupId;
  final RidesLoaded state;
  final RidesViewModel vm;

  @override
  State<QuickLogCard> createState() => _QuickLogCardState();
}

class _QuickLogCardState extends State<QuickLogCard> {
  var _editingPrice = false;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await widget.vm.saveQuickLog();
    if (!mounted) return;
    setState(() => _editingPrice = false);
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: l10n.ridesSaved(
            owesText(context, value.owes, value.currency),
          ),
          undo: value.undo,
        );
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final quick = widget.state.quick!;
    final title = quick.isToday
        ? l10n.quickLogTitleToday
        : l10n.quickLogTitleDate(
            MaterialLocalizations.of(context).formatMediumDate(quick.date),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.md,
          Spacing.sm,
          Spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.directions_car_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                ),
                IconButton(
                  tooltip: l10n.ridesSettings,
                  icon: const Icon(Icons.tune),
                  onPressed: () => unawaited(
                    context.push('/groups/${widget.groupId}/rides/settings'),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: Spacing.md),
              child: quick.collapsed ? _done(context) : _form(context, quick),
            ),
          ],
        ),
      ),
    );
  }

  String _price(int milli, Currency currency) {
    final money = MoneyFormat.of(context);
    final number = formatPriceMilli(milli, separator: money.decimalSeparator);
    return '$number ${money.currencySymbol(currency)}';
  }

  Widget _done(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final today = widget.state
        .entriesOn(widget.state.today)
        .map((e) => widget.state.member(e.ride.driverId)?.name ?? '')
        .toList();
    return Row(
      children: [
        ExcludeSemantics(
          child: Icon(Icons.check_circle, color: scheme.primary),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(child: Text(l10n.quickLogDone(today.join(', ')))),
        TextButton(
          onPressed: widget.vm.expand,
          child: Text(l10n.quickLogAnother),
        ),
      ],
    );
  }

  Widget _form(BuildContext context, QuickLog quick) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = widget.state;
    final vm = widget.vm;
    final template = quick.template;
    final money = MoneyFormat.of(context);
    final driver = quick.driverId;
    final unit = quick.vehicle?.fuelType == FuelType.electric
        ? l10n.ridesUnitKwh
        : l10n.ridesUnitLitre;
    final owes = [
      for (final s in quick.preview?.owes ?? const <RideShare>[])
        (name: state.member(s.memberId)?.name ?? '', cents: s.cents),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!quick.isToday)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => vm.setDate(null),
              child: Text(l10n.quickLogBackToToday),
            ),
          ),
        if (state.templates.length > 1) ...[
          if (template == null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Text(
                l10n.quickLogPickRoute,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final t in state.templates)
                ChoiceChip(
                  label: Text(t.name),
                  selected: template?.id == t.id,
                  onSelected: (_) => vm.selectTemplate(t.id),
                ),
            ],
          ),
        ] else if (template != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Text(
              l10n.ridesRouteLine(
                template.name,
                distanceText(
                  context,
                  template.distanceMeters,
                  roundTrip: template.roundTrip,
                ),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (template != null && driver != null) ...[
          _Label(l10n.quickLogDriver),
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final m in state.members)
                ChoiceChip(
                  avatar: ExcludeSemantics(
                    child: MemberAvatar(
                      memberId: m.id,
                      name: m.name,
                      size: Sizes.avatarSmall,
                    ),
                  ),
                  label: Text(m.name),
                  selected: driver == m.id,
                  onSelected: (_) => vm.selectDriver(m.id),
                ),
            ],
          ),
          if (state.members.length > 1) ...[
            _Label(l10n.quickLogPassengers),
            Wrap(
              spacing: Spacing.sm,
              children: [
                for (final m in state.members)
                  if (m.id != driver)
                    FilterChip(
                      avatar: ExcludeSemantics(
                        child: MemberAvatar(
                          memberId: m.id,
                          name: m.name,
                          size: Sizes.avatarSmall,
                        ),
                      ),
                      label: Text(m.name),
                      selected: quick.passengerIds.contains(m.id),
                      onSelected: (_) => vm.togglePassenger(m.id),
                    ),
              ],
            ),
          ],
          if (!quick.usesKmRate) ...[
            const SizedBox(height: Spacing.sm),
            if (_editingPrice)
              MilliField(
                label: l10n.quickLogPriceLabel(unit),
                suffix: money.currencySymbol(state.group.currency),
                milli: quick.priceMilli,
                autofocus: true,
                onChanged: (milli) {
                  if (milli != null) vm.setPrice(milli);
                },
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ActionChip(
                  avatar: const Icon(Icons.local_gas_station_outlined),
                  label: Text(
                    l10n.quickLogPrice(
                      _price(quick.priceMilli, state.group.currency),
                      unit,
                    ),
                  ),
                  onPressed: () => setState(() => _editingPrice = true),
                ),
              ),
          ],
          const SizedBox(height: Spacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              owesText(context, owes, state.group.currency),
              style: MitlioTypography.tabular(theme.textTheme.titleMedium),
            ),
          ),
        ],
        const SizedBox(height: Spacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: quick.canSave ? () => unawaited(_save()) : null,
            child: Text(l10n.quickLogSave),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.xs),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
