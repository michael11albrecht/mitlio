import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/features/onboarding/ui/onboarding_view.dart';
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
        // First run: no groups yet.
        GroupsLoaded(isEmpty: true, :final archivedCount) =>
          archivedCount == 0
              ? const OnboardingBody()
              : Column(
                  children: [
                    const Expanded(child: OnboardingBody()),
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.md),
                      child: _ArchivedEntry(archivedCount),
                    ),
                  ],
                ),
        GroupsLoaded(:final groups, :final archivedCount) => ListView.separated(
          padding: Spacing.screen.copyWith(bottom: Sizes.fabClearance),
          itemCount: groups.length + (archivedCount > 0 ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (context, i) {
            if (i == groups.length) {
              // Quiet entry, only when something is archived.
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: _ArchivedEntry(archivedCount),
              );
            }
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

/// Quiet link to the archived groups; shown only when there are some.
class _ArchivedEntry extends StatelessWidget {
  const _ArchivedEntry(this.count);

  final int count;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => unawaited(context.push('/groups/archived')),
    child: Text(AppLocalizations.of(context).groupsArchivedEntry(count)),
  );
}
