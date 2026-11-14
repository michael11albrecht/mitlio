import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/balances/ui/balances_view.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';

import '../features/balances/ui/balances_fixtures.dart';
import 'golden_matrix.dart';

const _height = 760.0;
const _width = 360.0;

Widget _view(BalancesState s) => scopedBalances(
  balancesStateOverride(s),
  const BalancesView(groupId: 'g-1'),
);

Future<void> main() async {
  Future<void> golden(
    String name,
    BalancesState state, {
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => _view(state),
    width: _width,
    height: _height,
    pumpBeforeTest: pump,
  );

  await golden('balances_loading', const BalancesLoading(), pump: pumpOnce);
  await golden('balances_empty', emptyBalances);
  await golden('balances_error', const BalancesFailure(Storage('x')));
  await golden('balances_data', sampleBalances);
  await golden('balances_direct', samplePairwise);
  await golden('balances_settled', settledBalances);
}
