import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/rides/ui/quick_log_card.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Localised name of a fuel type.
String fuelLabel(AppLocalizations l10n, FuelType fuel) => switch (fuel) {
  FuelType.petrol => l10n.fuelPetrol,
  FuelType.diesel => l10n.fuelDiesel,
  FuelType.electric => l10n.fuelElectric,
  FuelType.other => l10n.fuelOther,
};

/// Cars and routes of a group (behind the settings icon of the rides tab):
/// tap to edit, trash with undo, one add button per list.
class RidesSetupView extends ConsumerWidget {
  const RidesSetupView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(ridesSetupViewModelProvider(groupId).notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ridesSettingsTitle)),
      body: switch (ref.watch(ridesSetupViewModelProvider(groupId))) {
        RidesSetupLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        RidesSetupFailure() => ErrorState(onRetry: vm.retry),
        final RidesSetupLoaded loaded => _Lists(
          groupId: groupId,
          state: loaded,
          vm: vm,
        ),
      },
    );
  }
}

class _Lists extends StatelessWidget {
  const _Lists({required this.groupId, required this.state, required this.vm});

  final String groupId;
  final RidesSetupLoaded state;
  final RidesSetupViewModel vm;

  Future<void> _delete(
    BuildContext context, {
    required Future<RepoResult<Undo>> Function() command,
    required String Function(AppLocalizations) message,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await command();
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(context, message: message(l10n), undo: value);
      case Err(error: Conflict()):
        messenger.showSnackBar(SnackBar(content: Text(l10n.ridesVehicleInUse)));
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat.of(context);
    return ListView(
      padding: Spacing.screen,
      children: [
        _Header(l10n.ridesVehicles),
        if (state.vehicles.isEmpty) _Muted(l10n.ridesVehiclesEmpty),
        for (final v in state.vehicles)
          Card(
            margin: const EdgeInsets.only(bottom: Spacing.sm),
            child: ListTile(
              title: Text(v.name),
              subtitle: Text(
                l10n.ridesVehicleLine(
                  fuelLabel(l10n, v.fuelType),
                  formatMilli(
                    v.consumptionMilliPer100km,
                    separator: money.decimalSeparator,
                  ),
                  v.fuelType == FuelType.electric
                      ? l10n.ridesUnitKwh
                      : l10n.ridesUnitLitre,
                ),
              ),
              onTap: () => unawaited(
                context.push('/groups/$groupId/rides/vehicles/${v.id}'),
              ),
              trailing: IconButton(
                tooltip: l10n.ridesDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => unawaited(
                  _delete(
                    context,
                    command: () => vm.deleteVehicle(v.id),
                    message: (l) => l.ridesVehicleDeleted(v.name),
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.ridesVehicleAdd),
            onPressed: () => unawaited(
              context.push('/groups/$groupId/rides/vehicles/new'),
            ),
          ),
        ),
        _Header(l10n.ridesTemplates),
        if (state.templates.isEmpty) _Muted(l10n.ridesTemplatesEmpty),
        for (final t in state.templates)
          Card(
            margin: const EdgeInsets.only(bottom: Spacing.sm),
            child: ListTile(
              title: Text(t.name),
              subtitle: Text(
                [
                  distanceText(
                    context,
                    t.distanceMeters,
                    roundTrip: t.roundTrip,
                  ),
                  if (state.vehicle(t.vehicleId) case final v?) v.name,
                ].join(' · '),
              ),
              onTap: () => unawaited(
                context.push('/groups/$groupId/rides/templates/${t.id}'),
              ),
              trailing: IconButton(
                tooltip: l10n.ridesDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => unawaited(
                  _delete(
                    context,
                    command: () => vm.deleteTemplate(t.id),
                    message: (l) => l.ridesTemplateDeleted(t.name),
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.ridesTemplateAdd),
            onPressed: () => unawaited(
              context.push('/groups/$groupId/rides/templates/new'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
