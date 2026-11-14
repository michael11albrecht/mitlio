import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/expenses/ui/expense_history_view_model.dart';
import 'package:mitlio/features/expenses/ui/expenses_view.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Opens the "Verlauf" of [expenseId]. Completes with true when a version was
/// restored (the stored expense changed, so an open form is stale).
Future<bool?> showExpenseHistorySheet(BuildContext context, String expenseId) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => ExpenseHistorySheet(expenseId: expenseId),
    );

/// Changes of one expense, newest first, each with what it did to the
/// fields and "Diese Version wiederherstellen" (an undo snackbar, no dialog).
class ExpenseHistorySheet extends ConsumerWidget {
  const ExpenseHistorySheet({required this.expenseId, super.key});

  final String expenseId;

  Future<void> _restore(
    BuildContext context,
    ExpenseHistoryViewModel vm,
    String revisionId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await vm.restore(revisionId);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: l10n.expenseHistoryRestored,
          undo: value,
        );
        navigator.pop(true);
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(expenseHistoryViewModelProvider(expenseId).notifier);
    final state = ref.watch(expenseHistoryViewModelProvider(expenseId));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
          child: Semantics(
            header: true,
            child: Text(
              l10n.expenseHistory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Flexible(
          child: switch (state) {
            ExpenseHistoryLoading() => const Padding(
              padding: EdgeInsets.all(Spacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            ExpenseHistoryFailure() => ErrorState(onRetry: vm.retry),
            ExpenseHistoryLoaded(isEmpty: true) => EmptyState(
              icon: Icons.history,
              title: l10n.expenseHistoryEmpty,
            ),
            final ExpenseHistoryLoaded loaded => ListView(
              shrinkWrap: true,
              padding: Spacing.screen,
              children: [
                for (final item in loaded.items)
                  _HistoryTile(
                    key: ValueKey(item.revisionId),
                    item: item,
                    state: loaded,
                    onRestore: () =>
                        unawaited(_restore(context, vm, item.revisionId)),
                  ),
              ],
            ),
          },
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.state,
    required this.onRestore,
    super.key,
  });

  final ExpenseHistoryItem item;
  final ExpenseHistoryLoaded state;
  final VoidCallback onRestore;

  String _name(AppLocalizations l10n, String id) =>
      state.memberNames[id] ?? l10n.expenseHistoryUnknownMember;

  String _money(BuildContext context, int cents, String? code) =>
      MoneyFormat.of(
        context,
      ).format(
        cents,
        code == null
            ? state.currency
            : Currency.tryParse(code) ?? state.currency,
      );

  String _splitLabel(AppLocalizations l10n, String mode) => switch (mode) {
    'equal' => l10n.expenseSplitEqual,
    'shares' => l10n.expenseSplitShares,
    'percent' => l10n.expenseSplitPercent,
    'exact' => l10n.expenseSplitExact,
    _ => mode,
  };

  String _line(BuildContext context, ExpenseChange change) {
    final l10n = AppLocalizations.of(context);
    final dates = MaterialLocalizations.of(context);
    final money = MoneyFormat.of(context);
    String category(String? key) =>
        key == null ? '–' : categoryLabel(l10n, key);
    return switch (change) {
      TitleChange(:final from, :final to) => l10n.expenseHistoryTitle(from, to),
      AmountChange(
        :final fromCents,
        :final fromCurrency,
        :final toCents,
        :final toCurrency,
      ) =>
        l10n.expenseHistoryAmount(
          _money(context, fromCents, fromCurrency),
          _money(context, toCents, toCurrency),
        ),
      RateChange(:final fromPpm, :final toPpm) => l10n.expenseHistoryRate(
        money.formatRate(fromPpm),
        money.formatRate(toPpm),
      ),
      DateChange(:final from, :final to) => l10n.expenseHistoryDate(
        dates.formatMediumDate(from),
        dates.formatMediumDate(to),
      ),
      CategoryChange(:final from, :final to) => l10n.expenseHistoryCategory(
        category(from),
        category(to),
      ),
      SplitModeChange(:final from, :final to) => l10n.expenseHistorySplit(
        _splitLabel(l10n, from),
        _splitLabel(l10n, to),
      ),
      TripDetailsChange() => l10n.expenseHistoryTrip,
      PayerAdded(:final memberId) => l10n.expenseHistoryPayerAdded(
        _name(l10n, memberId),
      ),
      PayerRemoved(:final memberId) => l10n.expenseHistoryPayerRemoved(
        _name(l10n, memberId),
      ),
      PaidChange(:final memberId, :final fromCents, :final toCents) =>
        l10n.expenseHistoryPaid(
          _name(l10n, memberId),
          _money(context, fromCents, null),
          _money(context, toCents, null),
        ),
      ParticipantAdded(:final memberId) => l10n.expenseHistoryParticipantAdded(
        _name(l10n, memberId),
      ),
      ParticipantRemoved(:final memberId) =>
        l10n.expenseHistoryParticipantRemoved(_name(l10n, memberId)),
      ShareChange(:final memberId, :final fromCents, :final toCents) =>
        l10n.expenseHistoryShare(
          _name(l10n, memberId),
          _money(context, fromCents, null),
          _money(context, toCents, null),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = MaterialLocalizations.of(context);
    final local = item.changedAt.toLocal();
    final when =
        '${dates.formatMediumDate(local)}, '
        '${dates.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
    final author = item.authorName;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author == null
                    ? when
                    : l10n.expenseHistoryByAuthor(when, author),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              if (item.changes.isEmpty)
                Text(l10n.expenseHistoryNoVisibleChange)
              else
                for (final change in item.changes) Text(_line(context, change)),
              if (item.changes.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: onRestore,
                    child: Text(l10n.expenseHistoryRestore),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
