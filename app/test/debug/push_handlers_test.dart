import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/push.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';

import '../features/push/ui/push_fixtures.dart';
import '../helpers/fake_app.dart';

/// `ext.mitlio.push.simulate`: a payload goes through the routing the platform
/// streams use, without FCM (P6b-T07). The app runs, so the router is real.
void main() {
  late PushWorld w;
  late FakeSyncRemote sync;
  late Map<String, DriveHandler> h;

  Future<void> open(WidgetTester tester) async {
    w = await PushWorld.create();
    sync = FakeSyncRemote()..addMember('g1');
    final c = ProviderContainer(
      overrides: [
        ...FakeApp().overrides,
        ...w.overrides,
        syncRemoteProvider.overrideWithValue(sync),
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
    h = pushDriveHandlers(c);
  }

  Future<DriveResult> simulate(
    Object payload, {
    String? source,
    String? body,
  }) => h['push.simulate']!({
    'payload': payload is String ? payload : jsonEncode(payload),
    'source': ?source,
    'body': ?body,
  });

  testWidgets('a tap opens the expense, the group is pulled first', (
    tester,
  ) async {
    await open(tester);
    final r = await simulate({
      'group_id': 'g1',
      'event': 'expense_added',
      'expense_id': 'e1',
    });
    expect(r['route'], '/groups/g1/expenses/e1');
    expect(r['opened'], ['/groups/g1', '/groups/g1/expenses/e1']);
    expect(r['pulled'], isTrue);
    expect(r['announced'], isNull);
    expect(sync.calls, greaterThan(0));
  });

  testWidgets('foreground announces and does not move', (tester) async {
    await open(tester);
    final r = await simulate(
      {'group_id': 'g1'},
      source: 'foreground',
      body: 'Anna hat ...',
    );
    expect(r['announced'], 'incoming');
    expect(r['opened'], isEmpty);
    expect(r['route'], '/');
    expect(sync.calls, greaterThan(0));
  });

  testWidgets('background pulls only', (tester) async {
    await open(tester);
    final r = await simulate({'group_id': 'g1'}, source: 'background');
    expect(r['pulled'], isTrue);
    expect(r['opened'], isEmpty);
    expect(r['announced'], isNull);
  });

  testWidgets('numbers in the payload are fine, they arrive as strings', (
    tester,
  ) async {
    await open(tester);
    final r = await simulate({'group_id': 'g1', 'expense_id': 7});
    expect(r['route'], '/groups/g1/expenses/7');
  });

  testWidgets('bad input is invalid_params, nothing is pulled', (
    tester,
  ) async {
    await open(tester);
    expect((await h['push.simulate']!({}))['error'], 'invalid_params');
    expect((await simulate('{nope'))['error'], 'invalid_params');
    expect((await simulate('[1]'))['error'], 'invalid_params');
    expect(
      (await simulate({'group_id': 'g1'}, source: 'sideways'))['error'],
      'invalid_params',
    );
    final noGroup = await simulate({'event': 'expense_added'});
    expect(noGroup['error'], 'invalid_params');
    expect(noGroup['announced'], 'openFailed');
    expect(sync.calls, 0);
  });
}
