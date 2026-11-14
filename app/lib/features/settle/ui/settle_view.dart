import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio/features/settle/ui/transfer_sheet.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Ausgleichen": what is left to pay (tap a transfer to pay and mark it),
/// below it the recorded settlements with swipe-to-delete and undo.
class SettleView extends ConsumerWidget {
  const SettleView({required this.groupId, super.key});

  final String groupId;

  Future<void> _share(
    BuildContext context,
    SettleViewModel vm,
    Currency currency,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat.of(context);
    final result = await vm.share((cents) => money.format(cents, currency));
    if (result is Err) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(settleViewModelProvider(groupId).notifier);
    final state = ref.watch(settleViewModelProvider(groupId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settleTitle),
        actions: [
          if (state is SettleLoaded && !state.isSettled)
            IconButton(
              tooltip: l10n.settleShare,
              icon: const Icon(Icons.ios_share),
              onPressed: () => unawaited(_share(context, vm, state.currency)),
            ),
        ],
      ),
      body: switch (state) {
        SettleLoading() => const Center(child: CircularProgressIndicator()),
        SettleFailure() => ErrorState(onRetry: vm.retry),
        final SettleLoaded loaded => _Loaded(
          groupId: groupId,
          state: loaded,
          vm: vm,
        ),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.groupId,
    required this.state,
    required this.vm,
  });

  final String groupId;
  final SettleLoaded state;
  final SettleViewModel vm;

  Future<void> _delete(BuildContext context, HistoryItem item) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await vm.deleteSettlement(item.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: l10n.settleHistoryDeleted,
          undo: value,
        );
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: Spacing.screen,
      children: [
        if (state.isSettled)
          _SettledBanner(
            title: l10n.settleSettledTitle,
            message: l10n.settleSettledMessage,
          )
        else ...[
          Semantics(
            header: true,
            child: Text(
              l10n.settleOpenTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          for (final t in state.transfers)
            _TransferRow(
              from: state.nameOf(t.fromId),
              fromId: t.fromId,
              to: state.nameOf(t.toId),
              cents: t.amountCents,
              currency: state.currency,
              onTap: () => unawaited(
                showTransferSheet(context, (
                  groupId: groupId,
                  fromId: t.fromId,
                  toId: t.toId,
                  amountCents: t.amountCents,
                )),
              ),
            ),
        ],
        const SizedBox(height: Spacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.settleHistoryTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        if (state.history.isEmpty)
          Text(
            l10n.settleHistoryEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final item in state.history)
            _HistoryRow(
              key: ValueKey(item.id),
              item: item,
              currency: state.currency,
              onDelete: () => unawaited(_delete(context, item)),
            ),
      ],
    );
  }
}

class _SettledBanner extends StatelessWidget {
  const _SettledBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: Radii.mdAll,
      ),
      child: Padding(
        padding: Spacing.allMd,
        child: MergeSemantics(
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.check_circle_outline,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.from,
    required this.fromId,
    required this.to,
    required this.cents,
    required this.currency,
    required this.onTap,
  });

  final String from;
  final String fromId;
  final String to;
  final int cents;
  final Currency currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: Spacing.allMd,
            child: Row(
              children: [
                MemberAvatar(memberId: fromId, name: from),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    l10n.settleTransfer(from, to),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                MoneyText(
                  cents: cents,
                  currency: currency,
                  style: theme.textTheme.titleMedium,
                ),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.item,
    required this.currency,
    required this.onDelete,
    super.key,
  });

  final HistoryItem item;
  final Currency currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(item.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: ClipRRect(
        borderRadius: Radii.mdAll,
        child: Semantics(
          customSemanticsActions: {
            CustomSemanticsAction(label: l10n.settleHistoryDelete): onDelete,
          },
          child: Dismissible(
            key: ValueKey('dismiss-${item.id}'),
            direction: DismissDirection.endToStart,
            // The list drops the row itself once the repository confirmed
            // the delete, so the swipe never "completes" on its own.
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
              child: ListTile(
                leading: MemberAvatar(
                  memberId: item.entry.settlement.fromId,
                  name: item.fromName,
                ),
                title: Text(l10n.settleTransfer(item.fromName, item.toName)),
                subtitle: Text(date),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyText(
                      cents: item.amountCents,
                      currency: currency,
                      style: theme.textTheme.titleMedium,
                    ),
                    IconButton(
                      tooltip: l10n.settleHistoryDelete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
