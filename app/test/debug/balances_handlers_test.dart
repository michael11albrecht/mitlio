import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/balances.dart';

import '../features/balances/balances_support.dart';
import '../helpers/fake_app.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;

  setUp(() {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
    h = balancesDriveHandlers(container);
  });

  test('balances.get returns balances and simplified transfers', () async {
    final s = await Scenario.create(app, ['A', 'B', 'C']);
    await s.expense({'A': 3000}, {'A': 1000, 'B': 1000, 'C': 1000});
    final r = await h['balances.get']!({'groupId': s.group.id});
    expect(r, {
      'balances': {s.ids['A']!: 2000, s.ids['B']!: -1000, s.ids['C']!: -1000},
      'transfers': [
        {'from': s.ids['B'], 'to': s.ids['A'], 'amount': 1000},
        {'from': s.ids['C'], 'to': s.ids['A'], 'amount': 1000},
      ],
    });
  });

  test('balances.get ignores the toggle of the screen', () async {
    final s = await Scenario.create(app, ['A', 'B']);
    await s.expense({'A': 1000}, {'B': 1000});
    final r = await h['balances.get']!({'groupId': s.group.id});
    expect(r['transfers'], hasLength(1));
  });

  test('balances.get needs a groupId', () async {
    expect((await h['balances.get']!({}))['error'], 'invalid_params');
  });

  test('balances.get reports an unknown group', () async {
    expect((await h['balances.get']!({'groupId': 'nope'}))['error'], isNotNull);
  });
}
