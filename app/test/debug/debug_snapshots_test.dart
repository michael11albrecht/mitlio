import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/debug/debug_snapshots.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart' show ok;
import '../helpers/fake_app.dart';
import '../helpers/pump_app.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late DebugSnapshotRegistry registry;

  setUp(() {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
    registry = buildSnapshotRegistry(container);
  });

  Future<String> newGroup() async => ok(
    await app.groups.create(
      name: 'Trip',
      currency: Currency.eur,
      createdBy: 'dev',
    ),
  ).id;

  test('lists the slice screens', () {
    expect(registry.screens, [
      'groups',
      'group',
      'expenses',
      'expense_form',
      'balances',
      'rides',
      'rides_setup',
      'vehicle_form',
      'template_form',
    ]);
  });

  test('groups reads the list ViewModel', () async {
    final id = await newGroup();
    registry.snapshot('groups'); // builds the ViewModel
    await pumpEventQueue();
    expect(registry.snapshot('groups'), {
      'status': 'data',
      'groups': [
        {'id': id, 'name': 'Trip', 'currency': 'EUR'},
      ],
    });
  });

  testWidgets('group follows the open route and is not_open elsewhere', (
    tester,
  ) async {
    final id = await newGroup();
    final c = await pumpMitlio(tester, app);
    final live = buildSnapshotRegistry(c);
    expect(live.snapshot('group'), {'status': 'not_open'});

    final router = c.read(routerProvider)..go('/groups/$id');
    await tester.pumpAndSettle();
    expect(live.snapshot('group')!['name'], 'Trip');

    router.go('/groups/$id/edit');
    await tester.pumpAndSettle();
    expect(live.snapshot('group')!['groupId'], id);

    router.go('/groups/new');
    await tester.pumpAndSettle();
    expect(live.snapshot('group'), {'status': 'not_open'});

    // Imperative pushes count too (the UI navigates with push).
    router.go('/');
    await tester.pumpAndSettle();
    unawaited(router.push('/groups/$id'));
    await tester.pumpAndSettle();
    expect(live.snapshot('group')!['groupId'], id);
  });

  testWidgets('expenses and expense_form follow the open route', (
    tester,
  ) async {
    final id = await newGroup();
    final c = await pumpMitlio(tester, app);
    final live = buildSnapshotRegistry(c);
    expect(live.snapshot('expenses'), {'status': 'not_open'});
    expect(live.snapshot('expense_form'), {'status': 'not_open'});

    final router = c.read(routerProvider)..go('/groups/$id');
    await tester.pumpAndSettle();
    expect(live.snapshot('expenses')!['groupId'], id);
    expect(live.snapshot('expense_form'), {'status': 'not_open'});

    router.go('/groups/$id/expenses/new');
    await tester.pumpAndSettle();
    expect(live.snapshot('expense_form')!['expenseId'], isNull);
    expect(live.snapshot('expense_form')!['groupId'], id);

    router.go('/groups/$id/expenses/abc');
    await tester.pumpAndSettle();
    // An id that is not stored is a not-found failure, not "not open".
    expect(live.snapshot('expense_form')!['status'], 'error');
  });

  testWidgets('balances follows the open balances route', (tester) async {
    final id = await newGroup();
    final c = await pumpMitlio(tester, app);
    final live = buildSnapshotRegistry(c);
    expect(live.snapshot('balances'), {'status': 'not_open'});

    c.read(routerProvider).go('/groups/$id/balances');
    await tester.pumpAndSettle();
    expect(live.snapshot('balances')!['status'], 'empty');
    expect(live.snapshot('balances')!['groupId'], id);
  });
}
