import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/feedback/data/feedback_providers.dart';
import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A 1x1 PNG: the default picture of `feedback.addScreenshot`.
final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// `ext.mitlio.feedback.*` (ADR-29, P7-T10; keys without the `ext.mitlio.`
/// prefix): thin wrappers over `FeedbackViewModel`, the commands the form
/// uses. Nothing here talks to the network except `feedback.submit`, which
/// goes through the same repository the screen uses.
Map<String, DriveHandler> feedbackDriveHandlers(ProviderContainer c) {
  FeedbackViewModel vm() => c.read(feedbackViewModelProvider.notifier);
  DriveResult state() => c.read(feedbackViewModelProvider).toJson();

  return {
    'feedback.available': (_) async => {
      'availability':
          (await c
                  .read(
                    feedbackRepositoryProvider,
                  )
                  .availability())
              .name,
    },
    'feedback.state': (_) async => state(),
    'feedback.draft': (p) async {
      final type = p['type'];
      if (type != null) {
        final parsed = FeedbackType.values.asNameMap()[type];
        if (parsed == null) return invalidParams('unknown type: $type');
        vm().setType(parsed);
      }
      final message = p['message'];
      if (message != null) vm().setMessage(message);
      final email = p['email'];
      if (email != null) vm().setEmail(email);
      final diagnostics = p['diagnostics'];
      if (diagnostics != null) {
        vm().setIncludeDiagnostics(include: diagnostics == 'true');
      }
      return state();
    },
    'feedback.diagnostics': (_) async => {
      ...c.read(feedbackDiagnosticsProvider).toJson(),
      'preview': c.read(feedbackDiagnosticsProvider).preview,
    },
    'feedback.addScreenshot': (p) async {
      final data = p['data'];
      final bytes = data == null ? _pixel : base64Decode(data);
      final result = vm().addPicked([FeedbackScreenshot(bytes)]);
      return switch (result) {
        Ok() => state(),
        Err(:final error) => _driveError(error),
      };
    },
    'feedback.removeScreenshot': (p) async {
      final index = int.tryParse(p['index'] ?? '');
      if (index == null) return invalidParams('index must be an integer');
      vm().removeScreenshot(index);
      return state();
    },
    'feedback.submit': (p) async {
      final result = await vm().submit(locale: p['locale'] ?? 'de');
      return switch (result) {
        Ok() => {'sent': true, ...state()},
        Err(:final error) => _driveError(error),
      };
    },
    'feedback.reset': (_) async {
      vm().reset();
      return state();
    },
  };
}

/// The `{error, message}` convention: `invalid_params` (the content was
/// refused), `rate_limited`, `unavailable` (not set up) or `internal`
/// (offline, server down, picker).
DriveResult _driveError(FeedbackError error) => {
  'error': switch (error) {
    FeedbackRejected() => 'invalid_params',
    FeedbackRateLimited() || FeedbackBusy() => 'rate_limited',
    FeedbackUnavailable() => 'unavailable',
    FeedbackOffline() ||
    FeedbackServerDown() ||
    FeedbackPickFailed() => 'internal',
  },
  'message': error.toString(),
};
