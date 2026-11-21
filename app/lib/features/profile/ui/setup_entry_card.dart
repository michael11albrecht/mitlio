import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/widgets/inline_setup_card.dart';
import 'package:mitlio/features/profile/ui/entry_card_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The inline card for [card] (ADR-25 §5), or nothing while it is not
/// needed. The action opens the flow; coming back re-checks, so the card is
/// gone once the flow was finished.
class SetupEntryCard extends ConsumerWidget {
  const SetupEntryCard(this.card, {super.key});

  final EntryCard card;

  /// Where the card's action leads.
  String get _route => switch (card) {
    EntryCard.settlePayment || EntryCard.newGroupProfile => '/settings/profile',
    EntryCard.groupCar => '/settings/cars/new',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(entryCardViewModelProvider(card))) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(entryCardViewModelProvider(card).notifier);
    final (title, message, action) = switch (card) {
      EntryCard.settlePayment => (
        l10n.cardSettlePaymentTitle,
        l10n.cardSettlePaymentMessage,
        l10n.cardSettlePaymentAction,
      ),
      EntryCard.groupCar => (
        l10n.cardGroupCarTitle,
        l10n.cardGroupCarMessage,
        l10n.cardGroupCarAction,
      ),
      EntryCard.newGroupProfile => (
        l10n.cardNewGroupProfileTitle,
        l10n.cardNewGroupProfileMessage,
        l10n.cardNewGroupProfileAction,
      ),
    };

    Future<void> open() async {
      await context.push<void>(_route);
      await vm.refresh();
    }

    Future<void> dismiss() async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await vm.dismiss();
      if (result case Err(:final error)) {
        showErrorSnackBar(messenger, l10n, error);
      }
    }

    return InlineSetupCard(
      title: title,
      message: message,
      actionLabel: action,
      onAction: () => unawaited(open()),
      dismissLabel: l10n.cardDismiss,
      onDismiss: () => unawaited(dismiss()),
    );
  }
}
