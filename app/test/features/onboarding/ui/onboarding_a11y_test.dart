import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/onboarding/ui/onboarding_view.dart';

import '../../../helpers/a11y.dart';
import '../../groups/ui/groups_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  forEachMode(
    'first run',
    () => scoped(const [], const OnboardingView()),
    (tester, _, _) async {
      await expectAccessible(tester);
      // The title is a header for screen readers.
      expect(
        tester.getSemantics(find.text('Willkommen bei mitlio')),
        matchesSemantics(isHeader: true, label: 'Willkommen bei mitlio'),
      );
    },
  );
}
