import 'package:alchemist/alchemist.dart';
import 'package:mitlio/features/support/ui/tip_jar_view_model.dart';

import '../features/support/ui/support_fixtures.dart';
import 'golden_matrix.dart';

const _width = 360.0;

Future<void> main() async {
  Future<void> sheet(
    String name,
    TipJarState state, {
    double height = 420,
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => tipJarSheet(state),
    width: _width,
    height: height,
    pumpBeforeTest: pump,
  );

  await sheet('support_sheet_loading', const TipJarLoading(), pump: pumpOnce);
  await sheet('support_sheet_sizes', const TipJarReady(tipProducts));
  await sheet(
    'support_sheet_buying',
    const TipJarReady(tipProducts, buying: TipSize.medium),
    pump: pumpOnce,
  );
  await sheet(
    'support_sheet_failed',
    const TipJarReady(tipProducts, error: TipFailure.purchaseFailed),
    height: 520,
  );
  await sheet(
    'support_sheet_store_unavailable',
    const TipJarUnavailable(TipFailure.storeUnavailable),
    height: 560,
  );
  await sheet('support_sheet_thanks', const TipJarThanks());
  await matrixGolden(
    'support_prompt_line',
    promptLine,
    width: _width,
    height: 320,
  );
}
