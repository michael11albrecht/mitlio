import 'package:alchemist/alchemist.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/ui/member_payment_view_model.dart';

import '../features/members/ui/member_payment_fixtures.dart';
import 'golden_matrix.dart';

const _height = 640.0;
const _width = 360.0;

Future<void> main() async {
  Future<void> golden(
    String name,
    MemberPaymentState state, {
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => paymentSheet(state),
    width: _width,
    height: _height,
    pumpBeforeTest: pump,
  );

  await golden(
    'member_payment_loading',
    const MemberPaymentLoading(),
    pump: pumpOnce,
  );
  await golden('member_payment_empty', emptyPayment);
  await golden('member_payment_filled', filledPayment);
  await golden('member_payment_errors', errorsPayment);
  await golden(
    'member_payment_error',
    const MemberPaymentFailure(Storage('x')),
  );
}
