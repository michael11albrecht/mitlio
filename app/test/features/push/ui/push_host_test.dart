import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/ui/push_notices_view_model.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';

import '../../../helpers/fake_app.dart';
import 'push_fixtures.dart';

const _slide = Duration(milliseconds: 600);

/// The top of the stack, also for screens that were pushed.
String _location(ProviderContainer c) => c
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .last
    .matchedLocation;

void main() {
  late PushWorld w;
  late ProviderContainer c;

  Future<void> open(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    w = await PushWorld.create();
    c = ProviderContainer(
      overrides: [
        ...FakeApp().overrides,
        ...w.overrides,
        syncRemoteProvider.overrideWithValue(FakeSyncRemote()),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await w.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MitlioApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the offer is a snack bar; "Ja, bitte" asks and registers', (
    tester,
  ) async {
    await open(tester);
    await c.read(pushNoticesViewModelProvider.notifier).offer();
    await tester.pump();
    await tester.pump(_slide);
    expect(
      find.text('Soll mitlio dir Bescheid geben, wenn jemand etwas einträgt?'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Ja, bitte'));
    await tester.pumpAndSettle();
    expect(w.service.permissionRequests, 1);
    expect(w.remote.tokens, hasLength(1));
    expect(c.read(pushNoticesViewModelProvider), isNull);
  });

  testWidgets('swiping the offer away is "not now": not asked again', (
    tester,
  ) async {
    await open(tester);
    await c.read(pushNoticesViewModelProvider.notifier).offer();
    await tester.pump();
    await tester.pump(_slide);
    await tester.drag(find.byType(SnackBar), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(w.store.wasAsked, isTrue);
    expect(w.service.permissionRequests, 0);
    await c.read(pushNoticesViewModelProvider.notifier).offer();
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('the offer timing out is "not now" too', (tester) async {
    await open(tester);
    await c.read(pushNoticesViewModelProvider.notifier).offer();
    await tester.pump();
    await tester.pump(_slide);
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(w.store.wasAsked, isTrue);
  });

  testWidgets('another note replacing the offer does not use it up', (
    tester,
  ) async {
    await open(tester);
    final vm = c.read(pushNoticesViewModelProvider.notifier);
    await vm.offer();
    await tester.pump();
    await tester.pump(_slide);
    vm.state = const PushNoticeOpenFailed();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(w.store.wasAsked, isFalse);
    expect(find.textContaining('nicht öffnen'), findsOneWidget);
  });

  testWidgets('denied by the OS: a quiet note with the way back', (
    tester,
  ) async {
    await open(tester);
    w.service.permissionAnswer = PushPermission.denied;
    final vm = c.read(pushNoticesViewModelProvider.notifier);
    await vm.offer();
    await tester.pump();
    await tester.pump(_slide);
    await tester.tap(find.text('Ja, bitte'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Systemeinstellungen'), findsOneWidget);
    expect(w.remote.tokens, isEmpty);
  });

  testWidgets('a foreground message is an in-app note; "Ansehen" opens it', (
    tester,
  ) async {
    await open(tester);
    w.service.emitForeground(
      const PushMessage({
        'group_id': 'g1',
        'event': 'expense_added',
        'expense_id': 'e1',
      }, body: 'Anna hat „Tanken“ eingetragen · 42,00 €'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Anna hat „Tanken“'), findsOneWidget);
    await tester.tap(find.text('Ansehen'));
    await tester.pumpAndSettle();
    expect(
      _location(c),
      '/groups/g1/expenses/e1',
    );
  });

  testWidgets('a tapped notification opens the expense after a pull', (
    tester,
  ) async {
    await open(tester);
    w.service.emitOpened(
      const PushMessage({'group_id': 'g1', 'expense_id': 'e1'}),
    );
    await tester.pumpAndSettle();
    expect(
      _location(c),
      '/groups/g1/expenses/e1',
    );
  });

  testWidgets('a tapped notification without ids says so', (tester) async {
    await open(tester);
    w.service.emitOpened(const PushMessage({'group_id': '../x'}));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Diese Benachrichtigung ließ sich nicht öffnen. '
        'Öffne die Gruppe in der Liste.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the app opened by a notification goes to it', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    w = await PushWorld.create();
    w.service.launchMessage = const PushMessage({
      'group_id': 'g1',
      'expense_id': 'e7',
    });
    c = ProviderContainer(
      overrides: [
        ...FakeApp().overrides,
        ...w.overrides,
        syncRemoteProvider.overrideWithValue(FakeSyncRemote()),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await w.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MitlioApp()),
    );
    await tester.pumpAndSettle();
    expect(
      _location(c),
      '/groups/g1/expenses/e7',
    );
  });
}
