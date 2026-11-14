import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';

import '../../repo_test_support.dart';

const testIban = 'DE89370400440532013000';

/// A [PaymentDetailsRepository] with the members repository it writes to.
typedef PaymentRepos = ({Repos base, PaymentDetailsRepository payments});

/// Behaviour every `PaymentDetailsRepository` must show.
void runPaymentDetailsRepositoryContract(
  String name,
  Future<PaymentRepos> Function() create,
) {
  group('PaymentDetailsRepository contract ($name)', () {
    late PaymentRepos r;
    late String annId;

    setUp(() async {
      r = await create();
      annId = (await seedGroup(r.base)).members.first.id;
    });

    test('a member without details has empty details', () async {
      expect(
        ok(await r.payments.get(annId)),
        PaymentDetails(memberId: annId),
      );
    });

    test('get of an unknown member is NotFound', () async {
      expect(err(await r.payments.get('nope')), isA<NotFound>());
    });

    test('save normalises and returns the details', () async {
      final saved = ok(
        await r.payments.save(
          annId,
          paypalMe: ' @AnnMuster ',
          iban: 'de89 3704 0044 0532 0130 00',
          bic: 'cobadeffxxx',
          accountName: ' Ann Muster ',
        ),
      );
      expect(saved.paypalMe, 'AnnMuster');
      expect(saved.iban, testIban);
      expect(saved.bic, 'COBADEFFXXX');
      expect(saved.accountName, 'Ann Muster');
      expect(ok(await r.payments.get(annId)), saved);
    });

    test('the synced member carries the handle and a masked hint', () async {
      ok(
        await r.payments.save(annId, paypalMe: 'ann', iban: testIban),
      );
      final ann = ok(
        await r.base.members.list((await seedGroupId(r.base)) ?? ''),
      ).where((m) => m.id == annId);
      expect(ann.single.paypalMe, 'ann');
      expect(ann.single.ibanHint, 'DE89 •••• 3000');
      expect(ann.single.ibanHint, isNot(contains('0532')));
    });

    test('saving again replaces; blank fields clear them', () async {
      ok(
        await r.payments.save(
          annId,
          paypalMe: 'ann',
          iban: testIban,
          bic: 'COBADEFFXXX',
          accountName: 'Ann',
        ),
      );
      final cleared = ok(
        await r.payments.save(annId, paypalMe: '  ', iban: ''),
      );
      expect(cleared, PaymentDetails(memberId: annId));
      expect(ok(await r.payments.get(annId)), PaymentDetails(memberId: annId));
    });

    test('a PayPal handle alone needs no IBAN', () async {
      final saved = ok(await r.payments.save(annId, paypalMe: 'ann'));
      expect(saved.iban, isNull);
      expect(saved.ibanHint, isNull);
    });

    test('invalid input names the fields, never their content', () async {
      final e = err(
        await r.payments.save(
          annId,
          paypalMe: 'not a handle',
          iban: 'DE89370400440532013001',
          bic: 'x',
        ),
      );
      expect(e, isA<InvalidData>());
      final text = e.toString();
      expect(text, contains('paypalMe'));
      expect(text, contains('iban'));
      expect(text, contains('bic'));
      expect(text, isNot(contains('DE89')));
      expect(text, isNot(contains('not a handle')));
    });

    test('invalid input stores nothing', () async {
      ok(await r.payments.save(annId, paypalMe: 'ann'));
      expect(
        err(await r.payments.save(annId, paypalMe: 'bob', iban: 'DE00')),
        isA<InvalidData>(),
      );
      expect(ok(await r.payments.get(annId)).paypalMe, 'ann');
    });

    test('save for an unknown member is NotFound', () async {
      expect(
        err(await r.payments.save('nope', paypalMe: 'ann')),
        isA<NotFound>(),
      );
    });
  });
}

/// The id of the only group in [r].
Future<String?> seedGroupId(Repos r) async {
  final groups = await r.groups.watchGroups().first;
  return groups.isEmpty ? null : groups.first.id;
}
