import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Archived groups with one action per row: restore. No confirm dialog; the
/// snack bar offers undo (archive again).
class ArchivedGroupsView extends ConsumerWidget {
  const ArchivedGroupsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(archivedGroupsViewModelProvider);
    final vm = ref.read(archivedGroupsViewModelProvider.notifier);

    Future<void> restore(String id, String name) async {
      final result = await vm.restore(id);
      if (!context.mounted) return;
      if (result case Ok(:final value)) {
        showUndoSnackBar(
          context,
          message: l10n.groupRestored(name),
          undo: value,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupsArchivedTitle)),
      body: switch (state) {
        GroupsLoading() => const Center(child: CircularProgressIndicator()),
        GroupsFailure() => ErrorState(onRetry: vm.retry),
        GroupsLoaded(:final groups) => ListView.separated(
          padding: Spacing.screen,
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (context, i) {
            final group = groups[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              // Stacked, not a ListTile: the action must fit at any text scale.
              child: Padding(
                padding: Spacing.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(l10n.currencyName(group.currency.code)),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Semantics(
                        label: l10n.groupRestoreLabel(group.name),
                        button: true,
                        excludeSemantics: true,
                        child: TextButton(
                          onPressed: () =>
                              unawaited(restore(group.id, group.name)),
                          child: Text(l10n.groupRestore),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      },
    );
  }
}
