import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Plain, du-form words for a failed feedback call: what happened and what to
/// do next ("No silent errors", CLAUDE.md). Offline is said only when the
/// server never answered.
String feedbackErrorText(AppLocalizations l10n, FeedbackError error) =>
    switch (error) {
      FeedbackOffline() => l10n.feedbackErrorOffline,
      FeedbackRateLimited(:final wait) =>
        wait == null
            ? l10n.feedbackErrorRateLimited
            : l10n.feedbackErrorRateLimitedIn(_minutes(wait)),
      FeedbackBusy() => l10n.feedbackErrorBusy,
      FeedbackUnavailable() => l10n.feedbackErrorUnavailable,
      FeedbackServerDown() => l10n.feedbackErrorServer,
      FeedbackRejected(:final tooLarge) when tooLarge =>
        l10n.feedbackErrorTooLarge,
      FeedbackRejected(:final badScreenshot) when badScreenshot =>
        l10n.feedbackErrorBadScreenshot,
      FeedbackRejected() => l10n.feedbackErrorRejected,
      FeedbackPickFailed() => l10n.feedbackErrorPick,
    };

int _minutes(Duration d) => d.inMinutes < 1 ? 1 : d.inMinutes;
