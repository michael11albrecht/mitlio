import 'package:mitlio/features/feedback/data/feedback_providers.dart';
import 'package:mitlio/features/feedback/ui/feedback_view.dart';
import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';

import '../features/feedback/ui/feedback_fixtures.dart';
import '../features/groups/ui/groups_fixtures.dart';
import 'golden_matrix.dart';

/// The feedback form: empty, filled in (two screenshots, app info on), a
/// failed send with the draft kept, and the thank-you state.
Future<void> main() async {
  for (final (name, state) in feedbackStates) {
    await matrixGolden(
      'feedback_$name',
      () => scoped([
        feedbackViewModelProvider.overrideWith(
          () => StubFeedbackViewModel(state),
        ),
        feedbackOsProvider.overrideWithValue('iOS 18.1'),
      ], const FeedbackView()),
      width: 360,
      height: 900,
    );
  }
}
