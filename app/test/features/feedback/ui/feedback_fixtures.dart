import 'dart:convert';
import 'dart:typed_data';

import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';

/// A real 1x1 PNG (the server sniffs the bytes, and the thumbnails decode it).
final Uint8List pngPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Fixed state for goldens and a11y tests, never touches a repository.
class StubFeedbackViewModel extends FeedbackViewModel {
  StubFeedbackViewModel(this.fixed);

  final FeedbackState fixed;

  @override
  FeedbackState build() => fixed;
}

const _message = 'Beim Abrechnen der Fahrt steht ein falscher Betrag da.';

final feedbackStates = <(String, FeedbackState)>[
  ('empty', const FeedbackState()),
  (
    'filled',
    FeedbackState(
      type: FeedbackType.problem,
      message: _message,
      email: 'mia@example.org',
      screenshots: [FeedbackScreenshot(pngPixel), FeedbackScreenshot(pngPixel)],
      includeDiagnostics: true,
    ),
  ),
  (
    'offline',
    const FeedbackState(
      type: FeedbackType.idea,
      message: _message,
      error: FeedbackOffline(),
    ),
  ),
  ('sent', const FeedbackState(status: FeedbackStatus.sent)),
];
