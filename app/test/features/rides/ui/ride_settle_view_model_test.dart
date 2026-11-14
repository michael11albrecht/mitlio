import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/rides/ui/ride_settle_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

const _feb = Month(2026, 2);

String _title(String name, Month m) => 'Fahrten ${m.month}/${m.year} · $name';

void main() {
  late RidesApp app;
  late ProviderContainer container;

  RideSettleViewModel vm() =>
      container.read(rideSettleViewModelProvider(app.group.id).notifier);
  RidesViewModel rides() =>
      container.read(ridesViewModelProvider(app.group.id).notifier);
  RidesLoaded loaded() =>
      container.read(ridesViewModelProvider(app.group.id)) as RidesLoaded;

  String id(int i) => app.people[i].id;

  /// The domain fixture `examples:rides`, moved to February (the fake clock
  /// says 2026-03-01, so February is over).
  Future<void> seedFixture() async {
    await app.seedCommute();
    await app.ride(
      date: '2026-02-05',
      driver: 0,
      passengers: [1],
      priceMilli: 1799,
    );
    await app.ride(
      date: '2026-02-06',
      driver: 1,
      passengers: [0, 2],
      priceMilli: 1759,
    );
    await app.ride(
      date: '2026-02-07',
      driver: 0,
      passengers: [1, 2],
      priceMilli: 1799,
    );
  }

  Future<void> open() async {
    container.listen(ridesViewModelProvider(app.group.id), (_, _) {});
    await pumpEventQueue();
    rides().shiftMonth(-1);
  }

  Future<List<ExpenseEntry>> expenses() =>
      app.expenses.watchExpenses(app.group.id).first;

  setUp(() {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  group('preview', () {
    test('equals the domain fixture examples:rides', () async {
      await seedFixture();
      await open();
      final plan = loaded().settlementPlan!;
      expect(plan.period, _feb);
      expect(plan.rideCount, 3);
      expect(plan.totalCents, 936 + 457);
      final a = plan.drivers[0];
      expect(a.driverId, id(0));
      expect(a.totalCents, 936);
      expect(a.rideCount, 2);
      expect(a.aggregate.shares, {id(0): 390, id(1): 390, id(2): 156});
      final b = plan.drivers[1];
      expect(b.driverId, id(1));
      expect(b.totalCents, 457);
      expect(b.aggregate.shares, {id(0): 153, id(1): 152, id(2): 152});
      // The driver's own part owes nobody.
      expect(
        [
          for (final s in a.sharesOf([id(0), id(1), id(2)]))
            (s.memberId, s.cents),
        ],
        [(id(1), 390), (id(2), 156)],
      );
    });

    test('only unsettled rides of the shown month count', () async {
      await seedFixture();
      final other = await app.ride(date: '2026-03-01', driver: 2);
      final settled = await app.ride(
        date: '2026-02-09',
        driver: 2,
        passengers: [0],
      );
      await app.settle([settled.ride.id]);
      await open();
      expect(loaded().settlementPlan!.rideCount, 3);
      expect(loaded().entries.any((e) => e.ride.id == other.ride.id), isTrue);
    });

    test('is null for an empty or settled month', () async {
      await app.seedCommute();
      await open();
      expect(loaded().settlementPlan, isNull);
      final r = await app.ride(date: '2026-02-05', driver: 0, passengers: [1]);
      await app.settle([r.ride.id]);
      await pumpEventQueue();
      expect(loaded().settlementPlan, isNull);
    });

    test('the card waits for the end of the month', () async {
      await seedFixture();
      await open();
      expect(loaded().isMonthOver, isTrue);
      rides().shiftMonth(1);
      expect(loaded().month, const Month(2026, 3));
      expect(loaded().isMonthOver, isFalse);
      app.base.clock.value = DateTime.utc(2026, 3, 31, 9);
      // The clock is read when the state is built.
      rides().shiftMonth(0);
      expect(loaded().isMonthOver, isTrue);
    });
  });

  group('settle', () {
    test('creates one trip expense per driver and locks the rides', () async {
      await seedFixture();
      final result = await vm().settle(_feb, titleOf: _title);
      final done = ok(result);
      expect(done.rideCount, 3);
      expect(done.expenses, hasLength(2));
      final [a, b] = done.expenses;
      expect(a.expense.title, 'Fahrten 2/2026 · Ann');
      expect(a.expense.amountCents, 936);
      expect(a.expense.payers, {id(0): 936});
      expect(a.expense.shares, {id(0): 390, id(1): 390, id(2): 156});
      expect(a.expense.date, DateTime.utc(2026, 2, 28));
      expect(b.expense.title, 'Fahrten 2/2026 · Ben');
      expect(b.expense.payers, {id(1): 457});
      expect(b.expense.shares, {id(0): 153, id(1): 152, id(2): 152});
      final meta = jsonDecode(a.tripMeta!) as Map<String, dynamic>;
      expect(meta['period'], '2026-02');
      expect(meta['rideIds'], hasLength(2));

      final stored = await app.entriesIn(_feb);
      expect(stored.every((e) => e.isSettled), isTrue);
      expect(await expenses(), hasLength(2));
      expect(
        container.read(rideSettleViewModelProvider(app.group.id)),
        isFalse,
      );
    });

    test('undo deletes the expenses and unlocks the rides', () async {
      await seedFixture();
      final done = ok(await vm().settle(_feb, titleOf: _title));
      ok(await done.undo());
      expect(await expenses(), isEmpty);
      expect((await app.entriesIn(_feb)).any((e) => e.isSettled), isFalse);
      // And the month can be settled again.
      expect(
        ok(await vm().settle(_feb, titleOf: _title)).expenses,
        hasLength(2),
      );
    });

    test('settling again only picks up rides logged since', () async {
      await seedFixture();
      ok(await vm().settle(_feb, titleOf: _title));
      final late = await app.ride(
        date: '2026-02-20',
        driver: 2,
        passengers: [0, 1],
      );
      final second = ok(await vm().settle(_feb, titleOf: _title));
      expect(second.rideCount, 1);
      final entry = second.expenses.single;
      expect(entry.expense.payers.keys, [id(2)]);
      expect((await app.entriesIn(_feb)).every((e) => e.isSettled), isTrue);
      expect(
        (await app.entriesIn(_feb))
            .firstWhere((e) => e.ride.id == late.ride.id)
            .settledExpenseId,
        entry.expense.id,
      );
      expect(await expenses(), hasLength(3));
    });

    test('a month in progress is dated today', () async {
      await seedFixture();
      await app.ride(date: '2026-03-01', driver: 0, passengers: [1]);
      final done = ok(await vm().settle(const Month(2026, 3), titleOf: _title));
      expect(done.expenses.single.expense.date, DateTime.utc(2026, 3));
    });

    test('nothing to settle is a validation error', () async {
      await app.seedCommute();
      expect(
        err(await vm().settle(_feb, titleOf: _title)),
        const InvalidData('nothing to settle'),
      );
      expect(await expenses(), isEmpty);
    });

    test('a failing repository changes nothing', () async {
      await seedFixture();
      app.rides.failWith = const Storage('disk');
      expect(
        err(await vm().settle(_feb, titleOf: _title)),
        const Storage('disk'),
      );
      app.rides.failWith = null;
      expect(await expenses(), isEmpty);
      expect((await app.entriesIn(_feb)).any((e) => e.isSettled), isFalse);
      // The button is usable again.
      expect(
        container.read(rideSettleViewModelProvider(app.group.id)),
        isFalse,
      );
      ok(await vm().settle(_feb, titleOf: _title));
    });

    test('a failing read is reported', () async {
      await seedFixture();
      app.rides.watchError = const Storage('disk');
      expect(
        err(await vm().settle(_feb, titleOf: _title)),
        const Storage('disk'),
      );
      app.rides.watchError = StateError('boom');
      expect(err(await vm().settle(_feb, titleOf: _title)), isA<Storage>());
    });

    test('an unknown group is NotFound', () async {
      await seedFixture();
      final other = container.read(
        rideSettleViewModelProvider('nope').notifier,
      );
      expect(
        err(await other.settle(_feb, titleOf: _title)),
        const NotFound('group', 'nope'),
      );
    });

    test('a second tap while running is refused', () async {
      await seedFixture();
      final first = vm().settle(_feb, titleOf: _title);
      expect(container.read(rideSettleViewModelProvider(app.group.id)), isTrue);
      expect(err(await vm().settle(_feb, titleOf: _title)), isA<Conflict>());
      ok(await first);
      expect(await expenses(), hasLength(2));
    });
  });

  group('fairness', () {
    test('km driven, km ridden and the net of the shown month', () async {
      await seedFixture();
      await open();
      final rows = {for (final r in loaded().fairness) r.memberId: r};
      // 40 km per ride.
      expect(rows[id(0)]!.metersDriven, 80000);
      expect(rows[id(0)]!.metersRidden, 40000);
      expect(rows[id(1)]!.metersDriven, 40000);
      expect(rows[id(1)]!.metersRidden, 80000);
      expect(rows[id(2)]!.metersDriven, 0);
      expect(rows[id(2)]!.metersRidden, 80000);
      // Ann: drove for 936 and owes her 390, plus 153 to Ben.
      expect(rows[id(0)]!.netCents, 936 - 390 - 153);
      expect(rows[id(1)]!.netCents, 457 - 152 - 390);
      expect(rows[id(2)]!.netCents, -156 - 152);
      expect(rows.values.fold(0, (n, r) => n + r.netCents), 0);
    });

    test('settled rides count too', () async {
      await seedFixture();
      ok(await vm().settle(_feb, titleOf: _title));
      await open();
      expect(loaded().fairness.fold(0, (n, r) => n + r.metersDriven), 120000);
    });

    test('debug JSON for a month', () async {
      await seedFixture();
      final json = ok(await vm().fairness(_feb));
      expect(json['month'], '2026-02');
      final rows = json['rows']! as List;
      expect(rows, hasLength(3));
      expect((rows.first as Map)['metersDriven'], 80000);
    });

    test('debug JSON reports a failing read', () async {
      await seedFixture();
      app.rides.watchError = const Storage('disk');
      expect(err(await vm().fairness(_feb)), const Storage('disk'));
    });

    test('next driver is the quick log rule, not the hand pick', () async {
      await seedFixture();
      await open();
      final s = loaded();
      expect(s.nextDriverId, s.quick!.driverId);
      rides().selectDriver(id(2));
      expect(loaded().quick!.driverId, id(2));
      expect(loaded().nextDriverId, s.quick!.driverId);
    });

    test('next driver needs a route and a member', () async {
      await app.seedVehicle();
      await open();
      expect(loaded().nextDriverId, isNull);
    });

    test(
      'next driver falls back to the first route when none is picked',
      () async {
        await app.seedCommute();
        await app.addRoute('Training');
        await open();
        expect(loaded().quick!.template, isNull);
        expect(loaded().nextDriverId, isNotNull);
      },
    );
  });
}
