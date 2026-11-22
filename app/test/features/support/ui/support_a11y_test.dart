import 'package:mitlio/features/support/ui/tip_jar_view_model.dart';

import '../../../helpers/a11y.dart';
import 'support_fixtures.dart';

void main() {
  final states = <String, TipJarState>{
    'sizes': const TipJarReady(tipProducts),
    'purchase failed': const TipJarReady(
      tipProducts,
      error: TipFailure.purchaseFailed,
    ),
    'store unavailable': const TipJarUnavailable(TipFailure.storeUnavailable),
    'thanks': const TipJarThanks(),
  };
  for (final e in states.entries) {
    forEachMode(
      'tip jar sheet ${e.key}',
      () => tipJarSheet(e.value),
      (tester, _, _) => expectAccessible(tester),
    );
  }

  forEachMode(
    'success-screen line',
    promptLine,
    (tester, _, _) => expectAccessible(tester),
  );
}
