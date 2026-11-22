import 'package:mitlio/features/rides/ui/commute_template_view.dart';

import '../../../helpers/a11y.dart';
import 'rides_fixtures.dart';

/// Contrast, tap targets, labels and overflow of every commute template
/// step, light and dark at text scale 1.0 and 2.0.
void main() {
  for (final (name, step, finished) in [
    ('name step', 0, false),
    ('route step', 1, false),
    ('car step', 2, false),
    ('people step', 3, false),
    ('tolls step', 4, false),
    ('finish screen', 4, true),
  ]) {
    forEachMode(
      name,
      () => scopedRides([
        ...setupStateOverride(setupData),
        ...commuteProgress(step: step, finished: finished),
      ], const CommuteTemplateView(groupId: 'g-1')),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
