import 'package:image_picker/image_picker.dart';
import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The system photo picker. Only the pictures the user taps are readable (no
/// library permission); nothing leaves the phone before "Senden".
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class ScreenshotPicker {
  /// Up to [max] pictures; an empty list when the user cancels.
  Future<FeedbackResult<List<FeedbackScreenshot>>> pick({required int max});
}

/// No picker (Linux harness, tests): the add button reports it.
class UnavailableScreenshotPicker implements ScreenshotPicker {
  const UnavailableScreenshotPicker();

  @override
  Future<FeedbackResult<List<FeedbackScreenshot>>> pick({
    required int max,
  }) async => const Err(FeedbackPickFailed());
}

/// `image_picker` (PHPicker on iOS, the photo picker on Android). Pictures are
/// scaled down and re-encoded as JPEG, so they stay far below the 5 MB limit.
class ImagePickerScreenshotPicker implements ScreenshotPicker {
  ImagePickerScreenshotPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<FeedbackResult<List<FeedbackScreenshot>>> pick({
    required int max,
  }) async {
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        limit: max,
      );
      return Ok([
        for (final f in files.take(max))
          FeedbackScreenshot(await f.readAsBytes()),
      ]);
    } on Object {
      return const Err(FeedbackPickFailed());
    }
  }
}
