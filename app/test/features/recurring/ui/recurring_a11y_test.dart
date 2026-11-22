import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/recurring/ui/recurring_view.dart';
import 'package:mitlio/features/recurring/ui/recurring_view_model.dart';

import '../../../helpers/a11y.dart';
import 'recurring_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  for (final (name, state) in <(String, RecurringState)>[
    ('empty', emptyRecurring),
    ('rules', sampleRecurring),
    ('error', const RecurringFailure(Storage('x'))),
  ]) {
    forEachMode(
      name,
      () => scopedRecurring(state, const RecurringView(groupId: 'g-1')),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
