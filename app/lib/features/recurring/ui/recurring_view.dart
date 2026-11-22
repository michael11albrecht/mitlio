import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/recurring/ui/recurring_labels.dart';
import 'package:mitlio/features/recurring/ui/recurring_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Wiederkehrende Ausgaben" of one group: what repeats, when it is next due,
/// pause and delete (both with undo, no confirm dialog). New rules are made
/// on the add-expense form.
class RecurringView extends ConsumerWidget {
  const RecurringView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(recurringViewModelProvider(groupId).notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      body: switch (ref.watch(recurringViewModelProvider(groupId))) {
        RecurringLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        RecurringFailure() => ErrorState(onRetry: vm.retry),
        RecurringLoaded(:final rules) when rules.isEmpty => EmptyState(
          icon: Icons.repeat,
          title: l10n.recurringTitle,
          message: l10n.recurringEmpty,
        ),
        final RecurringLoaded loaded => ListView(
          padding: Spacing.screen,
          children: [
            for (final rule in loaded.rules)
              _RuleTile(rule: rule, loaded: loaded, vm: vm),
          ],
        ),
      },
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule, required this.loaded, required this.vm});

  final RecurringExpense rule;
  final RecurringLoaded loaded;
  final RecurringViewModel vm;

  Future<void> _pause(BuildContext context, {required bool paused}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await vm.setPaused(rule.id, paused: paused);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: paused
              ? l10n.recurringPausedDone(rule.title)
              : l10n.recurringResumedDone(rule.title),
          undo: value,
        );
      case Err(:final error):
        showErrorSnackBar(messenger, l10n, error);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await vm.delete(rule.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: l10n.recurringDeletedDone(rule.title),
          undo: value,
        );
      case Err(:final error):
        showErrorSnackBar(messenger, l10n, error);
    }
  }

  String _subtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = rule.nextAfter(loaded.today);
    final when = rule.paused
        ? l10n.recurringPaused
        : next == null
        ? l10n.recurringEnded
        : l10n.recurringNext(
            MaterialLocalizations.of(context).formatMediumDate(next),
          );
    return '${recurrenceLabel(l10n, rule.rule.frequency, rule.rule.interval)}'
        ' · $when';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = MoneyFormat.of(
      context,
    ).format(rule.amountCents, loaded.group.currency);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${rule.title} · $amount'),
      subtitle: Text(_subtitle(context)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: rule.paused ? l10n.recurringResume : l10n.recurringPause,
            child: Switch(
              value: !rule.paused,
              onChanged: (on) => unawaited(_pause(context, paused: !on)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.recurringDelete,
            onPressed: () => unawaited(_delete(context)),
          ),
        ],
      ),
    );
  }
}
