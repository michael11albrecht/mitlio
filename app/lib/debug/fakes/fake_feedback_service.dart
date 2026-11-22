import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio/features/feedback/data/services/feedback_service.dart';
import 'package:mitlio/features/feedback/data/services/screenshot_picker.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory feedback backend for tests and DebugDrive: accepts everything
/// unless told to fail, and keeps what was sent.
class FakeFeedbackService implements FeedbackService {
  FakeFeedbackService({
    this.availabilityResult = FeedbackAvailability.available,
  });

  FeedbackAvailability availabilityResult;

  /// When set, `submit` fails with it (the draft must survive).
  FeedbackError? failWith;

  /// Everything the server "accepted", oldest first.
  final List<FeedbackSubmission> sent = [];

  @override
  Future<FeedbackAvailability> availability() async => availabilityResult;

  @override
  Future<FeedbackResult<void>> submit(FeedbackSubmission submission) async {
    final error = failWith;
    if (error != null) return Err(error);
    sent.add(submission);
    return const Ok(null);
  }
}

/// Hands out the pictures it was given, or fails.
class FakeScreenshotPicker implements ScreenshotPicker {
  FakeScreenshotPicker([this.next = const []]);

  List<FeedbackScreenshot> next;
  FeedbackError? failWith;

  @override
  Future<FeedbackResult<List<FeedbackScreenshot>>> pick({
    required int max,
  }) async {
    final error = failWith;
    if (error != null) return Err(error);
    return Ok(next.take(max).toList());
  }
}
