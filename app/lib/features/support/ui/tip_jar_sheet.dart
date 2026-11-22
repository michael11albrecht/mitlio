import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/features/support/ui/tip_jar_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Opens the tip jar in a bottom sheet (no dialog). Only reachable from the
/// Settings row and the quiet line on the "all settled" screen, never from
/// the payment flow (ADR-28, arch rule `no-tip-in-payment-path`).
Future<void> showTipJarSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const TipJarSheet(),
    );

/// "mitlio unterstützen": three sizes, one tap each, then a thank-you. The
/// store (StoreKit / Play Billing) asks for the confirmation.
class TipJarSheet extends ConsumerStatefulWidget {
  const TipJarSheet({super.key});

  @override
  ConsumerState<TipJarSheet> createState() => _TipJarSheetState();
}

class _TipJarSheetState extends ConsumerState<TipJarSheet> {
  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_load));
  }

  Future<void> _load() => ref.read(tipJarViewModelProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = ref.read(tipJarViewModelProvider.notifier);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: Spacing.md,
          right: Spacing.md,
          bottom: Spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.supportSheetTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(l10n.supportSheetIntro),
            const SizedBox(height: Spacing.md),
            switch (ref.watch(tipJarViewModelProvider)) {
              TipJarLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              TipJarUnavailable(:final failure) => ErrorState(
                message: _message(l10n, failure),
                onRetry: () => unawaited(vm.load()),
              ),
              final TipJarReady s => _Sizes(state: s, vm: vm),
              TipJarThanks() => _Thanks(
                onClose: () => Navigator.of(context).pop(),
              ),
            },
          ],
        ),
      ),
    );
  }
}

String _message(AppLocalizations l10n, TipFailure failure) => switch (failure) {
  TipFailure.storeUnavailable => l10n.supportErrorStore,
  TipFailure.productsUnavailable => l10n.supportErrorProducts,
  TipFailure.purchaseFailed => l10n.supportErrorPurchase,
};

class _Sizes extends StatelessWidget {
  const _Sizes({required this.state, required this.vm});

  final TipJarReady state;
  final TipJarViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final error = state.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in state.products)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: FilledButton.tonal(
              onPressed: state.buying == null
                  ? () => unawaited(vm.tip(p.size))
                  : null,
              child: Row(
                children: [
                  Expanded(child: Text(l10n.supportTipLabel(p.size.name))),
                  if (state.buying == p.size)
                    const SizedBox.square(
                      dimension: Spacing.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(p.price),
                ],
              ),
            ),
          ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _message(l10n, error),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _Thanks extends StatelessWidget {
  const _Thanks({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.supportThanksTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        Text(l10n.supportThanksBody),
        const SizedBox(height: Spacing.md),
        FilledButton(onPressed: onClose, child: Text(l10n.supportClose)),
      ],
    );
  }
}
