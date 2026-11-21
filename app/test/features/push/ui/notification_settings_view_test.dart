import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/ui/notification_settings_view.dart';
import 'package:mitlio/features/push/ui/notification_settings_view_model.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/themed_app.dart';
import '../../groups/ui/groups_fixtures.dart';
import 'push_fixtures.dart';

void main() {
  for (final (name, state) in notificationSettingsStates) {
    // The spinner never settles; the loading label is checked below.
    if (name == 'loading') continue;
    forEachMode(
      'notification settings $name',
      () => scoped(
        notificationSettingsOverride(state),
        const NotificationSettingsView(groupId: 'g1'),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }

  testWidgets('loading announces itself to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      themedApp(
        scoped(
          notificationSettingsOverride(const NotificationSettingsLoading()),
          const NotificationSettingsView(groupId: 'g1'),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel('Einstellungen werden geladen'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  group('with the real view model', () {
    late PushWorld w;
    late ProviderContainer c;

    setUp(() async {
      w = await PushWorld.create();
      c = w.container();
      addTearDown(() async {
        c.dispose();
        await w.close();
      });
    });

    Future<void> open(WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('de')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            localizationsDelegates: mitlioLocalizationsDelegates,
            supportedLocales: [Locale('de'), Locale('en')],
            home: NotificationSettingsView(groupId: 'g1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('choosing a level saves at once', (tester) async {
      await open(tester);
      expect(find.text('Alles'), findsOneWidget);
      await tester.tap(find.text('Nur was mich betrifft'));
      await tester.pumpAndSettle();
      expect(w.remote.prefs['fake-user-1|g1']!.level, NotificationLevel.mine);
      await tester.tap(find.text('Nichts'));
      await tester.pumpAndSettle();
      expect(w.remote.prefs['fake-user-1|g1']!.level, NotificationLevel.none);
    });

    testWidgets('quiet hours switch shows the window and changes it', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Von'), findsNothing);
      await tester.tap(find.text('Ruhezeiten'));
      await tester.pumpAndSettle();
      expect(find.text('Von'), findsOneWidget);
      expect(find.text('22:00'), findsOneWidget);
      expect(find.text('07:00'), findsOneWidget);
      expect(
        w.remote.prefs['fake-user-1|g1']!.quietHours!.startMinutes,
        22 * 60,
      );

      await tester.tap(find.text('22:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('21:00').last);
      await tester.pumpAndSettle();
      expect(
        w.remote.prefs['fake-user-1|g1']!.quietHours!.startMinutes,
        21 * 60,
      );

      await tester.tap(find.text('07:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('08:00').last);
      await tester.pumpAndSettle();
      expect(
        w.remote.prefs['fake-user-1|g1']!.quietHours!.endMinutes,
        8 * 60,
      );

      await tester.tap(find.text('Ruhezeiten'));
      await tester.pumpAndSettle();
      expect(find.text('Von'), findsNothing);
      expect(w.remote.prefs['fake-user-1|g1']!.quietHours, isNull);
    });

    testWidgets('hide amounts saves at once', (tester) async {
      await open(tester);
      await tester.tap(find.text('Beträge ausblenden'));
      await tester.pumpAndSettle();
      expect(w.remote.prefs['fake-user-1|g1']!.hideAmounts, isTrue);
    });

    testWidgets('a failed save says why and what to do, and snaps back', (
      tester,
    ) async {
      await open(tester);
      w.remote.offline = true;
      await tester.tap(find.text('Nichts'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Keine Verbindung'), findsOneWidget);
      final group = tester.widget<RadioListTile<NotificationLevel>>(
        find.widgetWithText(RadioListTile<NotificationLevel>, 'Alles'),
      );
      expect(group.value, NotificationLevel.all);
      expect(w.remote.prefs, isEmpty);
    });

    testWidgets('a load failure offers "Nochmal versuchen"', (tester) async {
      w.remote.failNext(const RateLimitedRemote(Duration(minutes: 3)));
      await open(tester);
      expect(find.textContaining('3 Min.'), findsOneWidget);
      await tester.tap(find.text('Nochmal versuchen'));
      await tester.pumpAndSettle();
      expect(find.text('Alles'), findsOneWidget);
    });

    testWidgets('enable shows while undecided and asks the OS', (tester) async {
      await open(tester);
      expect(find.text('Benachrichtigungen einschalten'), findsOneWidget);
      await tester.tap(find.text('Benachrichtigungen einschalten'));
      await tester.pumpAndSettle();
      expect(w.service.permissionRequests, 1);
      expect(find.text('Benachrichtigungen einschalten'), findsNothing);
      expect(w.remote.tokens, hasLength(1));
    });

    testWidgets('enable that fails is shown', (tester) async {
      await open(tester);
      w.remote.offline = true;
      await tester.tap(find.text('Benachrichtigungen einschalten'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Keine Verbindung'), findsOneWidget);
    });

    testWidgets('denied and unavailable say so', (tester) async {
      w.service.permissionState = PushPermission.denied;
      await open(tester);
      expect(find.textContaining('Systemeinstellungen'), findsOneWidget);
    });

    testWidgets('without push the screen says so', (tester) async {
      w.service.available = false;
      await open(tester);
      expect(find.textContaining('noch nicht'), findsOneWidget);
    });
  });
}
