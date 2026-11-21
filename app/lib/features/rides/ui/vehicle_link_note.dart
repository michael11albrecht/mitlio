import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/rides/ui/vehicle_link_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// On the form of a group vehicle that is a copy of a personal car: says so
/// and offers "Trennen". Nothing for an ordinary vehicle.
class VehicleLinkNote extends ConsumerWidget {
  const VehicleLinkNote({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = vehicleLinkViewModelProvider(vehicleId);
    final vm = ref.read(provider.notifier);

    Future<void> unlink() async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await vm.unlink();
      switch (result) {
        case Ok():
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.carUnlinked)));
        case Err(:final error):
          showErrorSnackBar(messenger, l10n, error);
      }
    }

    return switch (ref.watch(provider)) {
      AsyncLoading() || AsyncData(value: false) => const SizedBox.shrink(),
      AsyncError() => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.carLinkFailed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            TextButton(onPressed: vm.retry, child: Text(l10n.retry)),
          ],
        ),
      ),
      AsyncData() => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: Spacing.allMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.carLinkedNote, style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed: () => unawaited(unlink()),
                  child: Text(l10n.carUnlink),
                ),
              ],
            ),
          ),
        ),
      ),
    };
  }
}
