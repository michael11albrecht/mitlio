import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import 'profile_flow_rig.dart';

final _de = AppLocalizationsDe();
const _iban = 'DE89 3704 0044 0532 0130 00';

void main() {
  late ProfileFlowRig rig;
  late FakeApp app;
  late ProviderContainer container;

  setUp(() {
    app = FakeApp();
    rig = ProfileFlowRig(launcher: app.launcher)..install(app);
  });

  Future<void> open(WidgetTester tester, {String? at}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = await pumpMitlio(
      tester,
      app,
      location: at ?? '/settings/profile',
      extra: rig.flowOverrides,
    );
  }

  Finder text(String t) => find.text(t);
  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  group('entry point', () {
    testWidgets('Settings has a "Mein Profil" row that opens the flow', (
      tester,
    ) async {
      await open(tester, at: '/settings');
      await tester.tap(text(_de.profileSettingsEntry));
      await settle(tester);
      expect(text(_de.profileNameTitle), findsOneWidget);
      expect(text('Schritt 1 von 4'), findsOneWidget);
    });
  });

  group('name step', () {
    testWidgets('is required: blank shows a plain hint and stays', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      expect(text(_de.profileNameRequired), findsOneWidget);
      expect(text('Schritt 1 von 4'), findsOneWidget);
      expect(text(_de.setupSkip), findsNothing);
    });

    testWidgets('a failing save is shown, nothing is lost', (tester) async {
      await open(tester);
      rig.profile.failSaveWith = const Storage('full');
      await tester.enterText(field(_de.profileNameLabel), 'Anna');
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      expect(text(_de.errorStorage), findsOneWidget);
      expect(text('Schritt 1 von 4'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Anna'), findsOneWidget);
    });
  });

  group('the whole flow through the UI', () {
    testWidgets('every step answered stays within the profile_setup budget', (
      tester,
    ) async {
      await open(tester);
      final taps = TapCounter(tester);

      await taps.enterText(field(_de.profileNameLabel), 'Anna Beispiel');
      await taps.tap(text(_de.setupNext));
      await settle(tester);

      expect(text(_de.profileAvatarTitle), findsOneWidget);
      await taps.tap(text('🚗'));
      await taps.tap(text(_de.setupNext));
      await settle(tester);

      expect(text(_de.profilePaypalAskTitle), findsOneWidget);
      await taps.tap(text(_de.setupYes));
      await settle(tester);

      expect(text(_de.profilePaypalTitle), findsOneWidget);
      expect(text('Schritt 4 von 5'), findsOneWidget);
      await taps.enterText(
        field(_de.profilePaypalLabel),
        'https://paypal.me/annab?x=1',
      );
      await tester.pump();
      expect(text(_de.profilePaypalResult('paypal.me/annab')), findsOneWidget);
      await taps.tap(text(_de.setupNext));
      await settle(tester);

      expect(text(_de.profileBankAskTitle), findsOneWidget);
      await taps.tap(text(_de.setupYes));
      await settle(tester);

      expect(text(_de.profileIbanTitle), findsOneWidget);
      // The holder is prefilled from the name.
      expect(find.widgetWithText(TextField, 'Anna Beispiel'), findsOneWidget);
      expect(text(_de.profileIbanLocalOnly), findsOneWidget);
      await taps.enterText(
        field(_de.profileIbanLabel),
        'de89370400440532013000',
      );
      await tester.pump();
      expect(find.widgetWithText(TextField, _iban), findsOneWidget);
      expect(text(_de.profileIbanValid), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      await taps.tap(text(_de.setupNext));
      await settle(tester);

      expect(text(_de.profileFinishTitle), findsOneWidget);
      expect(text('Anna Beispiel'), findsOneWidget);
      expect(text(_de.profileCardPaypal('annab')), findsOneWidget);
      expect(text(_de.profileCardIban('3000')), findsOneWidget);
      await taps.tap(text(_de.setupFinishDone));
      await settle(tester);

      taps.expectWithinBudget('profile_setup');
      expect(taps.taps, 8);
      final saved = (await rig.storedProfile())!;
      expect((saved.paypalMe, saved.avatarEmoji), ('annab', '🚗'));
      expect(rig.setup.stored[profileFlowId], isNot(contains('0532')));
      // Back on Settings after "Fertig".
      expect(container.read(routerProvider).state.uri.path, '/settings');
    });

    testWidgets('the shortest path is five taps', (tester) async {
      await open(tester);
      final taps = TapCounter(tester);
      await taps.enterText(field(_de.profileNameLabel), 'Anna');
      await taps.tap(text(_de.setupNext));
      await settle(tester);
      await taps.tap(text(_de.setupSkip)); // avatar
      await settle(tester);
      await taps.tap(text(_de.setupNo)); // PayPal
      await settle(tester);
      expect(text('Schritt 4 von 4'), findsOneWidget);
      await taps.tap(text(_de.setupNo)); // bank
      await settle(tester);
      expect(text(_de.profileCardNoPayment), findsOneWidget);
      await taps.tap(text(_de.setupFinishDone));
      await settle(tester);
      expect(taps.taps, 5);
      taps.expectWithinBudget('profile_setup');
    });

    testWidgets('back from the finish screen goes to the last step', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(field(_de.profileNameLabel), 'Anna');
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      await tester.tap(text(_de.setupSkip));
      await settle(tester);
      await tester.tap(text(_de.setupNo));
      await settle(tester);
      await tester.tap(text(_de.setupNo));
      await settle(tester);
      await tester.tap(text(_de.setupBack));
      await settle(tester);
      expect(text(_de.profileBankAskTitle), findsOneWidget);
    });
  });

  group('PayPal.Me step', () {
    Future<void> toPaypalMe(WidgetTester tester) async {
      await open(tester);
      await tester.enterText(field(_de.profileNameLabel), 'Anna');
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      await tester.tap(text(_de.setupSkip));
      await settle(tester);
      await tester.tap(text(_de.setupYes));
      await settle(tester);
    }

    testWidgets('an invalid handle is explained, nothing is saved', (
      tester,
    ) async {
      await toPaypalMe(tester);
      await tester.enterText(field(_de.profilePaypalLabel), 'a b!');
      await tester.pump();
      expect(text(_de.profilePaypalInvalid), findsOneWidget);
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      expect(text(_de.profilePaypalTitle), findsOneWidget);
    });

    testWidgets('"Link testen" opens the link; disabled until valid', (
      tester,
    ) async {
      await toPaypalMe(tester);
      final test = find.widgetWithText(TextButton, _de.profilePaypalTest);
      expect(tester.widget<TextButton>(test).onPressed, isNull);
      await tester.enterText(field(_de.profilePaypalLabel), '@anna');
      await tester.pump();
      await tester.tap(test);
      await settle(tester);
      expect(rig.launcher.launched.single.toString(), 'https://paypal.me/anna');
    });

    testWidgets('when the link cannot open it is copied and says so', (
      tester,
    ) async {
      await toPaypalMe(tester);
      rig.launcher.canLaunch = false;
      await tester.enterText(field(_de.profilePaypalLabel), 'anna');
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, _de.profilePaypalTest));
      await settle(tester);
      expect(text(_de.profilePaypalLinkCopied), findsOneWidget);
      expect(rig.launcher.copied, ['https://paypal.me/anna']);
    });

    testWidgets('"Jetzt erstellen" opens PayPal', (tester) async {
      await toPaypalMe(tester);
      await tester.tap(text(_de.profilePaypalCreate));
      await settle(tester);
      expect(rig.launcher.launched.single.host, 'www.paypal.com');
    });

    testWidgets('"So findest du deinen Link" shows four sub-steps', (
      tester,
    ) async {
      await toPaypalMe(tester);
      await tester.tap(text(_de.profilePaypalHelpTitle));
      await settle(tester);
      for (final t in [
        _de.profilePaypalHelp1,
        _de.profilePaypalHelp2,
        _de.profilePaypalHelp3,
        _de.profilePaypalHelp4,
      ]) {
        expect(find.textContaining(t), findsOneWidget);
      }
    });

    testWidgets('can be skipped', (tester) async {
      await toPaypalMe(tester);
      await tester.tap(text(_de.setupSkip));
      await settle(tester);
      expect(text(_de.profileBankAskTitle), findsOneWidget);
    });
  });

  group('IBAN step', () {
    Future<void> toIban(WidgetTester tester) async {
      await open(tester);
      await tester.enterText(field(_de.profileNameLabel), 'Anna');
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      await tester.tap(text(_de.setupSkip));
      await settle(tester);
      await tester.tap(text(_de.setupSkip));
      await settle(tester);
      await tester.tap(text(_de.setupYes));
      await settle(tester);
    }

    testWidgets('formats and checks while typing', (tester) async {
      await toIban(tester);
      await tester.enterText(field(_de.profileIbanLabel), 'de8937');
      await tester.pump();
      expect(find.widgetWithText(TextField, 'DE89 37'), findsOneWidget);
      expect(text(_de.profileIbanTyping), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      await tester.enterText(
        field(_de.profileIbanLabel),
        'DE89370400440532013001',
      );
      await tester.pump();
      expect(text(_de.profileIbanBadChecksum), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('"Weiter" with a bad IBAN explains and saves nothing', (
      tester,
    ) async {
      await toIban(tester);
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      expect(text(_de.profileIbanBadFormat), findsOneWidget);
      expect(text(_de.profileIbanTitle), findsOneWidget);
      expect(await rig.storedBank(), isNull);
    });

    testWidgets('a missing holder is asked for', (tester) async {
      await toIban(tester);
      await tester.enterText(field(_de.profileIbanLabel), _iban);
      await tester.enterText(field(_de.profileIbanHolderLabel), '');
      await tester.pump();
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      expect(text(_de.profileIbanHolderRequired), findsOneWidget);
    });

    testWidgets('paste fills the field from the clipboard', (tester) async {
      await toIban(tester);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData'
            ? <String, Object?>{'text': 'de89370400440532013000'}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byTooltip(_de.profileIbanPaste));
      await settle(tester);
      expect(find.widgetWithText(TextField, _iban), findsOneWidget);
      expect(text(_de.profileIbanValid), findsOneWidget);
    });

    testWidgets('paste with an empty clipboard says so', (tester) async {
      await toIban(tester);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byTooltip(_de.profileIbanPaste));
      await settle(tester);
      expect(text(_de.profileIbanPasteEmpty), findsOneWidget);
    });

    testWidgets('a failing bank save is shown and the step stays', (
      tester,
    ) async {
      await toIban(tester);
      rig.bank.failSaveWith = const Storage('full');
      await tester.enterText(field(_de.profileIbanLabel), _iban);
      await tester.pump();
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      expect(text(_de.errorStorage), findsOneWidget);
      expect(text(_de.profileIbanTitle), findsOneWidget);
    });

    testWidgets('coming back shows the stored IBAN', (tester) async {
      await toIban(tester);
      await tester.enterText(field(_de.profileIbanLabel), _iban);
      await tester.pump();
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      await tester.tap(text(_de.setupBack)); // finish -> IBAN step
      await settle(tester);
      expect(find.widgetWithText(TextField, _iban), findsOneWidget);
    });

    testWidgets('a failing read of the stored IBAN is shown', (tester) async {
      await toIban(tester);
      await tester.enterText(field(_de.profileIbanLabel), _iban);
      await tester.pump();
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      rig.bank.failGetWith = const Storage('disk');
      await tester.tap(text(_de.setupBack));
      await settle(tester);
      expect(text(_de.errorStorage), findsOneWidget);
    });

    testWidgets('can be skipped', (tester) async {
      await toIban(tester);
      await tester.tap(text(_de.setupSkip));
      await settle(tester);
      expect(text(_de.profileFinishTitle), findsOneWidget);
      expect(text(_de.profileCardNoPayment), findsOneWidget);
    });
  });

  group('avatar step', () {
    testWidgets('colour and symbol are picked, initials are the default', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester);
      await tester.enterText(field(_de.profileNameLabel), 'Anna');
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel(_de.profileAvatarColor(3)));
      await tester.tap(text('🌻'));
      await tester.pump();
      await tester.tap(text(_de.setupNext));
      await settle(tester);
      final saved = (await rig.storedProfile())!;
      expect(saved.avatarEmoji, '🌻');
      expect(saved.avatarColor, isNotNull);
      semantics.dispose();
    });
  });
}
