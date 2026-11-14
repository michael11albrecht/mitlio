import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio/features/settle/ui/transfer_sheet_view_model.dart';

import '../../../helpers/a11y.dart';
import 'settle_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  final screens = <String, SettleState>{
    'to pay and history': sampleSettle,
    'settled': settledSettle,
    'no entries': emptySettle,
    'error': const SettleFailure(Storage('x')),
  };
  for (final MapEntry(:key, :value) in screens.entries) {
    forEachMode(
      key,
      () => scopedSettle(settleStateOverride(value), settleView),
      (tester, _, _) => expectAccessible(tester),
    );
  }

  final sheets = <String, TransferSheetState>{
    'sheet with QR': sheetFull,
    'sheet partial payment': sheetPartial,
    'sheet without details': sheetNoDetails,
    'sheet amount too high': sheetTooHigh,
  };
  for (final MapEntry(:key, :value) in sheets.entries) {
    forEachMode(
      key,
      () => scopedSettle(sheetStateOverride(value), transferSheet),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
