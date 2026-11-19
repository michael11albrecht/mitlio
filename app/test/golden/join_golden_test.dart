import 'package:alchemist/alchemist.dart';
import 'package:mitlio/features/sync/ui/join_view.dart';

import '../features/groups/ui/groups_fixtures.dart';
import '../features/sync/ui/join_fixtures.dart';
import 'golden_matrix.dart';

/// Joining, "Wer bist du?" (plain and with a notice) and the join errors.
Future<void> main() async {
  for (final (name, state) in joinStates) {
    await matrixGolden(
      'join_$name',
      () => scoped(joinStateOverride(state), const JoinView(token: 'tok-test')),
      width: 360,
      height: 640,
      pumpBeforeTest: name == 'joining' ? pumpOnce : onlyPumpAndSettle,
    );
  }
}
