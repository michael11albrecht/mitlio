import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio/features/feedback/data/feedback_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

// The views read these types through this file (views never import data/).
export 'package:mitlio/features/feedback/data/feedback_models.dart'
    show
        FeedbackAvailability,
        FeedbackBusy,
        FeedbackDiagnostics,
        FeedbackError,
        FeedbackOffline,
        FeedbackPickFailed,
        FeedbackRateLimited,
        FeedbackRejected,
        FeedbackScreenshot,
        FeedbackServerDown,
        FeedbackType,
        FeedbackUnavailable,
        feedbackMessageMax;

enum FeedbackStatus { editing, sending, sent }

final _emailPattern = RegExp(
  r'^[^\s@<>(),;:"\[\]\\]+@[^\s@<>(),;:"\[\]\\]+\.[^\s@<>(),;:"\[\]\\]{2,}$',
);

/// The report being written. Survives a failed send (nothing is cleared until
/// the server accepted it) and leaving the screen.
final class FeedbackState {
  const FeedbackState({
    this.type,
    this.message = '',
    this.email = '',
    this.screenshots = const [],
    this.includeDiagnostics = false,
    this.status = FeedbackStatus.editing,
    this.error,
  });

  final FeedbackType? type;
  final String message;
  final String email;
  final List<FeedbackScreenshot> screenshots;
  final bool includeDiagnostics;
  final FeedbackStatus status;

  /// The failure of the last pick or send, until the next edit.
  final FeedbackError? error;

  int get messageLength => message.trim().runes.length;

  bool get messageValid =>
      messageLength >= feedbackMessageMin &&
      message.trim().length <= feedbackMessageMax;

  /// Empty is fine (a reply is optional); a typed address has to look like one.
  bool get emailValid =>
      email.trim().isEmpty || _emailPattern.hasMatch(email.trim());

  bool get canAddScreenshot =>
      screenshots.length < feedbackMaxScreenshots &&
      status == FeedbackStatus.editing;

  bool get canSubmit =>
      status == FeedbackStatus.editing &&
      type != null &&
      messageValid &&
      emailValid;

  FeedbackState copyWith({
    FeedbackType? type,
    String? message,
    String? email,
    List<FeedbackScreenshot>? screenshots,
    bool? includeDiagnostics,
    FeedbackStatus? status,
    FeedbackError? error,
  }) => FeedbackState(
    type: type ?? this.type,
    message: message ?? this.message,
    email: email ?? this.email,
    screenshots: screenshots ?? this.screenshots,
    includeDiagnostics: includeDiagnostics ?? this.includeDiagnostics,
    status: status ?? this.status,
    error: error,
  );

  Map<String, Object?> toJson() => {
    'type': type?.name,
    'messageLength': messageLength,
    'hasEmail': email.trim().isNotEmpty,
    'screenshots': screenshots.length,
    'includeDiagnostics': includeDiagnostics,
    'canSubmit': canSubmit,
    'status': status.name,
    'error': error?.toString(),
  };
}

/// "Feedback" (ADR-29, P7-T10): every action of the form is a command here;
/// DebugDrive (`ext.mitlio.feedback.*`) and the screen call the same ones.
class FeedbackViewModel extends Notifier<FeedbackState> {
  @override
  FeedbackState build() => const FeedbackState();

  void setType(FeedbackType type) {
    if (state.status != FeedbackStatus.editing) return;
    state = state.copyWith(type: type);
  }

  void setMessage(String message) {
    if (state.status != FeedbackStatus.editing) return;
    state = state.copyWith(message: message);
  }

  void setEmail(String email) {
    if (state.status != FeedbackStatus.editing) return;
    state = state.copyWith(email: email);
  }

  void setIncludeDiagnostics({required bool include}) {
    if (state.status != FeedbackStatus.editing) return;
    state = state.copyWith(includeDiagnostics: include);
  }

  /// What "App-Infos mitsenden" would send, for the preview under the switch.
  FeedbackDiagnostics get diagnostics => ref.read(feedbackDiagnosticsProvider);

  /// Opens the photo picker for the free slots. Returns the failure, if any
  /// (also kept in [FeedbackState.error]).
  Future<FeedbackResult<void>> addScreenshots() async {
    if (!state.canAddScreenshot) {
      return const Err(FeedbackRejected('too_many_screenshots'));
    }
    final free = feedbackMaxScreenshots - state.screenshots.length;
    final picked = await ref
        .read(feedbackRepositoryProvider)
        .pickScreenshots(max: free);
    if (!ref.mounted) return const Ok(null);
    switch (picked) {
      case Ok(:final value):
        return addPicked(value);
      case Err(:final error):
        state = state.copyWith(error: error);
        return Err(error);
    }
  }

  /// Adds already read pictures (the picker result; DebugDrive passes bytes
  /// directly). Extra pictures beyond the free slots are ignored.
  FeedbackResult<void> addPicked(List<FeedbackScreenshot> pictures) {
    if (state.status != FeedbackStatus.editing) {
      return const Err(FeedbackRejected('too_many_screenshots'));
    }
    final free = feedbackMaxScreenshots - state.screenshots.length;
    if (pictures.any((p) => p.bytes.length > feedbackMaxScreenshotBytes)) {
      const error = FeedbackRejected('screenshot_too_large');
      state = state.copyWith(error: error);
      return const Err(error);
    }
    state = state.copyWith(
      screenshots: [...state.screenshots, ...pictures.take(free)],
    );
    return const Ok(null);
  }

  void removeScreenshot(int index) {
    if (state.status != FeedbackStatus.editing ||
        index < 0 ||
        index >= state.screenshots.length) {
      return;
    }
    state = state.copyWith(
      screenshots: [...state.screenshots]..removeAt(index),
    );
  }

  /// Sends the report. On success the draft is cleared and the status is
  /// `sent`; on failure the draft stays and [FeedbackState.error] says why.
  Future<FeedbackResult<void>> submit({required String locale}) async {
    final type = state.type;
    if (!state.canSubmit || type == null) {
      return const Err(FeedbackRejected('invalid'));
    }
    final draft = state;
    state = draft.copyWith(status: FeedbackStatus.sending);
    final result = await ref
        .read(feedbackRepositoryProvider)
        .submit(
          FeedbackSubmission(
            type: type,
            message: draft.message.trim(),
            email: draft.email.trim(),
            locale: locale,
            diagnostics: draft.includeDiagnostics ? diagnostics : null,
            screenshots: draft.screenshots,
          ),
        );
    if (ref.mounted) {
      state = switch (result) {
        Ok() => const FeedbackState(status: FeedbackStatus.sent),
        Err(:final error) => draft.copyWith(
          status: FeedbackStatus.editing,
          error: error,
        ),
      };
    }
    return result;
  }

  /// Back to an empty form (after the thank-you state, or for a new report).
  void reset() => state = const FeedbackState();
}

final NotifierProvider<FeedbackViewModel, FeedbackState>
feedbackViewModelProvider = NotifierProvider<FeedbackViewModel, FeedbackState>(
  FeedbackViewModel.new,
);

/// Whether Settings shows the Feedback row: only once the server has said
/// that feedback is set up (or could not be asked, e.g. offline). Hidden
/// while the first answer is pending, without a backend, and while the owner
/// has not stored the GitHub token (the function then answers 503).
final Provider<bool> feedbackEntryVisibleProvider = Provider<bool>((ref) {
  final availability = ref.watch(feedbackAvailabilityProvider).value;
  return availability != null &&
      availability != FeedbackAvailability.unavailable;
});
