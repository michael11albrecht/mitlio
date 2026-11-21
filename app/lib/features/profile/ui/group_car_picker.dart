import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/profile/ui/entry_card_view_model.dart'
    show EntryCard;
import 'package:mitlio/features/profile/ui/group_car_picker_view_model.dart';
import 'package:mitlio/features/profile/ui/setup_entry_card.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Under the vehicle list of a group: the personal cars that can be used
/// here with one tap ("Mein Auto", ADR-25 §2), or, without a personal car,
/// the calm card that offers to set one up once.
class GroupCarPicker extends ConsumerWidget {
  const GroupCarPicker({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = groupCarPickerViewModelProvider(groupId);
    final vm = ref.read(provider.notifier);

    Future<void> use(Vehicle car) async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await vm.use(car.id);
      if (result case Err(:final error)) {
        showErrorSnackBar(messenger, l10n, error);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SetupEntryCard(EntryCard.groupCar),
        switch (ref.watch(provider)) {
          AsyncLoading() => const SizedBox.shrink(),
          AsyncError() => Row(
            children: [
              Expanded(
                child: Text(
                  l10n.groupCarPickerFailed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              TextButton(onPressed: vm.retry, child: Text(l10n.retry)),
            ],
          ),
          AsyncData(:final value) when value.isEmpty => const SizedBox.shrink(),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Text(
                  l10n.groupCarPickerTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final car in value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_car_outlined),
                  title: Text(car.name),
                  trailing: TextButton(
                    onPressed: () => unawaited(use(car)),
                    child: Text(l10n.groupCarUse),
                  ),
                ),
            ],
          ),
        },
      ],
    );
  }
}
