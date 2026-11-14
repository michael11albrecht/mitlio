import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Localised label of a stored category key; custom keys show as they are.
String categoryLabel(AppLocalizations l10n, String key) => switch (key) {
  'food' => l10n.expenseCategoryFood,
  'stay' => l10n.expenseCategoryStay,
  'transport' => l10n.expenseCategoryTransport,
  'fun' => l10n.expenseCategoryFun,
  'other' => l10n.expenseCategoryOther,
  _ => key,
};

/// Group detail, expenses tab: expenses by day, newest first. One primary
/// action ("Ausgabe hinzufügen"), filters by person and category, swipe to
/// delete with an undo snackbar.
class ExpensesView extends ConsumerWidget {
  const ExpensesView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(expensesViewModelProvider(groupId).notifier);
    final state = ref.watch(expensesViewModelProvider(groupId));
    void add() => unawaited(context.push('/groups/$groupId/expenses/new'));
    return Scaffold(
      floatingActionButton: switch (state) {
        ExpensesLoaded(isEmpty: false, members: [_, ...]) =>
          FloatingActionButton.extended(
            onPressed: add,
            icon: const Icon(Icons.add),
            label: Text(l10n.expenseAdd),
          ),
        _ => null,
      },
      body: switch (state) {
        ExpensesLoading() => const Center(child: CircularProgressIndicator()),
        ExpensesFailure() => ErrorState(onRetry: vm.retry),
        ExpensesLoaded(members: []) => EmptyState(
          icon: Icons.person_add_alt_outlined,
          title: l10n.membersEmptyTitle,
          message: l10n.expensesNoMembersMessage,
          action: FilledButton(
            onPressed: () =>
                DefaultTabController.maybeOf(context)?.animateTo(0),
            child: Text(l10n.expensesNoMembersAction),
          ),
        ),
        ExpensesLoaded(isEmpty: true) => EmptyState(
          icon: Icons.receipt_long_outlined,
          title: l10n.expensesEmptyTitle,
          message: l10n.expensesEmptyMessage,
          action: FilledButton(onPressed: add, child: Text(l10n.expenseAdd)),
        ),
        final ExpensesLoaded loaded => _ExpenseList(
          groupId: groupId,
          state: loaded,
          vm: vm,
        ),
      },
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.groupId,
    required this.state,
    required this.vm,
  });

  final String groupId;
  final ExpensesLoaded state;
  final ExpensesViewModel vm;

  Future<void> _delete(BuildContext context, ExpenseEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await vm.delete(entry.expense.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: l10n.expenseDeleted(entry.expense.title),
          undo: value,
        );
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = state.days;
    final showFilters = state.members.length > 1 || state.categories.isNotEmpty;
    return Column(
      children: [
        if (showFilters) _FilterBar(state: state, vm: vm),
        Expanded(
          child: days.isEmpty
              ? EmptyState(
                  icon: Icons.filter_list_off,
                  title: l10n.expenseFilterEmptyTitle,
                  action: TextButton(
                    onPressed: vm.clearFilters,
                    child: Text(l10n.expenseFilterReset),
                  ),
                )
              : ListView(
                  padding: Spacing.screen.copyWith(
                    top: Spacing.sm,
                    bottom: Sizes.fabClearance,
                  ),
                  children: [
                    for (final day in days) ...[
                      _DayHeader(date: day.date, today: state.today),
                      for (final entry in day.entries)
                        _ExpenseRow(
                          key: ValueKey(entry.expense.id),
                          groupId: groupId,
                          entry: entry,
                          state: state,
                          onDelete: () => unawaited(_delete(context, entry)),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state, required this.vm});

  final ExpensesLoaded state;
  final ExpensesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final person = state.memberFilter == null
        ? null
        : state.member(state.memberFilter!)?.name;
    final category = state.categoryFilter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: Spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (state.members.length > 1)
              _FilterChip(
                label: person ?? l10n.expenseFilterPerson,
                active: person != null,
                allLabel: l10n.expenseFilterAll,
                options: [for (final m in state.members) (m.id, m.name)],
                onSelected: vm.setMemberFilter,
              ),
            if (state.categories.isNotEmpty)
              _FilterChip(
                label: category == null
                    ? l10n.expenseFilterCategory
                    : categoryLabel(l10n, category),
                active: category != null,
                allLabel: l10n.expenseFilterAll,
                options: [
                  for (final c in state.categories) (c, categoryLabel(l10n, c)),
                ],
                onSelected: vm.setCategoryFilter,
              ),
          ],
        ),
      ),
    );
  }
}

/// A chip that opens a menu of [options] (value, label) plus "all".
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.allLabel,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final bool active;
  final String allLabel;
  final List<(String, String)> options;
  final ValueChanged<String?> onSelected;

  /// Menu value of "all": popup menus do not report a null selection.
  static const _all = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: (v) => onSelected(v == _all ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: _all, child: Text(allLabel)),
        for (final (value, text) in options)
          PopupMenuItem(value: value, child: Text(text)),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.tapTarget),
        child: Center(
          widthFactor: 1,
          child: ExcludeSemantics(
            child: Chip(
              backgroundColor: active ? scheme.secondaryContainer : null,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.today});

  final DateTime date;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = date == today
        ? l10n.expenseToday
        : date == today.subtract(const Duration(days: 1))
        ? l10n.expenseYesterday
        : MaterialLocalizations.of(context).formatMediumDate(date);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xs),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.groupId,
    required this.entry,
    required this.state,
    required this.onDelete,
    super.key,
  });

  final String groupId;
  final ExpenseEntry entry;
  final ExpensesLoaded state;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final expense = entry.expense;
    final payers = expense.payers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final payer = state.member(payers.first.key);
    final payerName = payer?.name ?? '';
    final paidBy = payers.length == 1
        ? l10n.expensePaidBy(payerName)
        : l10n.expensePaidByMore(payerName, payers.length - 1);
    final category = entry.category;
    final subtitle = category == null
        ? paidBy
        : '$paidBy · ${categoryLabel(l10n, category)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: ClipRRect(
        borderRadius: Radii.mdAll,
        child: Semantics(
          customSemanticsActions: {
            CustomSemanticsAction(label: l10n.expenseDelete): onDelete,
          },
          child: Dismissible(
            key: ValueKey('dismiss-${expense.id}'),
            direction: DismissDirection.endToStart,
            // The list removes the row itself (and brings it back if the
            // delete fails), so the swipe never "completes" on its own.
            confirmDismiss: (_) async {
              onDelete();
              return false;
            },
            background: ColoredBox(
              color: scheme.errorContainer,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.delete_outline,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: MemberAvatar(
                  memberId: payers.first.key,
                  name: payerName,
                ),
                title: Text(expense.title),
                subtitle: Text(subtitle),
                trailing: MoneyText(
                  cents: expense.amountCents,
                  currency: expense.currency,
                  style: theme.textTheme.titleMedium,
                ),
                onTap: () => unawaited(
                  context.push('/groups/$groupId/expenses/${expense.id}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
