import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/profile/ui/car_setup_view.dart';
import 'package:mitlio/features/profile/ui/my_cars_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Meine Autos" (Settings): the personal cars and the way to add one. The
/// only entry to the car flow (ADR-25 §5: just-in-time entries come later).
class MyCarsView extends ConsumerWidget {
  const MyCarsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    final state = ref.watch(myCarsViewModelProvider);
    final vm = ref.read(myCarsViewModelProvider.notifier);

    Future<void> remove(Vehicle car) async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await vm.remove(car.id);
      if (!context.mounted) return;
      switch (result) {
        case Ok(:final value):
          showUndoSnackBar(
            context,
            message: l10n.carRemoved(car.name),
            undo: value,
          );
        case Err(:final error):
          showErrorSnackBar(messenger, l10n, error);
      }
    }

    void add() => unawaited(context.push('/settings/cars/new'));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.carsTitle)),
      body: switch (state) {
        MyCarsLoading() => const Center(child: CircularProgressIndicator()),
        MyCarsFailure() => ErrorState(onRetry: vm.retry),
        MyCarsLoaded(:final cars) when cars.isEmpty => EmptyState(
          icon: Icons.directions_car_outlined,
          title: l10n.carsEmptyTitle,
          message: l10n.carsEmptyMessage,
          action: FilledButton(onPressed: add, child: Text(l10n.carsAdd)),
        ),
        MyCarsLoaded(:final cars) => ListView(
          padding: Spacing.screen,
          children: [
            for (final car in cars)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car_outlined),
                  title: Text(car.name),
                  subtitle: Text(
                    carRowSubtitle(
                      l10n,
                      separator,
                      car.fuelType,
                      car.consumptionMilliPer100km,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.carRemoveLabel(car.name),
                    onPressed: () => unawaited(remove(car)),
                  ),
                ),
              ),
            const SizedBox(height: Spacing.md),
            FilledButton(onPressed: add, child: Text(l10n.carsAdd)),
          ],
        ),
      },
    );
  }
}
