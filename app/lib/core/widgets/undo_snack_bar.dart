import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart' show Err;

/// Short on purpose: a snack bar that lingers invites accidental taps on
/// "Undo". Flutter keeps snack bars with an action until dismissed unless
/// `persist` is false.
const undoSnackBarDuration = Duration(seconds: 4);

/// Tells what happened and offers "Undo" (plan §2.6: undo instead of confirm
/// dialogs). Replaces a snack bar that is still showing. Uses the app-level
/// messenger, so it survives a navigation right after the command.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required Undo undo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        // The chevron also hints that the bar can be swiped down.
        content: Row(
          children: [
            Expanded(child: Text(message)),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: l10n.hideSnackBar,
              onPressed: messenger.hideCurrentSnackBar,
            ),
          ],
        ),
        dismissDirection: DismissDirection.down,
        persist: false,
        duration: undoSnackBarDuration, // ignore: avoid_redundant_argument_values, pinned so a Flutter default change cannot make it linger
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => unawaited(_undo(messenger, l10n, undo)),
        ),
      ),
    );
}

/// Runs [undo]; a refusal is shown, never swallowed.
Future<void> _undo(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Undo undo,
) async {
  final result = await undo();
  if (result case Err(:final error)) {
    showErrorSnackBar(messenger, l10n, error);
  }
}
