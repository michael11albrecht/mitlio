import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_shortcut.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Home: the groups of this device. One primary action, "new group": the
/// button of the empty state, or the floating button once groups exist.
class GroupsView extends ConsumerWidget {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(groupsViewModelProvider);
    void newGroup() => unawaited(context.push('/groups/new'));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => unawaited(context.push('/settings')),
          ),
        ],
      ),
      floatingActionButton: switch (state) {
        GroupsLoaded(isEmpty: false) => FloatingActionButton.extended(
          onPressed: newGroup,
          icon: const Icon(Icons.add),
          label: Text(l10n.groupNew),
        ),
        _ => null,
      },
      body: switch (state) {
        GroupsLoading() => const Center(child: CircularProgressIndicator()),
        GroupsFailure() => ErrorState(
          onRetry: ref.read(groupsViewModelProvider.notifier).retry,
        ),
        GroupsLoaded(isEmpty: true) => EmptyState(
          icon: Icons.groups_outlined,
          title: l10n.groupsEmptyTitle,
          message: l10n.groupsEmptyMessage,
          action: FilledButton(
            onPressed: newGroup,
            child: Text(l10n.groupCreate),
          ),
        ),
        GroupsLoaded(:final groups) => ListView.separated(
          padding: Spacing.screen.copyWith(bottom: Sizes.fabClearance),
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (context, i) {
            final group = groups[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    title: Text(group.name),
                    subtitle: Text(l10n.currencyName(group.currency.code)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(context.push('/groups/${group.id}')),
                  ),
                  RidesShortcut(groupId: group.id),
                ],
              ),
            );
          },
        ),
      },
    );
  }
}
