import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/statistics/ui/statistics_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import '../../rides/ui/rides_fixtures.dart';

void main() {
  late RidesApp app;
  late ProviderContainer container;

  StatisticsViewModel vm(String id) =>
      container.read(statisticsViewModelProvider(id).notifier);
  StatisticsState state(String id) =>
      container.read(statisticsViewModelProvider(id));
  StatisticsLoaded loaded(String id) => state(id) as StatisticsLoaded;

  Future<void> open(String id) async {
    container.listen(statisticsViewModelProvider(id), (_, _) {});
    await pumpEventQueue();
  }

  Future<void> spend(
    int cents, {
    required String date,
    String? category,
    int payer = 0,
    ForeignAmount? foreign,
  }) async {
    ok(
      await app.expenses.create(
        app.group.id,
        ExpenseDraft(
          title: 'Ausgabe',
          amountCents: cents,
          currency: app.group.currency,
          date: DateTime.parse('${date}T00:00:00Z'),
          payers: {app.people[payer].id: cents},
          split: EqualSplit({app.people[0].id, app.people[1].id}),
          category: category,
          foreign: foreign,
        ),
      ),
    );
  }

  setUp(() async {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  group('state', () {
    test('loading, then loaded; a group without entries is empty', () async {
      await app.seedGroup();
      final id = app.group.id;
      container.listen(statisticsViewModelProvider(id), (_, _) {});
      expect(state(id), isA<StatisticsLoading>());
      await pumpEventQueue();
      final s = loaded(id);
      expect(s.stats.isEmpty, isTrue);
      expect(s.period, StatsPeriod.month);
      expect(s.today, DateTime.utc(2026, 3));
      expect(s.members.map((m) => m.name), ['Ann', 'Ben', 'Cy']);
      expect(s.currency, Currency.eur);
      expect(s.stats.months, hasLength(statsMonthCount));
    });

    test('numbers follow the expenses and update live', () async {
      await app.seedGroup();
      await spend(1000, date: '2026-03-01', category: 'food');
      await open(app.group.id);
      expect(loaded(app.group.id).stats.totalCents, 1000);
      await spend(500, date: '2026-03-01', category: 'stay', payer: 1);
      await pumpEventQueue();
      final s = loaded(app.group.id);
      expect(s.stats.totalCents, 1500);
      expect(s.stats.topCategory?.key, 'food');
      expect(s.nameOf(app.people[1].id), 'Ben');
      expect(s.nameOf('gone'), '?');
    });

    test('a foreign expense counts in the group currency', () async {
      await app.seedGroup();
      await spend(
        4600,
        date: '2026-03-01',
        foreign: const ForeignAmount(
          currency: Currency.usd,
          amountCents: 5000,
          ratePpm: 920000,
        ),
      );
      await open(app.group.id);
      expect(loaded(app.group.id).stats.totalCents, 4600);
    });

    test('rides show up in the monthly rows', () async {
      await app.seedCommute();
      await app.ride(date: '2026-03-01', driver: 0);
      await open(app.group.id);
      final march = loaded(app.group.id).stats.months.last;
      expect(march.rideMeters, 40000);
      expect(march.rideCents, greaterThan(0));
    });
  });

  group('setPeriod', () {
    test('switches the breakdown, not the monthly rows', () async {
      await app.seedGroup();
      await spend(1000, date: '2026-03-01');
      await spend(400, date: '2026-01-15');
      await spend(200, date: '2025-06-01');
      await open(app.group.id);
      final id = app.group.id;
      expect(loaded(id).stats.totalCents, 1000);
      final months = loaded(id).stats.months;

      vm(id).setPeriod(StatsPeriod.last3Months);
      expect(loaded(id).stats.totalCents, 1400);
      vm(id).setPeriod(StatsPeriod.year);
      expect(loaded(id).stats.totalCents, 1400);
      vm(id).setPeriod(StatsPeriod.all);
      expect(loaded(id).stats.totalCents, 1600);
      expect(loaded(id).period, StatsPeriod.all);
      expect(loaded(id).stats.months, months);
    });

    test('the choice survives a new expense', () async {
      await app.seedGroup();
      await open(app.group.id);
      vm(app.group.id).setPeriod(StatsPeriod.all);
      await spend(100, date: '2020-01-01');
      await pumpEventQueue();
      expect(loaded(app.group.id).stats.totalCents, 100);
    });
  });

  group('failures', () {
    test('an unknown group fails with NotFound', () async {
      await app.seedGroup();
      await open('nope');
      expect(
        (state('nope') as StatisticsFailure).error,
        isA<NotFound>(),
      );
    });

    test(
      'a failing repository stream shows as an error, retry recovers',
      () async {
        await app.seedGroup();
        app.rides.watchError = const Storage('disk');
        await open(app.group.id);
        final failure = state(app.group.id);
        expect(failure, isA<StatisticsFailure>());
        expect((failure as StatisticsFailure).error, isA<Storage>());

        app.rides.watchError = null;
        vm(app.group.id).retry();
        expect(state(app.group.id), isA<StatisticsLoading>());
        await pumpEventQueue();
        expect(state(app.group.id), isA<StatisticsLoaded>());
      },
    );

    test('a foreign error type is wrapped as Storage', () async {
      await app.seedGroup();
      app.base.members.watchError = StateError('boom');
      await open(app.group.id);
      expect((state(app.group.id) as StatisticsFailure).error, isA<Storage>());
    });
  });

  group('load (DebugDrive)', () {
    test('computes for the asked period without touching the screen', () async {
      await app.seedGroup();
      await spend(1000, date: '2026-03-01');
      await spend(400, date: '2026-01-15');
      await open(app.group.id);
      final id = app.group.id;
      final result = await vm(id).load(StatsPeriod.all);
      expect(ok(result).stats.totalCents, 1400);
      expect(loaded(id).period, StatsPeriod.month);
      expect(ok(await vm(id).load()).period, StatsPeriod.month);
    });

    test('an unknown group is NotFound', () async {
      await app.seedGroup();
      final result = await vm('nope').load();
      expect(
        (result as Err<StatisticsLoaded, RepositoryError>).error,
        isA<NotFound>(),
      );
    });

    test('a failing repository is an Err', () async {
      await app.seedGroup();
      app.rides.watchError = const Storage('disk');
      final result = await vm(app.group.id).load();
      expect(result, isA<Err<StatisticsLoaded, RepositoryError>>());
    });
  });

  group('debugSnapshot', () {
    test('loading, error, empty and data', () async {
      await app.seedGroup();
      final id = app.group.id;
      container.listen(statisticsViewModelProvider(id), (_, _) {});
      expect(vm(id).debugSnapshot()['status'], 'loading');
      await pumpEventQueue();
      expect(vm(id).debugSnapshot()['status'], 'empty');

      await spend(1000, date: '2026-03-01', category: 'food');
      await pumpEventQueue();
      final snap = vm(id).debugSnapshot();
      expect(snap['status'], 'data');
      expect(snap['period'], 'month');
      expect(snap['totalCents'], 1000);
      expect(snap['categories'], [
        {'key': 'food', 'cents': 1000, 'percent': 100, 'count': 1},
      ]);
      expect((snap['members']! as List<Object?>).first, {
        'id': app.people[0].id,
        'name': 'Ann',
        'paidCents': 1000,
        'shareCents': 500,
      });
      expect(snap['months'], hasLength(statsMonthCount));

      await open('nope');
      expect(vm('nope').debugSnapshot()['status'], 'error');
    });
  });
}
