import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio/features/feedback/data/services/feedback_service.dart';
import 'package:mitlio/features/feedback/data/services/screenshot_picker.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-app feedback (ADR-29): availability, picking screenshots, sending.
abstract interface class FeedbackRepository {
  Future<FeedbackAvailability> availability();

  /// Up to [max] screenshots from the photo picker (empty when cancelled).
  /// A picture over 5 MB is [FeedbackRejected] (`screenshot_too_large`).
  Future<FeedbackResult<List<FeedbackScreenshot>>> pickScreenshots({
    required int max,
  });

  Future<FeedbackResult<void>> submit(FeedbackSubmission submission);
}

class ServiceFeedbackRepository implements FeedbackRepository {
  ServiceFeedbackRepository({
    required this._service,
    required this._picker,
  });

  final FeedbackService _service;
  final ScreenshotPicker _picker;

  @override
  Future<FeedbackAvailability> availability() => _service.availability();

  @override
  Future<FeedbackResult<List<FeedbackScreenshot>>> pickScreenshots({
    required int max,
  }) async {
    final picked = await _picker.pick(max: max);
    if (picked case Ok(:final value)
        when value.any((s) => s.bytes.length > feedbackMaxScreenshotBytes)) {
      return const Err(FeedbackRejected('screenshot_too_large'));
    }
    return picked;
  }

  @override
  Future<FeedbackResult<void>> submit(FeedbackSubmission submission) async {
    // The server checks again; failing here saves the upload of a draft that
    // cannot be accepted.
    if (submission.screenshots.length > feedbackMaxScreenshots) {
      return const Err(FeedbackRejected('too_many_screenshots'));
    }
    if (submission.screenshots.any(
      (s) => s.bytes.length > feedbackMaxScreenshotBytes,
    )) {
      return const Err(FeedbackRejected('screenshot_too_large'));
    }
    return _service.submit(submission);
  }
}
