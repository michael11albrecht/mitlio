import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Home shortcut on a group card: "Heute gefahren" straight to the quick log
/// of the rides tab. Shown only for groups that have a ride template.
class RidesShortcut extends ConsumerWidget {
  const RidesShortcut({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTemplates = switch (ref.watch(hasRideTemplatesProvider(groupId))) {
      AsyncData(:final value) => value,
      _ => false,
    };
    if (!hasTemplates) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        0,
        Spacing.md,
        Spacing.sm,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          icon: const Icon(Icons.directions_car_outlined),
          label: Text(l10n.quickLogTitleToday),
          onPressed: () =>
              unawaited(context.push('/groups/$groupId?tab=rides')),
        ),
      ),
    );
  }
}
