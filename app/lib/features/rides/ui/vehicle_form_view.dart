import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/features/rides/ui/milli_field.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';
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
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
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
      case Err():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorTitle)),
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
              child: _FormBody(form: form, vm: vm, name: _name),
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
  const _FormBody({required this.form, required this.vm, required this.name});

  final VehicleFormReady form;
  final VehicleFormViewModel vm;
  final TextEditingController name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final symbol = MoneyFormat.of(context).currencySymbol(form.currency);
    return ListView(
      padding: Spacing.screen,
      children: [
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
