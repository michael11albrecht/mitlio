import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/month_settle_flow_view_model.dart';
import 'package:mitlio/features/rides/ui/ride_settle_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../profile/ui/car_flow_support.dart';
import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

const _march = Month(2026, 3);

void main() {
  late RidesApp app;
  late ProviderContainer c;

  setUp(() async {
    app = RidesApp();
    await app.seedCommute();
    await app.ride(date: '2026-03-05', driver: 0, passengers: [1]);
    await app.ride(date: '2026-03-06', driver: 1, passengers: [0]);
    c = app.container();
    addTearDown(c.dispose);
  });

  RepositoryError errorOf(RepoResult<void> r) =>
      (r as Err<void, RepositoryError>).error;

  MonthSettleKey key([Month month = _march]) =>
      (groupId: app.group.id, month: month);
  MonthSettleFlowViewModel vm([Month month = _march]) =>
      c.read(monthSettleFlowViewModelProvider(key(month)).notifier);
  String title(String name, Month month) => 'Fahrten ${month.month} · $name';

  group('steps', () {
    test('review the rides, review the amounts, then confirm', () {
      expect(
        [for (final s in monthSettleFlow.steps) s.id],
        ['rides', 'amounts'],
      );
      expect(monthSettleFlow.steps.every((s) => !s.skippable), isTrue);
    });

    test('every group and month has its own progress', () {
      expect(
        monthSettleFlowFor(key()).id,
        'month_settle:${app.group.id}:2026-03',
      );
      expect(
        monthSettleFlowFor(key()),
        isNot(monthSettleFlowFor(key(const Month(2026, 2)))),
      );
    });

    test('a step needs the "seen" answer', () async {
      final flow = monthSettleFlowFor(key());
      await c.start(flow);
      expect(errorOf(await c.flow(flow).next()), isA<InvalidData>());
      expect(errorOf(await c.flow(flow).next(answer: 'x')), isA<InvalidData>());
      await c.answer(flow, true);
      expect(c.flowState(flow).step?.id, 'amounts');
    });
  });

  group('confirm', () {
    Future<void> review() async {
      final flow = monthSettleFlowFor(key());
      await c.start(flow);
      await c.answer(flow, true);
      await c.answer(flow, true);
    }

    test('settles the month and clears its flow', () async {
      await review();
      final done = ok(await vm().confirm(titleOf: title));
      expect(done.rideCount, 2);
      expect(done.expenses, hasLength(2));
      final fresh = app.container();
      addTearDown(fresh.dispose);
      final flow = monthSettleFlowFor(key());
      await fresh.start(flow);
      expect(fresh.flowState(flow).answers, isEmpty);
      expect(fresh.flowState(flow).finished, isFalse);
    });

    test('the undo of the settlement still works', () async {
      await review();
      final done = ok(await vm().confirm(titleOf: title));
      ok(await done.undo());
      await review();
      final again = ok(await vm().confirm(titleOf: title));
      expect(again.rideCount, 2);
    });

    test('unfinished review is a conflict and settles nothing', () async {
      await c.start(monthSettleFlowFor(key()));
      expect(
        errorOf(await vm().confirm(titleOf: title)),
        isA<Conflict>(),
      );
      expect(await app.expenses.watchExpenses(app.group.id).first, isEmpty);
    });

    test('nothing to settle is returned, the flow stays', () async {
      final flow = monthSettleFlowFor(key(const Month(2025, 1)));
      await c.start(flow);
      await c.answer(flow, true);
      await c.answer(flow, true);
      expect(
        errorOf(await vm(const Month(2025, 1)).confirm(titleOf: title)),
        isA<InvalidData>(),
      );
      expect(c.flowState(flow).finished, isTrue);
    });

    test('a failing store is returned and the review stays', () async {
      await review();
      app.rides.failWith = const Storage('disk');
      expect(
        errorOf(await vm().confirm(titleOf: title)),
        const Storage('disk'),
      );
      expect(c.flowState(monthSettleFlowFor(key())).finished, isTrue);
      app.rides.failWith = null;
      expect(ok(await vm().confirm(titleOf: title)).rideCount, 2);
    });

    test('a double tap settles once', () async {
      await review();
      final results = await Future.wait([
        vm().confirm(titleOf: title),
        vm().confirm(titleOf: title),
      ]);
      expect(
        results.whereType<Ok<SettledMonth, RepositoryError>>(),
        hasLength(1),
      );
    });
  });
}
