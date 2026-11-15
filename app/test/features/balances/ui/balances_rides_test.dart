import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';
import 'package:mitlio/features/rides/ui/ride_settle_view_model.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import '../../rides/ui/rides_fixtures.dart';

const _feb = Month(2026, 2);

String _title(String name, Month m) => 'Fahrten ${m.month}/${m.year} · $name';

/// Open rides count live in the balances: the numbers before and after
/// "Abrechnen" are the same.
void main() {
  late RidesApp app;
  late ProviderContainer container;

  String gid() => app.group.id;
  String id(int i) => app.people[i].id;

  BalancesState state() => container.read(balancesViewModelProvider(gid()));
  BalancesLoaded loaded() => state() as BalancesLoaded;

  Future<void> open() async {
    container.listen(balancesViewModelProvider(gid()), (_, _) {});
    await pumpEventQueue();
  }

  Map<String, int> cents() => {
    for (final b in loaded().balances) b.member.id: b.cents,
  };

  /// The domain fixture `examples:rides` (see ride_settle_view_model_test).
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

  Future<void> settleFeb() async {
    ok(
      await container
          .read(rideSettleViewModelProvider(gid()).notifier)
          .settle(_feb, titleOf: _title),
    );
    await pumpEventQueue();
  }

  setUp(() {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  test('a single open ride shows up at once, driver credited', () async {
    await app.seedCommute();
    await app.ride(date: '2026-02-05', driver: 0, passengers: [1]);
    await open();
    final b = loaded();
    expect(b.hasEntries, isTrue);
    expect(b.openRideCount, 1);
    final ben = b.balances.firstWhere((x) => x.member.id == id(1)).cents;
    final ann = b.balances.firstWhere((x) => x.member.id == id(0)).cents;
    expect(ben, lessThan(0));
    expect(ann, -ben);
    expect(b.openRideCents, greaterThan(0));
    expect(b.simplified, [
      Transfer(fromId: id(1), toId: id(0), amountCents: ann),
    ]);
  });

  test('no rides: empty state stays', () async {
    await app.seedCommute();
    await open();
    expect(loaded().hasEntries, isFalse);
    expect(loaded().openRideCount, 0);
  });

  test('balances before Abrechnen == after, per member', () async {
    await seedFixture();
    await open();
    final before = cents();
    final beforeTransfers = loaded().simplified;
    final beforePairwise = loaded().pairwise;
    expect(loaded().openRideCount, 3);
    expect(loaded().openRideCents, 936 + 457);
    expect(before.values.reduce((a, b) => a + b), 0);
    expect(before.values.any((c) => c != 0), isTrue);

    await settleFeb();
    final after = loaded();
    expect(cents(), before);
    expect(after.simplified, beforeTransfers);
    expect(after.pairwise, beforePairwise);
    expect(after.openRideCount, 0);
    expect(after.openRideCents, 0);
  });

  test('settled and open rides mix without double counting', () async {
    await seedFixture();
    await open();
    final feb = cents();
    await settleFeb();
    // A new open ride after the settlement.
    await app.ride(
      date: '2026-03-01',
      driver: 2,
      passengers: [0],
    );
    await pumpEventQueue();
    final mixed = loaded();
    expect(mixed.openRideCount, 1);
    final march = {
      for (final b in mixed.balances) b.member.id: b.cents - feb[b.member.id]!,
    };
    expect(march[id(2)], greaterThan(0));
    // Closing March changes nothing either.
    final before = cents();
    ok(
      await container
          .read(rideSettleViewModelProvider(gid()).notifier)
          .settle(const Month(2026, 3), titleOf: _title),
    );
    await pumpEventQueue();
    expect(cents(), before);
    expect(loaded().openRideCount, 0);
  });

  test('rides of several months equal one settlement per month', () async {
    await seedFixture();
    await app.ride(
      date: '2026-01-10',
      driver: 1,
      passengers: [2],
      meters: 9999,
    );
    await open();
    final before = cents();
    expect(loaded().openRideCount, 4);
    await settleFeb();
    ok(
      await container
          .read(rideSettleViewModelProvider(gid()).notifier)
          .settle(const Month(2026, 1), titleOf: _title),
    );
    await pumpEventQueue();
    expect(cents(), before);
  });

  test('a payment recorded before Abrechnen still nets after it', () async {
    await seedFixture();
    await open();
    final owing = loaded().simplified.first;
    ok(
      await app.base.settlements.create(
        gid(),
        SettlementDraft(
          fromId: owing.fromId,
          toId: owing.toId,
          amountCents: 100,
          currency: Currency.eur,
          date: DateTime.utc(2026, 2, 8),
          method: SettlementMethod.cash,
        ),
      ),
    );
    await pumpEventQueue();
    final before = cents();
    expect(loaded().openRideCount, 3);
    await settleFeb();
    expect(cents(), before);
    // Nothing is lost: 100 cents less owed than without the payment.
    expect(before[owing.fromId]! > -owing.amountCents, isTrue);
  });

  test('the settle screen shows the transfers of open rides', () async {
    await seedFixture();
    container.listen(settleViewModelProvider(gid()), (_, _) {});
    await pumpEventQueue();
    final s = container.read(settleViewModelProvider(gid()));
    expect(s, isA<SettleLoaded>());
    expect((s as SettleLoaded).transfers, isNotEmpty);
  });

  test('a ride of an unknown vehicle is skipped, no crash', () async {
    await seedFixture();
    // Deleting the vehicle behind the rides' back.
    await app.vehicles.softDelete(app.golf.id);
    await open();
    final b = loaded();
    expect(b.openRideCount, 0);
    expect(cents().values.every((c) => c == 0), isTrue);
  });

  test('failing rides stream becomes a failure state', () async {
    await seedFixture();
    app.rides.watchError = const Storage('boom');
    await open();
    expect(state(), isA<BalancesFailure>());
  });

  test('load() (DebugDrive) includes open rides', () async {
    await seedFixture();
    final result = await container
        .read(balancesViewModelProvider(gid()).notifier)
        .load();
    final b = ok(result);
    expect(b.openRideCount, 3);
    expect(b.balances.any((x) => x.cents != 0), isTrue);
  });
}
