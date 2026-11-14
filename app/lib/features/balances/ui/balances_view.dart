import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Balances of one group, result first: who gets money back, who owes, then
/// "who pays whom" with a simple/direct switch. Read-only.
class BalancesView extends ConsumerWidget {
  const BalancesView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(balancesViewModelProvider(groupId).notifier);
    final state = ref.watch(balancesViewModelProvider(groupId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.balancesTitle)),
      // One obvious next step: pay what is open (or look at what was paid).
      floatingActionButton: state is BalancesLoaded && state.hasEntries
          ? FloatingActionButton.extended(
              onPressed: () =>
                  unawaited(context.push('/groups/$groupId/settle')),
              icon: const Icon(Icons.payments_outlined),
              label: Text(l10n.settleOpen),
            )
          : null,
      body: switch (state) {
        BalancesLoading() => const Center(child: CircularProgressIndicator()),
        BalancesFailure() => ErrorState(onRetry: vm.retry),
        final BalancesLoaded loaded when !loaded.hasEntries => EmptyState(
          icon: Icons.balance_outlined,
          title: l10n.balancesEmptyTitle,
          message: l10n.balancesEmptyMessage,
        ),
        final BalancesLoaded loaded => _Loaded(
          state: loaded,
          onMode: vm.setMode,
        ),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.onMode});

  final BalancesLoaded state;
  final ValueChanged<BalancesMode> onMode;

  /// Gets first (largest on top), then owes (largest on top), then square.
  List<MemberBalance> get _ordered {
    final all = [...state.balances];
    int group(MemberBalance b) => b.cents > 0 ? 0 : (b.cents < 0 ? 1 : 2);
    all.sort((a, b) {
      final byGroup = group(a).compareTo(group(b));
      return byGroup != 0 ? byGroup : b.cents.abs().compareTo(a.cents.abs());
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: Spacing.screen.copyWith(bottom: Sizes.fabClearance),
      children: [
        if (state.isSettled) ...[
          _SettledBanner(
            title: l10n.balancesSettledTitle,
            message: l10n.balancesSettledMessage,
          ),
          const SizedBox(height: Spacing.md),
        ],
        for (final b in _ordered)
          _BalanceRow(balance: b, currency: state.currency),
        if (!state.isSettled) ...[
          const SizedBox(height: Spacing.lg),
          Semantics(
            header: true,
            child: Text(
              l10n.balancesTransfersTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          SegmentedButton<BalancesMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: BalancesMode.simplified,
                label: Text(l10n.balancesModeSimplified),
              ),
              ButtonSegment(
                value: BalancesMode.pairwise,
                label: Text(l10n.balancesModeDirect),
              ),
            ],
            selected: {state.mode},
            onSelectionChanged: (s) => onMode(s.single),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            state.mode == BalancesMode.simplified
                ? l10n.balancesModeSimplifiedHint
                : l10n.balancesModeDirectHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          for (final t in state.transfers)
            _TransferRow(
              text: l10n.balancesTransfer(
                state.nameOf(t.fromId),
                state.nameOf(t.toId),
              ),
              transfer: t,
              currency: state.currency,
            ),
        ],
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

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balance, required this.currency});

  final MemberBalance balance;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final member = balance.member;
    final cents = balance.cents;
    final label = cents > 0
        ? l10n.balanceGets(member.name)
        : cents < 0
        ? l10n.balanceOwes(member.name)
        : l10n.balanceEven(member.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        child: Padding(
          padding: Spacing.allMd,
          child: MergeSemantics(
            child: Row(
              children: [
                MemberAvatar(memberId: member.id, name: member.name),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cents == 0 ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
                if (cents != 0) ...[
                  const SizedBox(width: Spacing.sm),
                  MoneyText(
                    cents: cents.abs(),
                    currency: currency,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: cents > 0 ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.text,
    required this.transfer,
    required this.currency,
  });

  final String text;
  final Transfer transfer;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: Radii.mdAll,
        ),
        child: Padding(
          padding: Spacing.allMd,
          child: MergeSemantics(
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.arrow_forward,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
                const SizedBox(width: Spacing.sm),
                MoneyText(
                  cents: transfer.amountCents,
                  currency: currency,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
