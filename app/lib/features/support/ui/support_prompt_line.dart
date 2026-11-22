import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/support/ui/support_prompt_view_model.dart';
import 'package:mitlio/features/support/ui/tip_jar_sheet.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The quiet line under the "all settled" result (ADR-28 §2): no popup, no
/// amount, never in the payment step. Shows nothing unless the remote flag is
/// on and the rate limit allows it; "Nicht mehr zeigen" is permanent.
class SupportPromptLine extends ConsumerStatefulWidget {
  const SupportPromptLine({super.key});

  @override
  ConsumerState<SupportPromptLine> createState() => _SupportPromptLineState();
}

class _SupportPromptLineState extends ConsumerState<SupportPromptLine> {
  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_reached));
  }

  Future<void> _reached() =>
      ref.read(supportPromptViewModelProvider.notifier).settledScreenReached();

  Future<void> _never() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(supportPromptViewModelProvider.notifier)
        .dismissForever();
    if (result case Err(:final error)) {
      showErrorSnackBar(messenger, l10n, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(supportPromptViewModelProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supportPromptText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: Spacing.sm,
            children: [
              TextButton(
                onPressed: () => unawaited(showTipJarSheet(context)),
                child: Text(l10n.supportPromptAction),
              ),
              TextButton(
                onPressed: () => unawaited(_never()),
                child: Text(l10n.supportPromptNever),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
