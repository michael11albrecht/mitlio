import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/feedback/data/feedback_providers.dart';
import 'package:mitlio/features/feedback/ui/feedback_view.dart';
import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';

import '../../../helpers/a11y.dart';
import 'feedback_fixtures.dart';

void main() {
  for (final (name, state) in feedbackStates) {
    forEachMode(
      'feedback $name',
      () => ProviderScope(
        overrides: [
          feedbackViewModelProvider.overrideWith(
            () => StubFeedbackViewModel(state),
          ),
          feedbackOsProvider.overrideWithValue('iOS 18.1'),
        ],
        child: const FeedbackView(),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
