import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/app_version.dart';
import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio/features/feedback/data/repositories/feedback_repository.dart';
import 'package:mitlio/features/feedback/data/services/feedback_service.dart';
import 'package:mitlio/features/feedback/data/services/screenshot_picker.dart';

/// No backend by default (no Feedback row); `main` overrides it with the HTTP
/// service when `SUPABASE_URL` is set, tests and DebugDrive with the fake.
final feedbackServiceProvider = Provider<FeedbackService>(
  (ref) => const UnavailableFeedbackService(),
);

/// The system photo picker; tests override it.
final screenshotPickerProvider = Provider<ScreenshotPicker>(
  (ref) => const UnavailableScreenshotPicker(),
);

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => ServiceFeedbackRepository(
    service: ref.watch(feedbackServiceProvider),
    picker: ref.watch(screenshotPickerProvider),
  ),
);

/// Whether the Settings row shows. Resolved once per app run; `unavailable`
/// (no backend, or the server reports it is not set up) hides the row.
final feedbackAvailabilityProvider = FutureProvider<FeedbackAvailability>(
  (ref) => ref.watch(feedbackRepositoryProvider).availability(),
);

/// The phone's OS as one short line for the diagnostics preview.
final feedbackOsProvider = Provider<String>(
  (ref) => sanitizeDiagnostic(
    '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
  ),
);

/// What "App-Infos mitsenden" would send. Only version, OS and the locale.
final feedbackDiagnosticsProvider = Provider<FeedbackDiagnostics>(
  (ref) => FeedbackDiagnostics(
    appVersion: sanitizeDiagnostic(ref.watch(appVersionProvider) ?? 'unknown'),
    os: ref.watch(feedbackOsProvider),
    locale: sanitizeDiagnostic(PlatformDispatcher.instance.locale.toString()),
  ),
);

final _disallowed = RegExp(r'[^\p{L}\p{N} .,+_()/-]', unicode: true);

/// Keeps a value inside what the server accepts (letters, digits and
/// `space . , + _ ( ) / -`, at most 40 characters).
String sanitizeDiagnostic(String value) {
  final clean = value
      .replaceAll(_disallowed, ' ')
      .replaceAll(RegExp(' +'), ' ');
  final trimmed = clean.trim();
  final cut = trimmed.length > 40 ? trimmed.substring(0, 40).trim() : trimmed;
  return cut.isEmpty ? 'unknown' : cut;
}
