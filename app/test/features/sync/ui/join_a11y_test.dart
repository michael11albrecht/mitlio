import 'package:mitlio/features/sync/ui/join_view.dart';

import '../../../helpers/a11y.dart';
import '../../groups/ui/groups_fixtures.dart';
import 'join_fixtures.dart';

/// Contrast, labelled and large-enough tap targets for every join state, in
/// light/dark and at text scale 1.0 and 2.0 (plan §2.6).
void main() {
  // "joining" is a spinner that never settles and has no controls.
  for (final (name, state) in joinStates.where((s) => s.$1 != 'joining')) {
    forEachMode(
      name,
      () => scoped(joinStateOverride(state), const JoinView(token: 'tok-test')),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
