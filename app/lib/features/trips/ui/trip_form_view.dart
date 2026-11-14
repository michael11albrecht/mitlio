import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/core/widgets/result_card.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The trip cost form ("private taxometer"): the result comes first and
/// updates with every keystroke; the form below only asks what is needed.
class TripFormView extends ConsumerStatefulWidget {
  const TripFormView({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<TripFormView> createState() => _TripFormViewState();
}

class _TripFormViewState extends ConsumerState<TripFormView> {
  final _distance = TextEditingController();
  final _consumption = TextEditingController();
  final _price = TextEditingController();
  final _wear = TextEditingController();
  final _kmRate = TextEditingController();
  final _tolls = TextEditingController();
  final _ferry = TextEditingController();
  final _title = TextEditingController();
  var _filled = false;

  TripFormViewModel get _vm =>
      ref.read(tripFormViewModelProvider(widget.groupId).notifier);

  @override
  void dispose() {
    for (final c in [
      _distance,
      _consumption,
      _price,
      _wear,
      _kmRate,
      _tolls,
      _ferry,
      _title,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills the fields once with what the ViewModel starts from (the last
  /// trip's vehicle values); later edits are the user's.
  void _fill(TripInputs inputs, String decimalSeparator) {
    if (_filled) return;
    _filled = true;
    String local(String s) => s.replaceAll('.', decimalSeparator);
    _distance.text = local(inputs.distance);
    _consumption.text = local(inputs.consumption);
    _price.text = local(inputs.price);
    _wear.text = local(inputs.wear);
    _kmRate.text = local(inputs.kmRate);
    _tolls.text = local(inputs.tolls);
    _ferry.text = local(inputs.ferry);
    _title.text = inputs.title;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _vm.save(fallbackTitle: l10n.tripDefaultTitle);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: l10n.tripSaved,
          undo: value.undo,
        );
        context.pop();
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  Future<void> _share(MoneyFormat format, TripFormLoaded s) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final currency = s.group.currency;
    final result = await _vm.shareResult(
      (cents) => l10n.tripShareText(format.format(cents, currency)),
    );
    if (!mounted) return;
    if (result is Err) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(tripFormViewModelProvider(widget.groupId));
    return switch (state) {
      TripFormLoading() => Scaffold(
        appBar: AppBar(title: Text(l10n.tripFormTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      TripFormFailure() => Scaffold(
        appBar: AppBar(title: Text(l10n.tripFormTitle)),
        body: ErrorState(onRetry: _vm.retry),
      ),
      TripFormLoaded(:final members) when members.isEmpty => Scaffold(
        appBar: AppBar(title: Text(l10n.tripFormTitle)),
        body: EmptyState(
          icon: Icons.person_add_alt_outlined,
          title: l10n.membersEmptyTitle,
          message: l10n.membersEmptyMessage,
          action: FilledButton(
            onPressed: context.pop,
            child: Text(l10n.expensesNoMembersAction),
          ),
        ),
      ),
      TripFormLoaded() => _form(context, state),
    };
  }

  Widget _form(BuildContext context, TripFormLoaded s) {
    final l10n = AppLocalizations.of(context);
    final format = MoneyFormat.of(context);
    _fill(s.inputs, format.decimalSeparator);
    final symbol = format.currencySymbol(s.group.currency);
    final inputs = s.inputs;
    final invalid = s.evaluation.invalid;
    final electric = inputs.energy == TripEnergy.electric;
    final vm = _vm;
    final standalone = vm.isStandalone;
    String nameOf(GroupMember m) => tripMemberName(l10n, standalone, m);

    Widget gap() => const SizedBox(height: Spacing.md);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.tripFormTitle,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: Spacing.screen,
              children: [
                _ResultArea(state: s, nameOf: nameOf),
                gap(),
                _NumberField(
                  controller: _distance,
                  label: l10n.tripDistanceLabel,
                  suffix: l10n.tripUnitKm,
                  error: invalid.contains(TripField.distance),
                  onChanged: vm.setDistance,
                  autofocus: true,
                  large: true,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tripRoundTrip),
                  value: inputs.roundTrip,
                  onChanged: (v) => vm.setRoundTrip(value: v),
                ),
                gap(),
                label(l10n.tripDriverLabel),
                Wrap(
                  spacing: Spacing.sm,
                  children: [
                    for (final m in s.members)
                      ChoiceChip(
                        avatar: MemberAvatar(
                          memberId: m.id,
                          name: nameOf(m),
                          size: Sizes.avatarSmall,
                        ),
                        label: Text(nameOf(m)),
                        selected: m.id == inputs.driverId,
                        showCheckmark: false,
                        onSelected: (_) => vm.setDriver(m.id),
                      ),
                  ],
                ),
                gap(),
                label(l10n.tripPassengersLabel),
                Wrap(
                  spacing: Spacing.sm,
                  children: [
                    for (final m in s.members)
                      if (m.id != inputs.driverId)
                        FilterChip(
                          avatar: MemberAvatar(
                            memberId: m.id,
                            name: nameOf(m),
                            size: Sizes.avatarSmall,
                          ),
                          label: Text(nameOf(m)),
                          selected: inputs.passengerIds.contains(m.id),
                          onSelected: (_) => vm.togglePassenger(m.id),
                        ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tripDriverPays),
                  value: inputs.driverCounts,
                  onChanged: (v) => vm.setDriverCounts(value: v),
                ),
                gap(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tripKmRateToggle),
                  subtitle: Text(l10n.tripKmRateHint),
                  value: inputs.useKmRate,
                  onChanged: (v) => vm.setUseKmRate(value: v),
                ),
                gap(),
                if (inputs.useKmRate)
                  _NumberField(
                    controller: _kmRate,
                    label: l10n.tripKmRateLabel,
                    suffix: l10n.tripUnitPerKm(symbol),
                    error: invalid.contains(TripField.kmRate),
                    onChanged: vm.setKmRate,
                  )
                else ...[
                  SegmentedButton<TripEnergy>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: TripEnergy.fuel,
                        label: Text(l10n.tripEnergyFuel),
                      ),
                      ButtonSegment(
                        value: TripEnergy.electric,
                        label: Text(l10n.tripEnergyElectric),
                      ),
                    ],
                    selected: {inputs.energy},
                    onSelectionChanged: (v) => vm.setEnergy(v.first),
                  ),
                  gap(),
                  _NumberField(
                    controller: _consumption,
                    label: l10n.tripConsumptionLabel,
                    suffix: electric
                        ? l10n.tripUnitKwhPer100
                        : l10n.tripUnitLitersPer100,
                    error: invalid.contains(TripField.consumption),
                    onChanged: vm.setConsumption,
                  ),
                  gap(),
                  _NumberField(
                    controller: _price,
                    label: electric
                        ? l10n.tripPriceElectricLabel
                        : l10n.tripPriceFuelLabel,
                    suffix: electric
                        ? l10n.tripUnitPerKwh(symbol)
                        : l10n.tripUnitPerLiter(symbol),
                    error: invalid.contains(TripField.price),
                    onChanged: vm.setPrice,
                  ),
                  gap(),
                  _NumberField(
                    controller: _wear,
                    label: l10n.tripWearLabel,
                    suffix: l10n.tripUnitPerKm(symbol),
                    error: invalid.contains(TripField.wear),
                    onChanged: vm.setWear,
                  ),
                ],
                gap(),
                _NumberField(
                  controller: _tolls,
                  label: l10n.tripTollsLabel,
                  suffix: symbol,
                  error: invalid.contains(TripField.tolls),
                  onChanged: vm.setTolls,
                ),
                gap(),
                _NumberField(
                  controller: _ferry,
                  label: l10n.tripFerryLabel,
                  suffix: symbol,
                  error: invalid.contains(TripField.ferry),
                  onChanged: vm.setFerry,
                ),
                if (!standalone) ...[
                  gap(),
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: vm.setTitle,
                    decoration: InputDecoration(labelText: l10n.tripTitleLabel),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: Spacing.screen,
              child: SizedBox(
                width: double.infinity,
                child: standalone
                    ? FilledButton.icon(
                        onPressed: s.evaluation.cost == null
                            ? null
                            : () => unawaited(_share(format, s)),
                        icon: const Icon(Icons.ios_share),
                        label: Text(l10n.tripShare),
                      )
                    : FilledButton(
                        onPressed: s.canSave ? () => unawaited(_save()) : null,
                        child: Text(l10n.tripSave),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.error,
    required this.onChanged,
    this.autofocus = false,
    this.large = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool error;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
      ],
      style: MitlioTypography.tabular(
        large ? Theme.of(context).textTheme.headlineMedium : null,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        errorText: error ? l10n.tripNumberInvalid : null,
      ),
    );
  }
}

/// The answer: "Jede Person zahlt X" and what the driver gets, with the
/// breakdown folded away; or one calm line telling what is still missing.
class _ResultArea extends StatelessWidget {
  const _ResultArea({required this.state, required this.nameOf});

  final TripFormLoaded state;
  final String Function(GroupMember) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final eval = state.evaluation;
    final cost = eval.cost;
    final currency = state.group.currency;
    if (cost == null) {
      final message = switch (eval.blocker) {
        TripBlocker.noParticipants => l10n.tripNoParticipants,
        TripBlocker.tooLarge => l10n.tripTooLarge,
        _ => state.inputs.useKmRate ? l10n.tripHintKmRate : l10n.tripHintFuel,
      };
      return Card(
        child: Padding(
          padding: Spacing.allLg,
          child: SizedBox(
            width: double.infinity,
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final format = MoneyFormat.of(context);
    final driver = state.members.firstWhere(
      (m) => m.id == eval.input!.driverId,
    );
    return Column(
      children: [
        ResultCard(
          caption: eval.sharesEqual
              ? l10n.tripResultCaption
              : l10n.tripResultCaptionRounded,
          cents: eval.perPersonCents!,
          currency: currency,
          detail: l10n.tripResultDriverGets(
            nameOf(driver),
            format.format(eval.driverGetsCents!, currency),
          ),
        ),
        _Breakdown(state: state, nameOf: nameOf),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.state, required this.nameOf});

  final TripFormLoaded state;
  final String Function(GroupMember) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cost = state.evaluation.cost!;
    final currency = state.group.currency;
    final electric = state.inputs.energy == TripEnergy.electric;
    final lines = <(String, int)>[
      if (cost.fuelCents > 0)
        (
          electric ? l10n.tripBreakdownElectric : l10n.tripBreakdownFuel,
          cost.fuelCents,
        ),
      if (cost.wearCents > 0) (l10n.tripBreakdownWear, cost.wearCents),
      if (cost.kmRateCents > 0) (l10n.tripBreakdownKmRate, cost.kmRateCents),
      if (cost.tollsCents > 0) (l10n.tripBreakdownTolls, cost.tollsCents),
      if (cost.ferryCents > 0) (l10n.tripBreakdownFerry, cost.ferryCents),
    ];
    final shares = state.evaluation.participantShares!;
    final names = {for (final m in state.members) m.id: nameOf(m)};
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l10n.tripBreakdown),
        children: [
          for (final (name, cents) in lines)
            _line(context, name, cents, currency),
          _line(
            context,
            l10n.tripBreakdownTotal,
            cost.totalCents,
            currency,
            bold: true,
          ),
          const SizedBox(height: Spacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.tripBreakdownPerPerson,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final e in shares.entries)
            _line(context, names[e.key] ?? '', e.value, currency),
          const SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String name,
    int cents,
    Currency currency, {
    bool bold = false,
  }) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(name, style: style)),
          MoneyText(cents: cents, currency: currency, style: style),
        ],
      ),
    );
  }
}

/// Seats of the trip form without a group have no name; they are "Person 1".
String tripMemberName(
  AppLocalizations l10n,
  bool standalone,
  GroupMember member,
) => standalone ? l10n.tripSeatName(member.position + 1) : member.name;
