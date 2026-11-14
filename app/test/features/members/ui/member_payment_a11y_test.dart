import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/ui/member_payment_view_model.dart';

import '../../../helpers/a11y.dart';
import 'member_payment_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  forEachMode(
    'empty form',
    () => paymentSheet(emptyPayment),
    (tester, _, _) => expectAccessible(tester),
  );
  forEachMode(
    'filled form',
    () => paymentSheet(filledPayment),
    (tester, _, _) => expectAccessible(tester),
  );
  forEachMode(
    'inline errors',
    () => paymentSheet(errorsPayment),
    (tester, _, _) => expectAccessible(tester),
  );
  forEachMode(
    'load error',
    () => paymentSheet(const MemberPaymentFailure(Storage('x'))),
    (tester, _, _) => expectAccessible(tester),
  );
}
