import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/settle/data/services/payment_link_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

class FakeLinkLauncher implements LinkLauncher {
  FakeLinkLauncher({this.canLaunch = true});

  bool canLaunch;
  final launched = <Uri>[];
  final copied = <String>[];

  @override
  Future<bool> launchExternal(Uri uri) async {
    if (canLaunch) launched.add(uri);
    return canLaunch;
  }

  @override
  Future<void> copyToClipboard(String text) async => copied.add(text);
}

void main() {
  final tenEuro = Money(1000, Currency.eur);

  group('openPayPal', () {
    test('opens the PayPal.Me link externally', () async {
      final launcher = FakeLinkLauncher();
      final r = await PaymentLinkService(
        launcher: launcher,
      ).openPayPal('@ann', tenEuro);
      expect(
        r,
        const Ok<PaymentLinkOutcome, PayPalError>(PaymentLinkOutcome.opened),
      );
      expect(launcher.launched, [Uri.parse('https://paypal.me/ann/10.00EUR')]);
      expect(launcher.copied, isEmpty);
    });

    test('copies the link when nothing can open it', () async {
      final launcher = FakeLinkLauncher(canLaunch: false);
      final r = await PaymentLinkService(
        launcher: launcher,
      ).openPayPal('ann', tenEuro);
      expect(
        r,
        const Ok<PaymentLinkOutcome, PayPalError>(PaymentLinkOutcome.copied),
      );
      expect(launcher.copied, ['https://paypal.me/ann/10.00EUR']);
    });

    test('an invalid handle or amount launches nothing', () async {
      final launcher = FakeLinkLauncher();
      final service = PaymentLinkService(launcher: launcher);
      expect(
        await service.openPayPal('not a handle', tenEuro),
        const Err<PaymentLinkOutcome, PayPalError>(InvalidHandle()),
      );
      expect(
        await service.openPayPal('ann', Money(0, Currency.eur)),
        const Err<PaymentLinkOutcome, PayPalError>(NonPositiveAmount()),
      );
      expect(launcher.launched, isEmpty);
      expect(launcher.copied, isEmpty);
    });
  });

  group('epcPayload', () {
    final service = PaymentLinkService(launcher: FakeLinkLauncher());

    test('delegates to the domain', () {
      final r = service.epcPayload(
        name: 'Max Mustermann',
        iban: 'DE89 3704 0044 0532 0130 00',
        amount: Money(1234, Currency.eur),
        remittance: 'mitlio: Urlaub',
      );
      expect(
        r,
        const Ok<String, EpcError>(
          'BCD\n002\n1\nSCT\n\nMax Mustermann\nDE89370400440532013000\n'
          'EUR12.34\n\n\nmitlio: Urlaub',
        ),
      );
    });

    test('reports domain errors', () {
      final r = service.epcPayload(
        name: 'Max',
        iban: 'DE89370400440532013000',
        amount: Money(1234, Currency.chf),
      );
      expect(r, const Err<String, EpcError>(NotEur()));
    });
  });

  group('SystemLinkLauncher', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('copies to the system clipboard', () async {
      String? text;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              text = (call.arguments as Map)['text'] as String?;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await const SystemLinkLauncher().copyToClipboard('x');
      expect(text, 'x');
    });

    test('a platform failure counts as "cannot open"', () async {
      // No url_launcher implementation behind the test binding: it throws.
      expect(
        await const SystemLinkLauncher().launchExternal(
          Uri.parse('https://paypal.me/a'),
        ),
        isFalse,
      );
    });
  });
}
