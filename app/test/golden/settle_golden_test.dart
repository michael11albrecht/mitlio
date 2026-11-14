import 'package:alchemist/alchemist.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio/features/settle/ui/transfer_sheet_view_model.dart';

import '../features/settle/ui/settle_fixtures.dart';
import 'golden_matrix.dart';

const _width = 360.0;

Future<void> main() async {
  Future<void> list(
    String name,
    SettleState state, {
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => scopedSettle(settleStateOverride(state), settleView),
    width: _width,
    height: 760,
    pumpBeforeTest: pump,
  );

  Future<void> sheet(String name, TransferSheetState state, double height) =>
      matrixGolden(
        name,
        () => scopedSettle(sheetStateOverride(state), transferSheet),
        width: _width,
        height: height,
      );

  await list('settle_loading', const SettleLoading(), pump: pumpOnce);
  await list('settle_error', const SettleFailure(Storage('x')));
  await list('settle_data', sampleSettle);
  await list('settle_settled', settledSettle);
  await list('settle_empty', emptySettle);
  // The sheet is shown at its natural size, at scale 2.0 it scrolls.
  await sheet('settle_sheet_qr', sheetFull, 900);
  await sheet('settle_sheet_partial', sheetPartial, 520);
  await sheet('settle_sheet_no_details', sheetNoDetails, 420);
  await sheet('settle_sheet_too_high', sheetTooHigh, 420);
}
