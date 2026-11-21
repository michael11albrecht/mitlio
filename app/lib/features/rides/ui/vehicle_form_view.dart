import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/rides/ui/milli_field.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';
import 'package:mitlio/features/rides/ui/vehicle_link_note.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Add a vehicle to [groupId], or with [vehicleId] edit the stored one.
/// Name, fuel and consumption are the whole job; wear and a km rate are
/// optional. With [thenTemplate] (first run) saving continues with the route
/// form, so "car, then route" is one flow.
class VehicleFormView extends ConsumerStatefulWidget {
  const VehicleFormView({
    required this.groupId,
    this.vehicleId,
    this.thenTemplate = false,
    super.key,
  });

  final String groupId;
  final String? vehicleId;
  final bool thenTemplate;

  @override
  ConsumerState<VehicleFormView> createState() => _VehicleFormViewState();
}

class _VehicleFormViewState extends ConsumerState<VehicleFormView> {
  final _name = TextEditingController();

  VehicleFormKey get _key =>
      (groupId: widget.groupId, vehicleId: widget.vehicleId);

  @override
  void initState() {
    super.initState();
    // Fill the name once with the stored value; later edits are the user's.
    ref.listenManual(vehicleFormViewModelProvider(_key), (prev, next) {
      if (prev is! VehicleFormReady && next is VehicleFormReady) {
        _name.text = next.name;
      } else if (prev is VehicleFormReady &&
          next is VehicleFormReady &&
          prev.nameRevision != next.nameRevision) {
        // A catalog pick or its undo changed the name, not the user's typing.
        _name.value = TextEditingValue(
          text: next.name,
          selection: TextSelection.collapsed(offset: next.name.length),
        );
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(CarCatalogEntry entry) {
    final undo = ref
        .read(vehicleFormViewModelProvider(_key).notifier)
        .applyCatalogEntry(entry);
    if (undo != null) {
      showUndoSnackBar(
        context,
        message: AppLocalizations.of(context).vehicleCatalogPicked(entry.name),
        undo: undo,
      );
    }
  }

  Future<void> _save() async {
    final result = await ref
        .read(vehicleFormViewModelProvider(_key).notifier)
        .save();
    if (!mounted) return;
    switch (result) {
      case Ok():
        if (widget.thenTemplate) {
          context.pushReplacement(
            '/groups/${widget.groupId}/rides/templates/new',
          );
        } else {
          context.pop();
        }
      case Err(error: InvalidData()):
        break; // Explained inline.
      case Err(:final error):
        showErrorSnackBar(
          ScaffoldMessenger.of(context),
          AppLocalizations.of(context),
          error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(vehicleFormViewModelProvider(_key).notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.vehicleId == null ? l10n.vehicleFormNew : l10n.vehicleFormEdit,
        ),
      ),
      body: switch (ref.watch(vehicleFormViewModelProvider(_key))) {
        VehicleFormLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        VehicleFormFailure() => ErrorState(onRetry: vm.retry),
        final VehicleFormReady form => Column(
          children: [
            Expanded(
              child: _FormBody(
                form: form,
                vm: vm,
                name: _name,
                onPick: _pick,
                vehicleId: widget.vehicleId,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: Spacing.screen,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: form.saving ? null : () => unawaited(_save()),
                    child: Text(l10n.vehicleSave),
                  ),
                ),
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.form,
    required this.vm,
    required this.name,
    required this.onPick,
    required this.vehicleId,
  });

  final String? vehicleId;
  final VehicleFormReady form;
  final VehicleFormViewModel vm;
  final TextEditingController name;
  final ValueChanged<CarCatalogEntry> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final symbol = MoneyFormat.of(context).currencySymbol(form.currency);
    return ListView(
      padding: Spacing.screen,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (form.editing && vehicleId != null)
          VehicleLinkNote(vehicleId: vehicleId!),
        TextField(
          controller: name,
          autofocus: !form.editing,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          onChanged: vm.setName,
          decoration: InputDecoration(
            labelText: l10n.vehicleNameLabel,
            hintText: l10n.vehicleNameHint,
            errorText: form.showErrors && form.nameMissing
                ? l10n.vehicleErrorName
                : null,
          ),
        ),
        _CatalogSuggestions(form: form, onPick: onPick),
        Padding(
          padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
          child: Text(
            l10n.vehicleFuelSection,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Wrap(
          spacing: Spacing.sm,
          children: [
            for (final fuel in FuelType.values)
              ChoiceChip(
                label: Text(fuelLabel(l10n, fuel)),
                selected: form.fuelType == fuel,
                onSelected: (_) => vm.setFuelType(fuel),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        MilliField(
          label: form.fuelType == FuelType.electric
              ? l10n.vehicleConsumptionKwh
              : l10n.vehicleConsumptionLitre,
          milli: form.consumptionMilli,
          onChanged: vm.setConsumption,
          errorText: form.showErrors && form.consumptionMissing
              ? l10n.vehicleErrorConsumption
              : null,
        ),
        if (form.fromCatalog != null) _WltpNote(form: form, vm: vm),
        const SizedBox(height: Spacing.md),
        MilliField(
          label: l10n.vehicleWearLabel,
          suffix: symbol,
          milli: form.wearMilli,
          onChanged: vm.setWear,
        ),
        const SizedBox(height: Spacing.md),
        MilliField(
          label: l10n.vehicleKmRateLabel,
          suffix: symbol,
          helper: l10n.vehicleKmRateHelper,
          milli: form.kmRateMilli,
          onChanged: vm.setKmRate,
        ),
        const SizedBox(height: Spacing.md),
      ],
    );
  }
}

/// "Golf" -> up to five cars; or why there are none: nothing matches, or the
/// list could not be loaded (never silent, the form works by hand either way).
class _CatalogSuggestions extends StatelessWidget {
  const _CatalogSuggestions({required this.form, required this.onPick});

  final VehicleFormReady form;
  final ValueChanged<CarCatalogEntry> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (form.catalogUnavailable) {
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.sm),
        child: Text(
          l10n.vehicleCatalogUnavailable,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }
    if (form.noMatch) {
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.sm),
        child: Text(l10n.vehicleCatalogNoMatch, style: hint),
      );
    }
    if (form.suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Semantics(
        container: true,
        label: l10n.vehicleCatalogSuggestions,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in form.suggestions)
                ListTile(
                  key: ValueKey(
                    'suggestion-${entry.name}-${entry.engineCc}'
                    '-${entry.powerKw}-${entry.fuelType.name}-${entry.hybrid}',
                  ),
                  title: Text(entry.name),
                  subtitle: Text(_describe(context, entry)),
                  onTap: () => onPick(entry),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.xs,
                  Spacing.md,
                  Spacing.sm,
                ),
                child: Text(l10n.vehicleCatalogSource, style: hint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "1,5 l, 96 kW, Benzin, 5,6 l/100 km".
String _describe(BuildContext context, CarCatalogEntry e) {
  final l10n = AppLocalizations.of(context);
  final sep = MoneyFormat.of(context).decimalSeparator;
  final electric = e.fuelType == FuelType.electric;
  final value = formatMilli(e.consumptionMilliPer100km, separator: sep);
  return [
    if (e.engineCc > 0)
      l10n.vehicleCatalogEngine(formatMilli(e.engineCc, separator: sep)),
    if (e.powerKw > 0) l10n.vehicleCatalogPower(e.powerKw),
    if (e.hybrid)
      l10n.vehicleCatalogHybrid(fuelLabel(l10n, e.fuelType))
    else
      fuelLabel(l10n, e.fuelType),
    if (electric)
      l10n.vehicleCatalogConsumptionKwh(value)
    else
      l10n.vehicleCatalogConsumptionLitre(value),
  ].join(', ');
}

/// The honest line under the consumption field after a catalog pick, with
/// the one-tap realistic estimate.
class _WltpNote extends StatelessWidget {
  const _WltpNote({required this.form, required this.vm});

  final VehicleFormReady form;
  final VehicleFormViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final real = form.realisticMilli;
    final text = form.realisticApplied
        ? l10n.vehicleCatalogRealisticNote
        : real == null
        ? l10n.vehicleCatalogWltpNoteElectric
        : l10n.vehicleCatalogWltpNote;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: style),
          if (real != null && !form.realisticApplied)
            TextButton(
              onPressed: vm.useRealisticConsumption,
              child: Text(
                l10n.vehicleCatalogUseRealistic(
                  formatMilli(
                    real,
                    separator: MoneyFormat.of(context).decimalSeparator,
                  ),
                ),
              ),
            ),
          Text(l10n.vehicleCatalogSource, style: style),
        ],
      ),
    );
  }
}
