import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/amount_field.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/settle/ui/transfer_sheet_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Opens one transfer in a bottom sheet (no dialog): pay, then mark as paid.
Future<void> showTransferSheet(BuildContext context, TransferKey key) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TransferSheet(transferKey: key),
    );

/// "Ben → Anna": the amount (editable for a partial payment), PayPal, the
/// EPC QR of a bank transfer and "Als bezahlt markieren". Only what the
/// receiver can actually be paid with is offered.
class TransferSheet extends ConsumerWidget {
  const TransferSheet({required this.transferKey, super.key});

  final TransferKey transferKey;

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    TransferSheetLoaded state,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await ref
        .read(transferSheetViewModelProvider(transferKey).notifier)
        .markPaid();
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        navigator.pop();
        showUndoSnackBar(
          context,
          message: l10n.settlePaidDone(state.fromName, state.toName),
          undo: value.undo,
        );
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = transferSheetViewModelProvider(transferKey);
    final vm = ref.read(provider.notifier);
    return switch (ref.watch(provider)) {
      TransferSheetLoading() => const SizedBox(
        height: Sizes.stateIcon * 3,
        child: Center(child: CircularProgressIndicator()),
      ),
      TransferSheetFailure() => ErrorState(onRetry: vm.retry),
      final TransferSheetLoaded s => _Content(
        state: s,
        vm: vm,
        onMarkPaid: () => unawaited(_markPaid(context, ref, s)),
      ),
    };
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.vm,
    required this.onMarkPaid,
  });

  final TransferSheetLoaded state;
  final TransferSheetViewModel vm;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyFormat.of(context);
    final problem = state.problem;
    final qr = state.epcPayload;
    final notice = switch (state.notice) {
      SheetNotice.linkCopied => l10n.paymentLinkCopied,
      SheetNotice.ibanCopied => l10n.settleIbanCopied,
      SheetNotice.actionFailed => l10n.settleActionFailed,
      null => null,
    };
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: Spacing.md,
          right: Spacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + Spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.settleTransfer(state.fromName, state.toName),
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: Spacing.md),
            AmountField(
              currency: state.currency,
              label: l10n.settleAmountLabel,
              cents: state.amountCents,
              onChanged: vm.setAmount,
            ),
            if (problem == AmountProblem.tooHigh)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Text(
                  l10n.settleAmountTooHigh(
                    money.format(state.fullCents, state.currency),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              )
            else if (problem == null && !state.isFull)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Text(
                  l10n.settlePartialHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: Spacing.md),
            if (state.hasNoPaymentDetails)
              Text(
                l10n.settleNoDetails(state.toName),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (state.options.hasPaypal) ...[
              OutlinedButton.icon(
                onPressed: problem == null ? vm.openPayPal : null,
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.settlePayPal),
              ),
              const SizedBox(height: Spacing.md),
            ],
            if (qr != null) ...[
              Semantics(
                header: true,
                child: Text(
                  l10n.settleBankTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Center(
                child: _QrCode(
                  data: qr,
                  label: l10n.settleQrLabel(state.toName),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                l10n.settleQrHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton.icon(
                onPressed: vm.copyIban,
                icon: const Icon(Icons.copy_outlined),
                label: Text(
                  state.options.ibanHint == null
                      ? l10n.settleCopyIban
                      : '${l10n.settleCopyIban} · ${state.options.ibanHint}',
                ),
              ),
              const SizedBox(height: Spacing.md),
            ] else if (state.options.hasIban) ...[
              // Bank details exist but no QR (not euro, or no valid amount):
              // copying the IBAN still works.
              OutlinedButton.icon(
                onPressed: vm.copyIban,
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.settleCopyIban),
              ),
              const SizedBox(height: Spacing.md),
            ],
            if (notice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    notice,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: state.notice == SheetNotice.actionFailed
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            FilledButton(
              onPressed: state.canMarkPaid ? onMarkPaid : null,
              child: Text(l10n.settleMarkPaid),
            ),
          ],
        ),
      ),
    );
  }
}

/// The QR stays black on white in both themes: dark-on-light is what banking
/// apps scan reliably.
class _QrCode extends StatelessWidget {
  const _QrCode({required this.data, required this.label});

  final String data;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: Radii.mdAll,
    ),
    child: QrImageView(
      data: data,
      size: Sizes.qrCode,
      padding: Spacing.allMd,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        color: Colors.black,
      ),
      semanticsLabel: label,
    ),
  );
}
