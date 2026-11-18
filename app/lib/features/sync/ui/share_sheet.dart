import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/sync/ui/share_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Opens "Gruppe teilen" in a bottom sheet (no dialog, plan §2.6): the link,
/// its QR code and the system share button.
Future<void> showShareSheet(BuildContext context, String groupId) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ShareSheet(groupId: groupId),
    );

class ShareSheet extends ConsumerStatefulWidget {
  const ShareSheet({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  @override
  void initState() {
    super.initState();
    // Not during build: the command changes provider state.
    unawaited(
      Future.microtask(
        () => ref.read(shareViewModelProvider(widget.groupId).notifier).share(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(shareViewModelProvider(widget.groupId));
    final vm = ref.read(shareViewModelProvider(widget.groupId).notifier);
    return SafeArea(
      child: SingleChildScrollView(
        padding: Spacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.shareSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.md),
            switch (state) {
              ShareLoading() => _Loading(text: l10n.sharePreparing),
              ShareFailed(:final failure) => _Failed(
                text: failure.text(l10n),
                onRetry: () => unawaited(vm.share()),
              ),
              final ShareReady ready => _Ready(state: ready, vm: vm),
            },
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: Spacing.allLg,
    child: Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: Spacing.md),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text),
        const SizedBox(height: Spacing.md),
        FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state, required this.vm});

  final ShareReady state;
  final ShareViewModel vm;

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await vm.shareLink(l10n);
    if (result is Err && context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = state.rotating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _QrCode(
            data: state.link.url,
            label: l10n.shareQrLabel(state.groupName),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          state.link.shortUrl,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (!state.link.saved) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            l10n.inviteNotSaved,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: Spacing.md),
        FilledButton.icon(
          onPressed: busy ? null : () => unawaited(_share(context)),
          icon: const Icon(Icons.ios_share),
          label: Text(l10n.shareLinkButton),
        ),
        if (state.isOwner) ...[
          const SizedBox(height: Spacing.sm),
          if (state.confirmingRotate)
            _RotateConfirm(state: state, vm: vm)
          else
            TextButton(
              onPressed: vm.askRotate,
              child: Text(l10n.inviteRotate),
            ),
        ],
      ],
    );
  }
}

/// The second step of "Neuen Link erstellen", inline: the server revokes the
/// old link at once, so there is no undo (plan §2.6 #4/#5).
class _RotateConfirm extends StatelessWidget {
  const _RotateConfirm({required this.state, required this.vm});

  final ShareReady state;
  final ShareViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final error = state.rotateError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.inviteRotateWarning,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (error != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            error.text(l10n),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: Spacing.sm),
        FilledButton.tonal(
          onPressed: state.rotating
              ? null
              : () => unawaited(vm.confirmRotate()),
          child: state.rotating
              ? const SizedBox.square(
                  dimension: Spacing.lg,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.inviteRotate),
        ),
        TextButton(
          onPressed: state.rotating ? null : vm.cancelRotate,
          child: Text(l10n.inviteRotateCancel),
        ),
      ],
    );
  }
}

/// The QR stays black on white in both themes: dark-on-light is what phone
/// cameras scan most reliably.
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
      eyeStyle: const QrEyeStyle(color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
      semanticsLabel: label,
    ),
  );
}
