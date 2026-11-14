import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/payment.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart' show eur, ok;
import '../helpers/fake_app.dart';

const _iban = 'DE89370400440532013000';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;
  late String groupId;
  late String annId;
  late String benId;

  setUp(() async {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
    h = paymentDriveHandlers(container);
    final g = ok(
      await app.groups.create(
        name: 'Trip',
        currency: eur,
        createdBy: 'dev',
      ),
    );
    groupId = g.id;
    annId = ok(await app.members.add(groupId, name: 'Ann')).id;
    benId = ok(await app.members.add(groupId, name: 'Ben')).id;
  });

  group('members.setPayment', () {
    test('stores details and answers with the masked hint only', () async {
      final r = await h['members.setPayment']!({
        'memberId': annId,
        'paypalMe': '@ann',
        'iban': 'de89 3704 0044 0532 0130 00',
        'bic': 'COBADEFFXXX',
        'accountName': 'Ann Muster',
      });
      expect(r, {
        'memberId': annId,
        'paypalMe': 'ann',
        'ibanHint': 'DE89 •••• 3000',
        'hasIban': true,
      });
      final text = jsonEncode(r);
      expect(text, isNot(contains('0532')));
      expect(text, isNot(contains('COBADEFFXXX')));
      expect(ok(await app.payments.get(annId)).iban, _iban);
    });

    test('validates params and input', () async {
      expect(
        (await h['members.setPayment']!({}))['error'],
        'invalid_params',
      );
      final bad = await h['members.setPayment']!({
        'memberId': annId,
        'iban': 'DE89370400440532013001',
      });
      expect(bad['error'], 'invalid_params');
      expect(jsonEncode(bad), isNot(contains('DE89')));
      expect(
        (await h['members.setPayment']!({
          'memberId': 'nope',
          'paypalMe': 'ann',
        }))['error'],
        'not_found',
      );
    });
  });

  group('payment.links', () {
    Future<void> setUpAnn() async {
      await h['members.setPayment']!({
        'memberId': annId,
        'paypalMe': 'ann',
        'iban': _iban,
        'accountName': 'Ann Muster',
      });
    }

    test('returns PayPal.Me link and EPC payload for the creditor', () async {
      await setUpAnn();
      final r = await h['payment.links']!({
        'fromId': benId,
        'toId': annId,
        'amountCents': '1234',
      });
      expect(r['paypalUrl'], 'https://paypal.me/ann/12.34EUR');
      expect(
        r['epcPayload'],
        'BCD\n002\n1\nSCT\n\nAnn Muster\n$_iban\nEUR12.34\n\n\nmitlio: Trip',
      );
      expect(r['paypalError'], isNull);
      expect(r['epcError'], isNull);
    });

    test('has nothing for a creditor without payment details', () async {
      final r = await h['payment.links']!({
        'fromId': annId,
        'toId': benId,
        'amountCents': '500',
      });
      expect(r, {
        'paypalUrl': null,
        'paypalError': null,
        'epcPayload': null,
        'epcError': null,
      });
    });

    test('non-EUR groups get a PayPal link but no EPC payload', () async {
      final chf = ok(
        await app.groups.create(
          name: 'Ski',
          currency: Currency.chf,
          createdBy: 'dev',
        ),
      );
      final a = ok(await app.members.add(chf.id, name: 'Ann')).id;
      final b = ok(await app.members.add(chf.id, name: 'Ben')).id;
      await h['members.setPayment']!({
        'memberId': a,
        'paypalMe': 'ann',
        'iban': _iban,
      });
      final r = await h['payment.links']!({
        'fromId': b,
        'toId': a,
        'amountCents': '1000',
      });
      expect(r['paypalUrl'], 'https://paypal.me/ann/10.00CHF');
      expect(r['epcPayload'], isNull);
      expect(r['epcError'], 'NotEur');
    });

    test('validates params and members', () async {
      for (final bad in [
        <String, String>{},
        {'fromId': benId, 'toId': annId, 'amountCents': '0'},
        {'fromId': benId, 'toId': annId, 'amountCents': 'x'},
        {'fromId': benId, 'amountCents': '5'},
      ]) {
        expect((await h['payment.links']!(bad))['error'], 'invalid_params');
      }
      expect(
        (await h['payment.links']!({
          'fromId': benId,
          'toId': 'nope',
          'amountCents': '5',
        }))['error'],
        'not_found',
      );
    });

    test('members of different groups are not found', () async {
      final other = ok(
        await app.groups.create(name: 'B', currency: eur, createdBy: 'dev'),
      );
      final x = ok(await app.members.add(other.id, name: 'Xi')).id;
      expect(
        (await h['payment.links']!({
          'fromId': x,
          'toId': annId,
          'amountCents': '5',
        }))['error'],
        'not_found',
      );
    });

    test('a failing repository is reported as internal', () async {
      final failing = ProviderContainer(
        overrides: app.overridesWith(payments: _Failing()),
      );
      addTearDown(failing.dispose);
      final r = await paymentDriveHandlers(failing)['payment.links']!({
        'fromId': annId,
        'toId': benId,
        'amountCents': '5',
      });
      expect(r['error'], 'internal');
    });
  });
}

class _Failing implements PaymentDetailsRepository {
  @override
  Future<RepoResult<PaymentDetails>> get(String memberId) async =>
      const Err(Storage('x'));

  @override
  Future<RepoResult<PaymentDetails>> save(
    String memberId, {
    String? paypalMe,
    String? iban,
    String? bic,
    String? accountName,
  }) async => const Err(Storage('x'));
}
