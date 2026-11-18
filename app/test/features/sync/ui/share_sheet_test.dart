import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/ui/share_sheet.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/fake_app.dart';
import '../../../support/tap_counter.dart';
import '../../balances/balances_support.dart';
import '../support/share_support.dart';
import 'share_fixtures.dart';

void main() {
  /// The app on the group detail of a fresh group, share sheet stubbed.
  Future<(FakeApp, ProviderContainer)> openGroup(
    WidgetTester tester, {
    bool backend = true,
  }) async {
    final app = FakeApp();
    final s = await Scenario.create(app, ['Anna', 'Ben']);
    final container = ProviderContainer(
      overrides: [
        ...app.overrides,
        shareAvailableProvider.overrideWithValue(backend),
        ...shareStateOverride(shareStates[1].$2),
      ],
    );
    addTearDown(container.dispose);
    tester.platformDispatcher.localesTestValue = [const Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    container.read(routerProvider).go('/groups/${s.group.id}');
    await tester.pumpAndSettle();
    return (app, container);
  }

  testWidgets('one tap from the group detail shows link and QR', (
    tester,
  ) async {
    await openGroup(tester);
    final taps = TapCounter(tester);
    await taps.tap(find.byTooltip('Gruppe teilen'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.text('mitlio.web.app/join/abcd…'),
      findsOneWidget,
      reason: 'a shortened link, not the whole secret',
    );
    expect(find.text('Neuen Link erstellen'), findsOneWidget);
    taps.expectWithinBudget('share_group_link');
  });

  testWidgets('two taps hand the invitation to the system share', (
    tester,
  ) async {
    final (app, _) = await openGroup(tester);
    final taps = TapCounter(tester);
    await taps.tap(find.byTooltip('Gruppe teilen'));
    await tester.pumpAndSettle();
    await taps.tap(find.text('Link teilen'));
    await tester.pumpAndSettle();
    expect(
      app.share.shared.single,
      'Komm in die Gruppe Wochenende in den Bergen bei mitlio: '
      '${sampleLink.url}',
    );
    taps.expectWithinBudget('share_group_system_share');
  });

  testWidgets('a system share that fails says so', (tester) async {
    final (app, _) = await openGroup(tester);
    app.share.failWith = Exception('no share sheet');
    await tester.tap(find.byTooltip('Gruppe teilen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link teilen'));
    await tester.pumpAndSettle();
    expect(
      find.text(AppLocalizationsDe().shareFailed),
      findsOneWidget,
    );
  });

  testWidgets('without a backend there is no share entry', (tester) async {
    await openGroup(tester, backend: false);
    expect(find.byTooltip('Gruppe teilen'), findsNothing);
  });

  group('the sheet with the real view model', () {
    Future<ProviderContainer> pumpSheet(
      WidgetTester tester,
      ShareWorld world, {
      Locale locale = const Locale('de'),
    }) async {
      final container = world.container();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: mitlioLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: ShareSheet(groupId: shareGroupId)),
          ),
        ),
      );
      // Drift and the fakes answer on real time.
      await tester.runAsync(
        () => Future<void>.delayed(
          const Duration(milliseconds: 100),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('a local group is shared, then its link and QR show', (
      tester,
    ) async {
      final w = await ShareWorld.create();
      await pumpSheet(tester, w);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Link teilen'), findsOneWidget);
      expect(find.text('Neuen Link erstellen'), findsOneWidget);
      expect(w.remote.hasMember(shareGroupId), isTrue);
      expect(w.storedToken, isNotNull);
    });

    testWidgets('new link: inline second step, no dialog, old link dies', (
      tester,
    ) async {
      final w = await ShareWorld.create();
      await pumpSheet(tester, w);
      final old = w.storedToken!;

      await tester.tap(find.text('Neuen Link erstellen'));
      await tester.pumpAndSettle();
      expect(
        find.text('Der alte Link funktioniert dann nicht mehr.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      // Still the old link until the second step.
      expect(w.storedToken, old);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Neuen Link erstellen'),
      );
      await tester.runAsync(
        () => Future<void>.delayed(
          const Duration(milliseconds: 100),
        ),
      );
      await tester.pumpAndSettle();
      expect(w.storedToken, isNot(old));
      expect(
        find.text('Der alte Link funktioniert dann nicht mehr.'),
        findsNothing,
      );
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('a failed new link shows why, de', (tester) async {
      final w = await ShareWorld.create();
      await pumpSheet(tester, w);
      await tester.tap(find.text('Neuen Link erstellen'));
      await tester.pumpAndSettle();
      w.invites.failNext(const RateLimitedRemote(Duration(minutes: 6)));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Neuen Link erstellen'),
      );
      await tester.runAsync(
        () => Future<void>.delayed(
          const Duration(milliseconds: 100),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Zu viele Versuche. Versuch es in 6 Min. nochmal.'),
        findsOneWidget,
      );
      expect(
        find.text('Der alte Link funktioniert dann nicht mehr.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed first share shows the text and retries, en', (
      tester,
    ) async {
      final w = await ShareWorld.create();
      w.remote.offline = true;
      await pumpSheet(tester, w, locale: const Locale('en'));
      final en = AppLocalizationsEn();
      expect(
        find.textContaining(en.shareUploadPartial(0, 3)),
        findsOneWidget,
      );
      expect(
        find.textContaining(remoteErrorText(en, const Offline())),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsNothing);

      w.remote.offline = false;
      await tester.tap(find.text(en.retry));
      await tester.runAsync(
        () => Future<void>.delayed(
          const Duration(milliseconds: 100),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('a member sees the link but no way to make a new one', (
      tester,
    ) async {
      final w = await ShareWorld.createMember();
      await pumpSheet(tester, w);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Neuen Link erstellen'), findsNothing);
    });

    testWidgets('a member whose link was replaced is told what to do', (
      tester,
    ) async {
      final w = await ShareWorld.createMember();
      await w.serverInvites.createInvite(shareGroupId);
      await pumpSheet(tester, w);
      expect(
        find.text(
          'Dieser Link gilt nicht mehr. Frag, wer die Gruppe erstellt hat, '
          'nach dem neuen.',
        ),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsNothing);
    });
  });
}
