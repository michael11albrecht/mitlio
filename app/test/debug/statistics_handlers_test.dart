import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/statistics.dart';
import 'package:mitlio/features/statistics/ui/statistics_view_model.dart';

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
    h = statisticsDriveHandlers(container);
  });

  test('statistics.get returns the numbers of the period', () async {
    final s = await Scenario.create(app, ['A', 'B']);
    await s.expense({'A': 1000}, {'A': 500, 'B': 500});
    await s.expense(
      {'B': 400},
      {'A': 200, 'B': 200},
      date: DateTime.utc(2025, 6),
    );
    final month = await h['statistics.get']!({
      'groupId': s.group.id,
      'period': 'all',
    });
    expect(month['period'], 'all');
    expect(month['totalCents'], 1400);
    expect(month['expenseCount'], 2);
    expect(month['currency'], 'EUR');
    expect((month['members']! as List<Object?>).first, {
      'id': s.ids['A'],
      'name': 'A',
      'paidCents': 1000,
      'shareCents': 700,
    });
    expect(month['months'], hasLength(statsMonthCount));
  });

  test('statistics.get defaults to the screen period', () async {
    final s = await Scenario.create(app, ['A', 'B']);
    final r = await h['statistics.get']!({'groupId': s.group.id});
    expect(r['period'], 'month');
    expect(r['totalCents'], 0);
  });

  test('statistics.period is the picker command', () async {
    final s = await Scenario.create(app, ['A', 'B']);
    container.listen(statisticsViewModelProvider(s.group.id), (_, _) {});
    await pumpEventQueue();
    expect(
      await h['statistics.period']!({
        'groupId': s.group.id,
        'period': 'year',
      }),
      {'period': 'year'},
    );
    final state = container.read(
      statisticsViewModelProvider(s.group.id),
    ) as StatisticsLoaded;
    expect(state.period, StatsPeriod.year);
  });

  test('bad params are reported', () async {
    expect((await h['statistics.get']!({}))['error'], 'invalid_params');
    expect(
      (await h['statistics.get']!({'groupId': 'x', 'period': 'week'}))['error'],
      'invalid_params',
    );
    expect(
      (await h['statistics.period']!({'groupId': 'x'}))['error'],
      'invalid_params',
    );
    expect(
      (await h['statistics.period']!({'period': 'all'}))['error'],
      'invalid_params',
    );
  });

  test('statistics.get reports an unknown group', () async {
    expect(
      (await h['statistics.get']!({'groupId': 'nope'}))['error'],
      isNotNull,
    );
  });
}
