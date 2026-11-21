import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/setup.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The profile flow (PU-T07) on the Linux desktop device with an in-memory
/// Drift database: once through the screens, once through
/// `ext.mitlio.setup.*`. Both end in the same rows, the IBAN only in the
/// local bank table.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late AppDatabase db;
  late Map<String, DriveHandler> drive;

  Future<void> start(WidgetTester tester) async {
    // German strings: the CI device language is not guaranteed.
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        setupFlowConfigsProvider.overrideWithValue({
          profileSetupFlow.id: profileSetupFlow,
        }),
      ],
    );
    addTearDown(container.dispose);
    drive = setupDriveHandlers(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Map<String, String> params(Object? answer) => {
    'flowId': profileFlowId,
    if (answer != null) 'answer': jsonEncode(answer),
  };

  Future<void> expectSavedLikeTheScript() async {
    final profile = await container.read(profileRepositoryProvider).get();
    final saved = (profile as Ok<UserProfile?, RepositoryError>).value;
    expect(saved?.displayName, 'Anna Beispiel');
    expect(saved?.paypalMe, 'annab');
    final bank = await container.read(profileBankRepositoryProvider).get();
    expect(
      (bank as Ok<ProfileBank?, RepositoryError>).value?.iban,
      'DE89370400440532013000',
    );
  }

  testWidgets('through the screens: Settings, every step, the card', (
    tester,
  ) async {
    await start(tester);
    print('MARK 1');
    container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    print('MARK 2');
    await tapText(tester, 'Mein Profil');
    print('MARK 3');

    await tester.enterText(
      find.widgetWithText(TextField, 'Dein Name'),
      'Anna Beispiel',
    );
    await tapText(tester, 'Weiter');
    print('MARK 4');
    await tapText(tester, 'Überspringen'); // avatar
    await tapText(tester, 'Ja'); // PayPal
    await tester.enterText(
      find.widgetWithText(TextField, 'PayPal.Me-Link oder Name'),
      'paypal.me/annab',
    );
    await tapText(tester, 'Weiter');
    print('MARK 5');
    await tapText(tester, 'Ja'); // bank transfer
    await tester.enterText(
      find.widgetWithText(TextField, 'IBAN'),
      'de89370400440532013000',
    );
    await tester.pumpAndSettle();
    print('MARK 6');
    expect(find.text('IBAN stimmt'), findsOneWidget);
    print('MARK 7');
    await tapText(tester, 'Weiter');
    print('MARK 8');

    expect(find.text('Dein Profil ist fertig'), findsOneWidget);
    print('MARK 9');
    expect(find.text('PayPal.Me: annab'), findsOneWidget);
    print('MARK 10');
    await expectSavedLikeTheScript();
    print('MARK 11');
    await tapText(tester, 'Fertig');
    print('MARK 12');
    expect(find.text('Einstellungen'), findsOneWidget);
    print('MARK 13');
  });

  testWidgets('through ext.mitlio.setup.*: the same rows, the card on resume', (
    tester,
  ) async {
    await start(tester);
    print('MARK 14');
    var r = await drive['setup.state']!(params(null));
    expect(r['step'], profileStepName);
    print('MARK 15');
    await drive['setup.next']!(params('Anna Beispiel'));
    print('MARK 16');
    await drive['setup.skip']!(params(null)); // avatar
    await drive['setup.next']!(params(true));
    print('MARK 17');
    await drive['setup.next']!(params('annab'));
    print('MARK 18');
    await drive['setup.next']!(params(true));
    print('MARK 19');
    r = await drive['setup.next']!(
      params({
        'iban': 'DE89 3704 0044 0532 0130 00',
        'holder': 'Anna Beispiel',
      }),
    );
    expect(r['finished'], isTrue);
    print('MARK 20');
    expect(jsonEncode(r), isNot(contains('0532')));
    print('MARK 21');
    await expectSavedLikeTheScript();
    print('MARK 22');

    // The screen resumes on the finish screen and shows what was set up.
    container.read(routerProvider).go('/settings/profile');
    await tester.pumpAndSettle();
    print('MARK 23');
    expect(find.text('Dein Profil ist fertig'), findsOneWidget);
    print('MARK 24');
    expect(find.text('Anna Beispiel'), findsOneWidget);
    print('MARK 25');
  });

  testWidgets('every step but the name can be skipped', (tester) async {
    await start(tester);
    print('MARK 26');
    await drive['setup.next']!(params('Anna'));
    print('MARK 27');
    for (var i = 0; i < 3; i++) {
      await drive['setup.skip']!(params(null));
    }
    final r = await drive['setup.state']!(params(null));
    print('MARK 28');
    expect(r['finished'], isTrue);
    print('MARK 29');
    final bank = await container.read(profileBankRepositoryProvider).get();
    expect((bank as Ok<ProfileBank?, RepositoryError>).value, isNull);
    print('MARK 30');
  });
}
