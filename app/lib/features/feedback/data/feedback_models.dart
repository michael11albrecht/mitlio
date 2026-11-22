// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:typed_data';

import 'package:mitlio_domain/mitlio_domain.dart';

/// Limits of the `submit-feedback` contract (`docs/feedback-api.md`).
const int feedbackMessageMin = 10;
const int feedbackMessageMax = 5000;
const int feedbackMaxScreenshots = 3;
const int feedbackMaxScreenshotBytes = 5 * 1024 * 1024;

/// What the report is about (the three chips).
enum FeedbackType { problem, idea, question }

/// One screenshot the user picked, as PNG/JPEG/WebP bytes.
final class FeedbackScreenshot {
  const FeedbackScreenshot(this.bytes);

  final Uint8List bytes;

  @override
  bool operator ==(Object other) =>
      other is FeedbackScreenshot && _same(other.bytes, bytes);

  @override
  int get hashCode => Object.hash(FeedbackScreenshot, bytes.length);
}

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The opt-in technical details: exactly these three values are sent, and the
/// form shows them before sending.
final class FeedbackDiagnostics {
  const FeedbackDiagnostics({
    required this.appVersion,
    required this.os,
    required this.locale,
  });

  final String appVersion;
  final String os;
  final String locale;

  Map<String, String> toJson() => {
    'appVersion': appVersion,
    'os': os,
    'locale': locale,
  };

  /// One line for the preview under the switch.
  String get preview => '$appVersion · $os · $locale';

  @override
  bool operator ==(Object other) =>
      other is FeedbackDiagnostics &&
      other.appVersion == appVersion &&
      other.os == os &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(appVersion, os, locale);
}

/// A finished report, ready to send.
final class FeedbackSubmission {
  const FeedbackSubmission({
    required this.type,
    required this.message,
    required this.locale,
    this.email = '',
    this.diagnostics,
    this.screenshots = const [],
  });

  final FeedbackType type;
  final String message;

  /// `de` or `en`: the language of the app when the report was written.
  final String locale;
  final String email;
  final FeedbackDiagnostics? diagnostics;
  final List<FeedbackScreenshot> screenshots;
}

/// Whether the backend takes feedback right now.
enum FeedbackAvailability {
  /// The backend said yes.
  available,

  /// The backend said it is not set up (or the build has no backend): the
  /// Settings row stays hidden.
  unavailable,

  /// The probe failed (offline, timeout): the row stays, so the form can be
  /// written and the send shows the real error.
  unknown,
}

/// Why a feedback call failed. One case per user-visible next step
/// (`feedbackErrorText`).
sealed class FeedbackError {
  const FeedbackError();
}

/// The server never answered.
final class FeedbackOffline extends FeedbackError {
  const FeedbackOffline();

  @override
  bool operator ==(Object other) => other is FeedbackOffline;

  @override
  int get hashCode => (FeedbackOffline).hashCode;

  @override
  String toString() => 'FeedbackOffline()';
}

/// Too many reports from this phone; [wait] is the server's hint.
final class FeedbackRateLimited extends FeedbackError {
  const FeedbackRateLimited(this.wait);

  final Duration? wait;

  @override
  bool operator ==(Object other) =>
      other is FeedbackRateLimited && other.wait == wait;

  @override
  int get hashCode => Object.hash(FeedbackRateLimited, wait);

  @override
  String toString() => 'FeedbackRateLimited($wait)';
}

/// The daily cap over all users is used up.
final class FeedbackBusy extends FeedbackError {
  const FeedbackBusy(this.wait);

  final Duration? wait;

  @override
  bool operator ==(Object other) => other is FeedbackBusy && other.wait == wait;

  @override
  int get hashCode => Object.hash(FeedbackBusy, wait);

  @override
  String toString() => 'FeedbackBusy($wait)';
}

/// The server answered that feedback is not set up (503
/// `provider_unconfigured`).
final class FeedbackUnavailable extends FeedbackError {
  const FeedbackUnavailable();

  @override
  bool operator ==(Object other) => other is FeedbackUnavailable;

  @override
  int get hashCode => (FeedbackUnavailable).hashCode;

  @override
  String toString() => 'FeedbackUnavailable()';
}

/// The server answered with a failure on its side.
final class FeedbackServerDown extends FeedbackError {
  const FeedbackServerDown();

  @override
  bool operator ==(Object other) => other is FeedbackServerDown;

  @override
  int get hashCode => (FeedbackServerDown).hashCode;

  @override
  String toString() => 'FeedbackServerDown()';
}

/// The server (or the form itself) refused the content; [code] is the
/// contract's error code (`screenshot_too_large`, `invalid_screenshot`, ...).
final class FeedbackRejected extends FeedbackError {
  const FeedbackRejected(this.code);

  final String code;

  /// A picture is over 5 MB.
  bool get tooLarge =>
      code == 'screenshot_too_large' || code == 'payload_too_large';

  /// A picture is not PNG/JPEG/WebP or there are too many.
  bool get badScreenshot =>
      code == 'invalid_screenshot' || code == 'too_many_screenshots';

  @override
  bool operator ==(Object other) =>
      other is FeedbackRejected && other.code == code;

  @override
  int get hashCode => Object.hash(FeedbackRejected, code);

  @override
  String toString() => 'FeedbackRejected($code)';
}

/// The photo picker failed or a picture could not be read.
final class FeedbackPickFailed extends FeedbackError {
  const FeedbackPickFailed();

  @override
  bool operator ==(Object other) => other is FeedbackPickFailed;

  @override
  int get hashCode => (FeedbackPickFailed).hashCode;

  @override
  String toString() => 'FeedbackPickFailed()';
}

typedef FeedbackResult<T> = Result<T, FeedbackError>;
