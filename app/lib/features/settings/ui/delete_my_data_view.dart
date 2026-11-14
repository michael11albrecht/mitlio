import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/settings/ui/crash_reporting_view_model.dart';
import 'package:mitlio/features/settings/ui/delete_my_data_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The one confirmation step in the app (plan §2.6): a dedicated screen that
/// says what is deleted and what stays, and asks to type the confirmation
/// word. No dialog.
class DeleteMyDataView extends ConsumerWidget {
  const DeleteMyDataView({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final word = AppLocalizations.of(context).deleteMyDataConfirmWord;
    final router = GoRouter.of(context);
    final result = await ref
        .read(deleteMyDataViewModelProvider.notifier)
        .delete(word: word);
    if (result is! Ok) return;
    ref.invalidate(crashReportingViewModelProvider);
    // Home shows the first-run screen again: no group is left.
    router.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(deleteMyDataViewModelProvider);
    final vm = ref.read(deleteMyDataViewModelProvider.notifier);
    final deleting = state.status == DeleteMyDataStatus.deleting;
    final canDelete = state.matches(l10n.deleteMyDataConfirmWord) && !deleting;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteMyDataTitle)),
      body: ListView(
        padding: Spacing.screen,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.deleteMyDataWhatTitle,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(l10n.deleteMyDataWhat),
          const SizedBox(height: Spacing.sm),
          Text(l10n.deleteMyDataServer),
          const SizedBox(height: Spacing.lg),
          Semantics(
            header: true,
            child: Text(
              l10n.deleteMyDataStaysTitle,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(l10n.deleteMyDataStays),
          const SizedBox(height: Spacing.lg),
          Text(
            l10n.deleteMyDataIrreversible,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            enabled: !deleting,
            onChanged: vm.setTyped,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.deleteMyDataConfirmLabel,
            ),
          ),
          if (state.status == DeleteMyDataStatus.failed) ...[
            const SizedBox(height: Spacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.deleteMyDataFailed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: canDelete
                ? () => unawaited(_delete(context, ref))
                : null,
            child: Text(l10n.deleteMyDataAction),
          ),
        ],
      ),
    );
  }
}
