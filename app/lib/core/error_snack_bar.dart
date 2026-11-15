import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Plain words for a failed command: what happened and what to do next.
/// "No silent errors" (CLAUDE.md): a user action that fails always says why.
String repositoryErrorMessage(AppLocalizations l10n, RepositoryError error) =>
    switch (error) {
      NotFound() => l10n.errorNotFound,
      Conflict() => l10n.errorConflict,
      Locked() => l10n.errorLocked,
      InvalidData() => l10n.errorInvalidData,
      Storage() => l10n.errorStorage,
      RateLimited(:final retryAfter) =>
        retryAfter == null
            ? l10n.errorRateLimited
            : l10n.errorRateLimitedIn(_minutes(retryAfter)),
    };

int _minutes(Duration d) => d.inMinutes < 1 ? 1 : d.inMinutes;

/// Shows [error] in a snack bar, replacing one that is still showing.
void showErrorSnackBar(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  RepositoryError error,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(repositoryErrorMessage(l10n, error))),
    );
}
