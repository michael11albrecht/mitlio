import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/members/ui/member_payment_view.dart';
import 'package:mitlio/features/members/ui/member_payment_view_model.dart';

/// Fixed state for goldens and a11y tests: the ViewModel is replaced by a
/// stub that never touches a repository.
class StubMemberPaymentViewModel extends MemberPaymentViewModel {
  StubMemberPaymentViewModel(super.memberId, this.fixed);

  final MemberPaymentState fixed;

  @override
  MemberPaymentState build() => fixed;
}

List<Override> paymentStateOverride(MemberPaymentState state) => [
  memberPaymentViewModelProvider.overrideWith2(
    (id) => StubMemberPaymentViewModel(id, state),
  ),
];

/// The sheet as a page, the way it appears inside the bottom sheet.
Widget paymentSheet(MemberPaymentState state) => ProviderScope(
  overrides: paymentStateOverride(state),
  child: const Scaffold(
    body: MemberPaymentSheet(memberId: 'm-1', memberName: 'Anna'),
  ),
);

const emptyPayment = MemberPaymentLoaded(
  details: PaymentDetails(memberId: 'm-1'),
);

const filledPayment = MemberPaymentLoaded(
  details: PaymentDetails(
    memberId: 'm-1',
    paypalMe: 'annamuster',
    iban: 'DE89370400440532013000',
    bic: 'COBADEFFXXX',
    accountName: 'Anna Muster',
  ),
);

const errorsPayment = MemberPaymentLoaded(
  details: PaymentDetails(
    memberId: 'm-1',
    paypalMe: 'anna muster',
    iban: 'DE89370400440532013001',
    bic: 'x',
  ),
  fieldErrors: {
    PaymentField.paypalMe: PaymentFieldError.invalid,
    PaymentField.iban: PaymentFieldError.checksum,
    PaymentField.bic: PaymentFieldError.invalid,
  },
);
