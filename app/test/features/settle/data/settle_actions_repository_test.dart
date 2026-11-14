import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settle/data/repositories/settle_actions_repository.dart';
import 'package:mitlio/features/settle/data/services/payment_link_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/fake_platform.dart';
import '../../repo_test_support.dart';

const _iban = 'DE89370400440532013000';

void main() {
  late FakeApp app;
  late FakeLinkLauncher launcher;
  late FakeShareService share;
  late SettleActionsRepository repo;
  late String annaId;
  late String benId;

  final tenEuro = Money(1000, Currency.eur);

  setUp(() async {
    app = FakeApp();
    launcher = FakeLinkLauncher();
    share = FakeShareService();
    repo = PlatformSettleActionsRepository(
      details: app.payments,
      links: PaymentLinkService(launcher: launcher),
      launcher: launcher,
      share: share,
    );
    final g = ok(
      await app.groups.create(name: 'Trip', currency: eur, createdBy: 'dev'),
    );
    annaId = ok(await app.members.add(g.id, name: 'Anna')).id;
    benId = ok(await app.members.add(g.id, name: 'Ben')).id;
  });

  Future<void> annaPays({String? paypal, String? iban}) async {
    ok(await app.payments.save(annaId, paypalMe: paypal, iban: iban));
  }

  group('options', () {
    test('none, PayPal, IBAN, both', () async {
      expect(ok(await repo.options(annaId)).isEmpty, isTrue);
      await annaPays(paypal: 'anna');
      expect(ok(await repo.options(annaId)).hasPaypal, isTrue);
      expect(ok(await repo.options(annaId)).hasIban, isFalse);
      await annaPays(paypal: 'anna', iban: _iban);
      final both = ok(await repo.options(annaId));
      expect(both.hasPaypal && both.hasIban, isTrue);
      expect(both.ibanHint, 'DE89 •••• 3000');
      expect(both.isEmpty, isFalse);
    });

    test('equal options are equal', () {
      const a = PayoutOptions(hasPaypal: true, hasIban: false);
      const b = PayoutOptions(hasPaypal: true, hasIban: false);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const PayoutOptions(hasPaypal: true, hasIban: true)));
    });

    test('an unknown member is NotFound', () async {
      expect(err(await repo.options('x')), isA<NotFound>());
    });
  });

  group('epcPayload', () {
    Future<RepoResult<String?>> payload(Money amount, {String? to}) =>
        repo.epcPayload(
          memberId: to ?? annaId,
          memberName: 'Anna',
          amount: amount,
          remittance: 'mitlio: Trip',
        );

    test('builds the payload with the member name as fallback', () async {
      await annaPays(iban: _iban);
      expect(
        ok(await payload(tenEuro)),
        'BCD\n002\n1\nSCT\n\nAnna\n$_iban\nEUR10.00\n\n\nmitlio: Trip',
      );
    });

    test('no IBAN: null', () async {
      expect(ok(await payload(tenEuro)), isNull);
    });

    test('not euro: null', () async {
      await annaPays(iban: _iban);
      expect(ok(await payload(Money(1000, Currency.usd))), isNull);
    });

    test('an unknown member is NotFound', () async {
      expect(err(await payload(tenEuro, to: 'x')), isA<NotFound>());
    });
  });

  group('openPayPal', () {
    test('opens the link', () async {
      await annaPays(paypal: 'anna');
      expect(ok(await repo.openPayPal(annaId, tenEuro)), PayPalOutcome.opened);
      expect(
        launcher.launched.single.toString(),
        'https://paypal.me/anna/10.00EUR',
      );
    });

    test('copies the link when nothing opens it', () async {
      await annaPays(paypal: 'anna');
      launcher.canLaunch = false;
      expect(ok(await repo.openPayPal(annaId, tenEuro)), PayPalOutcome.copied);
      expect(launcher.copied.single, 'https://paypal.me/anna/10.00EUR');
    });

    test('no handle: InvalidData', () async {
      expect(err(await repo.openPayPal(annaId, tenEuro)), isA<InvalidData>());
    });

    test('a bad amount is InvalidData', () async {
      await annaPays(paypal: 'anna');
      expect(
        err(await repo.openPayPal(annaId, Money(0, Currency.eur))),
        isA<InvalidData>(),
      );
    });

    test('an unknown member is NotFound', () async {
      expect(err(await repo.openPayPal('x', tenEuro)), isA<NotFound>());
    });
  });

  group('copyIban', () {
    test('copies the normalised IBAN', () async {
      await annaPays(iban: _iban);
      ok(await repo.copyIban(annaId));
      expect(launcher.copied, [_iban]);
    });

    test('no IBAN: InvalidData, nothing copied', () async {
      expect(err(await repo.copyIban(annaId)), isA<InvalidData>());
      expect(launcher.copied, isEmpty);
    });

    test('an unknown member is NotFound', () async {
      expect(err(await repo.copyIban(benId + annaId)), isA<NotFound>());
    });
  });

  group('shareText', () {
    test('hands the text to the share sheet', () async {
      ok(await repo.shareText('Trip: Ben → Anna 5 €'));
      expect(share.shared, ['Trip: Ben → Anna 5 €']);
    });

    test('a failing share sheet is Storage', () async {
      share.failWith = Exception('no share');
      expect(err(await repo.shareText('x')), isA<Storage>());
    });
  });
}
