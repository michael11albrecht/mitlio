import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/members/ui/member_payment_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

const _iban = 'DE89370400440532013000';

/// Payments fake whose commands can be made to fail.
class _FlakyPayments implements PaymentDetailsRepository {
  _FlakyPayments(this._inner);

  final PaymentDetailsRepository _inner;
  RepositoryError? failGet;
  RepositoryError? failSave;

  @override
  Future<RepoResult<PaymentDetails>> get(String memberId) async =>
      failGet != null ? Err(failGet!) : _inner.get(memberId);

  @override
  Future<RepoResult<PaymentDetails>> save(
    String memberId, {
    String? paypalMe,
    String? iban,
    String? bic,
    String? accountName,
  }) async => failSave != null
      ? Err(failSave!)
      : _inner.save(
          memberId,
          paypalMe: paypalMe,
          iban: iban,
          bic: bic,
          accountName: accountName,
        );
}

void main() {
  late FakeApp app;
  late _FlakyPayments payments;
  late ProviderContainer container;
  late String annId;

  MemberPaymentViewModel vm() =>
      container.read(memberPaymentViewModelProvider(annId).notifier);
  MemberPaymentState state() =>
      container.read(memberPaymentViewModelProvider(annId));
  MemberPaymentLoaded loaded() => state() as MemberPaymentLoaded;

  Future<void> open() async {
    container.listen(memberPaymentViewModelProvider(annId), (_, _) {});
    await pumpEventQueue();
  }

  setUp(() async {
    app = FakeApp();
    payments = _FlakyPayments(app.payments);
    final g = ok(
      await app.groups.create(
        name: 'Trip',
        currency: eur,
        createdBy: 'dev',
      ),
    );
    annId = ok(await app.members.add(g.id, name: 'Ann')).id;
    container = ProviderContainer(
      overrides: app.overridesWith(payments: payments),
    );
    addTearDown(container.dispose);
  });

  test('starts loading, then shows empty details', () async {
    container.listen(memberPaymentViewModelProvider(annId), (_, _) {});
    expect(state(), isA<MemberPaymentLoading>());
    await pumpEventQueue();
    expect(loaded().details, PaymentDetails(memberId: annId));
    expect(vm().debugSnapshot(), {
      'status': 'data',
      'memberId': annId,
      'paypalMe': null,
      'ibanHint': null,
      'hasIban': false,
      'hasBic': false,
      'hasAccountName': false,
      'fieldErrors': <String, String>{},
      'saveError': null,
    });
  });

  test('loading failure is shown and retry loads again', () async {
    payments.failGet = const Storage('x');
    container.listen(memberPaymentViewModelProvider(annId), (_, _) {});
    await pumpEventQueue();
    expect(state(), isA<MemberPaymentFailure>());
    expect(vm().debugSnapshot()['status'], 'error');
    payments.failGet = null;
    vm().retry();
    expect(state(), isA<MemberPaymentLoading>());
    expect(vm().debugSnapshot()['status'], 'loading');
    await pumpEventQueue();
    expect(state(), isA<MemberPaymentLoaded>());
  });

  group('save', () {
    test('stores normalised details', () async {
      await open();
      final saved = ok(
        await vm().save(
          paypalMe: '@ann',
          iban: 'de89 3704 0044 0532 0130 00',
          bic: 'cobadeffxxx',
          accountName: 'Ann',
        ),
      );
      expect(saved.iban, _iban);
      expect(loaded().details, saved);
      expect(loaded().fieldErrors, isEmpty);
    });

    test('the snapshot never contains IBAN, BIC or account name', () async {
      await open();
      ok(
        await vm().save(
          paypalMe: 'ann',
          iban: _iban,
          bic: 'COBADEFFXXX',
          accountName: 'Ann Muster',
        ),
      );
      final snapshot = vm().debugSnapshot();
      expect(snapshot['ibanHint'], 'DE89 •••• 3000');
      expect(snapshot['hasIban'], isTrue);
      expect(snapshot['hasBic'], isTrue);
      expect(snapshot['hasAccountName'], isTrue);
      final text = snapshot.toString();
      expect(text, isNot(contains('DE89370400')));
      expect(text, isNot(contains('0532013000')));
      expect(text, isNot(contains('COBADEFFXXX')));
      expect(text, isNot(contains('Ann Muster')));
    });

    test('invalid input sets inline errors and stores nothing', () async {
      await open();
      final e = err(
        await vm().save(
          paypalMe: 'no handle',
          iban: 'DE89370400440532013001',
          bic: 'x',
        ),
      );
      expect(e, isA<InvalidData>());
      expect(loaded().fieldErrors, {
        PaymentField.paypalMe: PaymentFieldError.invalid,
        PaymentField.iban: PaymentFieldError.checksum,
        PaymentField.bic: PaymentFieldError.invalid,
      });
      expect(loaded().details, PaymentDetails(memberId: annId));
      expect(vm().debugSnapshot()['fieldErrors'], {
        'paypalMe': 'invalid',
        'iban': 'checksum',
        'bic': 'invalid',
      });
      expect(ok(await app.payments.get(annId)).paypalMe, isNull);
    });

    test('fixing the input clears the errors', () async {
      await open();
      err(await vm().save(iban: 'DE89'));
      expect(loaded().fieldErrors, isNotEmpty);
      ok(await vm().save(iban: _iban));
      expect(loaded().fieldErrors, isEmpty);
    });

    test('blank input clears stored details', () async {
      await open();
      ok(await vm().save(paypalMe: 'ann', iban: _iban));
      ok(await vm().save());
      expect(loaded().details, PaymentDetails(memberId: annId));
    });

    test('a repository failure is kept as saveError', () async {
      await open();
      ok(await vm().save(paypalMe: 'ann'));
      payments.failSave = const Storage('x');
      expect(err(await vm().save(paypalMe: 'bob')), isA<Storage>());
      expect(loaded().saveError, const Storage('x'));
      expect(loaded().details.paypalMe, 'ann');
      expect(vm().debugSnapshot()['saveError'], isNotNull);
    });

    test('before the details are loaded it is refused', () async {
      expect(err(await vm().save(paypalMe: 'ann')), isA<InvalidData>());
    });
  });

  test(
    'the state is dropped once nobody listens (no IBAN in memory)',
    () async {
      final sub = container.listen(
        memberPaymentViewModelProvider(annId),
        (_, _) {},
      );
      await pumpEventQueue();
      ok(await vm().save(iban: _iban));
      sub.close();
      await pumpEventQueue();
      expect(state(), isA<MemberPaymentLoading>());
    },
  );
}
