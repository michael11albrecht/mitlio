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
import 'package:mitlio/features/profile/ui/car_edit_view_model.dart';
import 'package:mitlio/features/rides/ui/milli_field.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view.dart' show fuelLabel;
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// One personal car in one step (name, fuel, consumption, extra cost per
/// km). Saving updates every group that uses it, with an undo snackbar.
class CarEditView extends ConsumerStatefulWidget {
  const CarEditView({required this.carId, super.key});

  final String carId;

  @override
  ConsumerState<CarEditView> createState() => _CarEditViewState();
}

class _CarEditViewState extends ConsumerState<CarEditView> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fill the name once with the stored value; later edits are the user's.
    ref.listenManual(carEditViewModelProvider(widget.carId), (prev, next) {
      if (prev is! CarEditReady && next is CarEditReady) _name.text = next.name;
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(carEditViewModelProvider(widget.carId).notifier)
        .save();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        // The snack bar belongs to the app, so it outlives this screen.
        if (value.groups > 0) {
          showUndoSnackBar(
            context,
            message: l10n.carUpdatedInGroups(value.groups),
            undo: value.undo,
          );
        }
        context.pop();
      case Err(error: InvalidData()):
        break; // Explained inline.
      case Err(:final error):
        showErrorSnackBar(messenger, l10n, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = carEditViewModelProvider(widget.carId);
    final vm = ref.read(provider.notifier);
    final symbol = MoneyFormat.of(context).currencySymbol(Currency.eur);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.carEditTitle)),
      body: switch (ref.watch(provider)) {
        CarEditLoading() => const Center(child: CircularProgressIndicator()),
        CarEditFailure() => ErrorState(onRetry: vm.retry),
        final CarEditReady form => Column(
          children: [
            Expanded(
              child: ListView(
                padding: Spacing.screen,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    onChanged: vm.setName,
                    decoration: InputDecoration(
                      labelText: l10n.vehicleNameLabel,
                      errorText: form.showErrors && form.nameMissing
                          ? l10n.vehicleErrorName
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: Spacing.md,
                      bottom: Spacing.sm,
                    ),
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
                ],
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
