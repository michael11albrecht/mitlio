import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/features/profile/ui/my_qr_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// "Mein QR-Code teilen" (PU-T16): the own IBAN as a QR code without amount
/// and one button that sends it as a picture through the share sheet. Reached
/// from Settings once an IBAN is saved.
class MyQrView extends StatelessWidget {
  const MyQrView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).myQrTitle)),
    body: const MyQrBody(),
  );
}

/// What "Mein QR-Code teilen" shows below the app bar (also what its golden
/// draws: the app bar title's text width is not stable across platforms).
class MyQrBody extends ConsumerWidget {
  const MyQrBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(myQrViewModelProvider.notifier);

    Future<void> share() async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await vm.share();
      if (!context.mounted) return;
      if (result case Err(:final error)) {
        showErrorSnackBar(messenger, l10n, error);
      }
    }

    return switch (ref.watch(myQrViewModelProvider)) {
      MyQrLoading() => const Center(child: CircularProgressIndicator()),
      MyQrFailure() => ErrorState(onRetry: () => unawaited(vm.load())),
      MyQrNoIban() => EmptyState(
        icon: Icons.qr_code_2,
        title: l10n.myQrNoIbanTitle,
        message: l10n.myQrNoIbanMessage,
      ),
      MyQrLoaded(:final name, :final payload) => ListView(
        padding: Spacing.screen,
        children: [
          Center(
            // Black on white in both themes, like every payment QR.
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: Radii.mdAll,
              ),
              child: QrImageView(
                data: payload,
                size: Sizes.qrCode,
                padding: Spacing.allMd,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(
                  color: Colors.black,
                ),
                semanticsLabel: l10n.myQrSemantics(name),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            l10n.myQrHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => unawaited(share()),
            icon: const Icon(Icons.ios_share),
            label: Text(l10n.myQrShare),
          ),
        ],
      ),
    };
  }
}
