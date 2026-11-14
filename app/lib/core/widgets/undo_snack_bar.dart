import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Tells what happened and offers "Undo" (plan §2.6: undo instead of confirm
/// dialogs). Replaces a snack bar that is still showing. Uses the app-level
/// messenger, so it survives a navigation right after the command.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required Undo undo,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: AppLocalizations.of(context).undo,
          onPressed: () => unawaited(undo()),
        ),
      ),
    );
}
