import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/balances/ui/balances_view.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';

import '../../../helpers/a11y.dart';
import 'balances_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  const view = BalancesView(groupId: 'g-1');
  final states = <String, BalancesState>{
    'simplified': sampleBalances,
    'direct': samplePairwise,
    'settled': settledBalances,
    'no entries': emptyBalances,
    'error': const BalancesFailure(Storage('x')),
  };
  for (final MapEntry(:key, :value) in states.entries) {
    forEachMode(
      key,
      () => scopedBalances(balancesStateOverride(value), view),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
