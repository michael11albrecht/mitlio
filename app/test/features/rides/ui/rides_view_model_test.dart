import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

void main() {
  late RidesApp app;
  late ProviderContainer container;

  RidesViewModel vm() =>
      container.read(ridesViewModelProvider(app.group.id).notifier);
  RidesState state() => container.read(ridesViewModelProvider(app.group.id));
  RidesLoaded loaded() => state() as RidesLoaded;
  QuickLog quick() => loaded().quick!;

  Future<void> open() async {
    container.listen(ridesViewModelProvider(app.group.id), (_, _) {});
    await pumpEventQueue();
  }

  String id(int i) => app.people[i].id;

  setUp(() {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  group('state', () {
    test('loading, then loaded', () async {
      await app.seedCommute();
      container.listen(ridesViewModelProvider(app.group.id), (_, _) {});
      expect(state(), isA<RidesLoading>());
      await pumpEventQueue();
      final s = loaded();
      expect(s.group.name, 'Pendler');
      expect(s.members.map((m) => m.name), ['Ann', 'Ben', 'Cy']);
      expect(s.templates.single.name, 'Arbeit');
      expect(s.month, const Month(2026, 3));
      expect(s.today, DateTime.utc(2026, 3));
      expect(s.isOnboarding, isFalse);
    });

    test(
      'a group without templates is onboarding and has no quick log',
      () async {
        await app.seedVehicle();
        await open();
        expect(loaded().isOnboarding, isTrue);
        expect(loaded().quick, isNull);
        expect(loaded().vehicles.single.name, 'Golf');
      },
    );

    test('a group without members has no quick log', () async {
      app.group = ok(
        await app.base.groups.create(
          name: 'Leer',
          currency: Currency.eur,
          createdBy: 'dev',
        ),
      );
      await open();
      expect(loaded().hasMembers, isFalse);
      expect(loaded().quick, isNull);
    });

    test('an unknown group fails with NotFound', () async {
      await app.seedCommute();
      container.listen(ridesViewModelProvider('nope'), (_, _) {});
      await pumpEventQueue();
      expect(
        (container.read(ridesViewModelProvider('nope')) as RidesFailure).error,
        isA<NotFound>(),
      );
    });

    test('a failing stream fails the state, retry reloads', () async {
      await app.seedCommute();
      app.rides.watchError = const Storage('disk');
      await open();
      expect((state() as RidesFailure).error, const Storage('disk'));
      app.rides.watchError = null;
      vm().retry();
      expect(state(), isA<RidesLoading>());
      await pumpEventQueue();
      expect(state(), isA<RidesLoaded>());
    });

    test('a failing stream with a plain error is wrapped in Storage', () async {
      await app.seedCommute();
      app.rides.watchError = StateError('x');
      await open();
      expect((state() as RidesFailure).error, isA<Storage>());
    });
  });

  group('quick log defaults', () {
    test('one template is pre-selected with the template defaults', () async {
      await app.seedCommute();
      await open();
      final q = quick();
      expect(q.template?.name, 'Arbeit');
      expect(q.driverId, id(0));
      expect(q.passengerIds, {id(1)});
      expect(q.priceMilli, 1750);
      expect(q.isToday, isTrue);
      expect(q.collapsed, isFalse);
      expect(q.canSave, isTrue);
      expect(q.usesKmRate, isFalse);
      // 2 x 20 km at 6,5 l/100 km and 1,75 EUR/l: 4,55 EUR, Ann bears the
      // odd cent (earlier in member order).
      expect(q.preview?.totalCents, 455);
      expect(
        [
          for (final s in q.preview!.owes) (s.memberId, s.cents),
        ],
        [(id(1), 227)],
      );
    });

    test('several templates: nothing is picked until the user picks', () async {
      await app.seedCommute();
      ok(
        await app.templates.add(
          app.group.id,
          RideTemplate(
            id: '',
            name: 'Training',
            distanceMeters: 8000,
            vehicleId: app.golf.id,
          ),
        ),
      );
      await open();
      expect(quick().template, isNull);
      expect(quick().canSave, isFalse);
      expect(quick().driverId, isNull);
      expect(
        (await vm().saveQuickLog()),
        isA<Err<LoggedRide, RepositoryError>>(),
      );

      vm().selectTemplate(loaded().templates.last.id);
      expect(quick().template?.name, 'Training');
      expect(quick().canSave, isTrue);
      expect(quick().passengerIds, isEmpty);
      expect(quick().preview?.owes, isEmpty);
    });

    test(
      'the fuel price is frozen from the last ride with the vehicle',
      () async {
        await app.seedCommute();
        await app.ride(date: '2026-02-20', driver: 0, priceMilli: 1799);
        await app.ride(date: '2026-02-10', driver: 0, priceMilli: 1700);
        await open();
        expect(quick().priceMilli, 1799);
      },
    );

    test('a km rate vehicle needs no fuel price', () async {
      await app.seedGroup();
      final km = ok(
        await app.vehicles.add(
          app.group.id,
          name: 'Firmenwagen',
          fuelType: FuelType.diesel,
          consumptionMilliPer100km: 5000,
          kmRateMilliPerKm: 300,
        ),
      );
      ok(
        await app.templates.add(
          app.group.id,
          RideTemplate(
            id: '',
            name: 'Kunde',
            distanceMeters: 10000,
            vehicleId: km.id,
            defaultDriverId: id(0),
            defaultPassengerIds: {id(1)},
          ),
        ),
      );
      await open();
      expect(quick().usesKmRate, isTrue);
      // 10 km at 0,30 EUR/km.
      expect(quick().preview?.totalCents, 300);
    });

    test('a ride today collapses the card, expand reopens it', () async {
      await app.seedCommute();
      await app.ride(date: app.today, driver: 0, passengers: [1]);
      await open();
      expect(quick().collapsed, isTrue);
      vm().expand();
      expect(quick().collapsed, isFalse);
    });

    test('rides on other days do not collapse the card', () async {
      await app.seedCommute();
      await app.ride(date: '2026-02-28', driver: 0, passengers: [1]);
      await open();
      expect(quick().collapsed, isFalse);
    });
  });

  group('smart driver', () {
    test('without history only the default driver can be suggested', () async {
      await app.seedCommute();
      await open();
      expect(quick().driverId, id(0));
    });

    test('alternates fairly once a second person drove the car', () async {
      await app.seedCommute();
      // Ann drove three days, Ben once: Ann +120 km, Ben -80 km.
      await app.ride(date: '2026-02-23', driver: 0, passengers: [1]);
      await app.ride(date: '2026-02-24', driver: 0, passengers: [1]);
      await app.ride(date: '2026-02-25', driver: 1, passengers: [0]);
      await app.ride(date: '2026-02-26', driver: 0, passengers: [1]);
      await open();
      // Balances: Ann 3 x 40 - 40 = +80, Ben 40 - 120 = -80.
      expect(quick().driverId, id(1));
      // The carpool follows: Ann rides along.
      expect(quick().passengerIds, {id(0)});
    });

    test('settled rides do not count towards the balance', () async {
      await app.seedCommute();
      final settled = [
        await app.ride(date: '2026-02-23', driver: 0, passengers: [1]),
        await app.ride(date: '2026-02-24', driver: 0, passengers: [1]),
      ];
      await app.ride(date: '2026-02-25', driver: 1, passengers: [0]);
      final expense = ok(
        await app.expenses.create(
          app.group.id,
          ExpenseDraft(
            title: 'Februar',
            amountCents: 100,
            currency: Currency.eur,
            date: DateTime.utc(2026, 2, 28),
            payers: {id(0): 100},
            split: EqualSplit({id(0), id(1)}),
          ),
        ),
      );
      ok(
        await app.rides.markSettled([
          for (final e in settled) e.ride.id,
        ], expense.expense.id),
      );
      await open();
      // Open: Ben drove once, Ann rode once: Ben +40, Ann -40.
      expect(quick().driverId, id(0));
    });

    test('the manual choice wins and resets the passengers', () async {
      await app.seedCommute();
      await open();
      vm().togglePassenger(id(2));
      expect(quick().passengerIds, {id(1), id(2)});
      vm().selectDriver(id(1));
      expect(quick().driverId, id(1));
      // Ann (the usual driver) rides along, Cy was a one-off.
      expect(quick().passengerIds, {id(0)});
    });

    test('toggling a passenger off and on', () async {
      await app.seedCommute();
      await open();
      vm().togglePassenger(id(1));
      expect(quick().passengerIds, isEmpty);
      expect(quick().preview?.owes, isEmpty);
      vm().togglePassenger(id(1));
      expect(quick().passengerIds, {id(1)});
    });

    test('a template without a driver falls back to its carpool', () async {
      await app.seedCommute(defaultDriver: null, passengers: {'Ben', 'Cy'});
      await open();
      // Ben and Cy tie; the earlier member drives.
      expect(quick().driverId, id(1));
      expect(quick().passengerIds, {id(2)});
    });

    test(
      'a template without driver and passengers falls back to everyone',
      () async {
        await app.seedCommute(defaultDriver: null, passengers: {});
        await open();
        expect(quick().driverId, id(0));
        expect(quick().passengerIds, isEmpty);
      },
    );
  });

  group('overrides', () {
    test('price override and reset', () async {
      await app.seedCommute();
      await open();
      vm().setPrice(2000);
      expect(quick().priceMilli, 2000);
      expect(quick().preview?.totalCents, 520);
      vm().setPrice(null);
      expect(quick().priceMilli, 1750);
    });

    test('logging for another day and back', () async {
      await app.seedCommute();
      await open();
      vm().setDate(DateTime(2026, 2, 27, 18));
      expect(quick().isToday, isFalse);
      expect(quick().date, DateTime.utc(2026, 2, 27));
      vm().setDate(null);
      expect(quick().isToday, isTrue);
    });

    test('picking a template resets the other overrides', () async {
      await app.seedCommute();
      await open();
      vm()
        ..setPrice(2000)
        ..selectTemplate(app.work.id);
      expect(quick().priceMilli, 1750);
    });

    test('toggling a passenger without a quick log does nothing', () async {
      await app.seedVehicle();
      await open();
      vm().togglePassenger(id(1));
      expect(loaded().quick, isNull);
    });
  });

  group('saveQuickLog', () {
    test(
      'stores the ride, tells who pays what and collapses the card',
      () async {
        await app.seedCommute();
        await open();
        final logged = ok(await vm().saveQuickLog());
        await pumpEventQueue();
        expect(logged.driverName, 'Ann');
        expect(logged.totalCents, 455);
        expect(logged.owes, [(name: 'Ben', cents: 227)]);
        expect(logged.currency, Currency.eur);

        final stored = loaded().entries.single;
        expect(stored.ride.driverId, id(0));
        expect(stored.ride.passengerIds, {id(1)});
        expect(stored.ride.pricePerUnitMilli, 1750);
        expect(stored.ride.distanceMeters, 20000);
        expect(stored.ride.roundTrip, isTrue);
        expect(stored.ride.date, DateTime.utc(2026, 3));
        expect(quick().collapsed, isTrue);
        expect(quick().saving, isFalse);
      },
    );

    test('undo deletes the ride again', () async {
      await app.seedCommute();
      await open();
      final logged = ok(await vm().saveQuickLog());
      ok(await logged.undo());
      await pumpEventQueue();
      expect(loaded().entries, isEmpty);
      expect(quick().collapsed, isFalse);
    });

    test('a backdated ride keeps the card open', () async {
      await app.seedCommute();
      await open();
      vm().setDate(DateTime.utc(2026, 2, 27));
      ok(await vm().saveQuickLog());
      await pumpEventQueue();
      expect(loaded().entries.single.ride.date, DateTime.utc(2026, 2, 27));
      expect(quick().isToday, isTrue);
      expect(quick().collapsed, isFalse);
    });

    test(
      'repository failure is reported and the card stays as it was',
      () async {
        await app.seedCommute();
        await open();
        vm().setPrice(1999);
        app.rides.failWith = const Storage('disk');
        expect(err(await vm().saveQuickLog()), const Storage('disk'));
        expect(loaded().entries, isEmpty);
        expect(quick().saving, isFalse);
        expect(quick().priceMilli, 1999);
        expect(quick().canSave, isTrue);
      },
    );

    test('without a template the save is refused', () async {
      await app.seedVehicle();
      await open();
      expect(err(await vm().saveQuickLog()), isA<InvalidData>());
    });
  });

  group('logRide', () {
    test('works before the screen has loaded (DebugDrive)', () async {
      await app.seedCommute();
      final logged = ok(
        await vm().logRide(
          driverId: id(1),
          templateId: app.work.id,
          date: DateTime.utc(2026, 2, 12),
        ),
      );
      // Passengers default to the carpool without the driver: Ann and Ben
      // swap seats.
      expect(logged.entry.ride.passengerIds, {id(0)});
      expect(logged.entry.ride.date, DateTime.utc(2026, 2, 12));
      expect(logged.owes.single.name, 'Ann');
    });

    test('explicit passengers, price and a one-off vehicle ride', () async {
      await app.seedCommute();
      final logged = ok(
        await vm().logRide(
          driverId: id(0),
          vehicleId: app.golf.id,
          distanceMeters: 10000,
          tollsCents: 200,
          passengerIds: {id(1), id(2)},
          priceMilli: 2000,
        ),
      );
      expect(logged.entry.ride.roundTrip, isFalse);
      expect(logged.entry.ride.tollsCents, 200);
      expect(logged.entry.ride.pricePerUnitMilli, 2000);
      expect(logged.owes.map((o) => o.name), ['Ben', 'Cy']);
    });

    test('needs a template or a vehicle with a distance', () async {
      await app.seedCommute();
      expect(err(await vm().logRide(driverId: id(0))), isA<InvalidData>());
    });

    test('unknown template, vehicle, driver and group', () async {
      await app.seedCommute();
      expect(
        err(await vm().logRide(driverId: id(0), templateId: 'nope')),
        isA<NotFound>(),
      );
      expect(
        err(
          await vm().logRide(
            driverId: id(0),
            vehicleId: 'nope',
            distanceMeters: 1000,
          ),
        ),
        isA<NotFound>(),
      );
      expect(
        err(await vm().logRide(driverId: 'nobody', templateId: app.work.id)),
        isA<InvalidData>(),
      );
      expect(
        err(
          await container
              .read(ridesViewModelProvider('nope').notifier)
              .logRide(driverId: id(0), templateId: app.work.id),
        ),
        isA<NotFound>(),
      );
    });

    test('the domain refuses a driver among the passengers', () async {
      await app.seedCommute();
      expect(
        err(
          await vm().logRide(
            driverId: id(0),
            templateId: app.work.id,
            passengerIds: {id(0)},
          ),
        ),
        isA<InvalidData>(),
      );
      expect(
        app.rides.watchRides(app.group.id, Month(2026, 3)),
        emits(isEmpty),
      );
    });

    test('a storage failure while reading becomes Err(Storage)', () async {
      await app.seedCommute();
      app.rides.watchError = const Storage('disk');
      expect(
        err(await vm().logRide(driverId: id(0), templateId: app.work.id)),
        const Storage('disk'),
      );
    });
  });

  group('calendar', () {
    test('shiftMonth moves across year boundaries', () async {
      await app.seedCommute();
      await open();
      vm().shiftMonth(-3);
      expect(loaded().month, const Month(2025, 12));
      vm().shiftMonth(1);
      expect(loaded().month, const Month(2026, 1));
      vm().shiftMonth(12);
      expect(loaded().month, const Month(2027, 1));
    });

    test('shiftMonth before the state loaded does nothing', () async {
      await app.seedCommute();
      container.listen(ridesViewModelProvider(app.group.id), (_, _) {});
      vm().shiftMonth(1);
      await pumpEventQueue();
      expect(loaded().month, const Month(2026, 3));
    });

    test('month entries, days and drivers', () async {
      await app.seedCommute();
      await app.ride(date: '2026-02-27', driver: 0, passengers: [1]);
      await app.ride(date: '2026-03-02', driver: 0, passengers: [1]);
      await app.ride(date: '2026-03-02', driver: 1, passengers: [0]);
      await app.ride(date: '2026-03-03', driver: 1, passengers: [0]);
      await open();
      final s = loaded();
      expect(s.monthEntries, hasLength(3));
      expect(s.entriesOn(DateTime.utc(2026, 3, 2)), hasLength(2));
      expect(s.driversOn(DateTime.utc(2026, 3, 2)), [id(0), id(1)]);
      expect(s.driversOn(DateTime.utc(2026, 3, 9)), isEmpty);
      expect(s.member(id(2))?.name, 'Cy');
      expect(s.member('x'), isNull);
      vm().shiftMonth(-1);
      expect(loaded().monthEntries, hasLength(1));
    });

    test('summary of a ride, null for an unknown vehicle', () async {
      await app.seedCommute();
      final entry = await app.ride(
        date: '2026-03-02',
        driver: 0,
        passengers: [1],
      );
      await open();
      expect(loaded().summary(entry)?.totalCents, 455);
      final ghost = RideEntry(
        groupId: app.group.id,
        createdAt: DateTime.utc(2026),
        ride: Ride(
          id: 'g',
          date: DateTime.utc(2026, 3),
          distanceMeters: 1000,
          vehicleId: 'gone',
          driverId: id(0),
          pricePerUnitMilli: 1000,
        ),
      );
      expect(loaded().summary(ghost), isNull);
    });
  });

  group('deleteRide', () {
    test('removes the row at once, undo brings it back', () async {
      await app.seedCommute();
      final entry = await app.ride(
        date: '2026-03-02',
        driver: 0,
        passengers: [1],
      );
      await open();
      final undo = ok(await vm().deleteRide(entry.ride.id));
      expect(loaded().entries, isEmpty);
      ok(await undo());
      await pumpEventQueue();
      expect(loaded().entries, hasLength(1));
    });

    test('repository failure brings the row back', () async {
      await app.seedCommute();
      final entry = await app.ride(
        date: '2026-03-02',
        driver: 0,
        passengers: [1],
      );
      await open();
      app.rides.failWith = const Storage('disk');
      expect(err(await vm().deleteRide(entry.ride.id)), const Storage('disk'));
      expect(loaded().entries, hasLength(1));
    });

    test('rides of a settled period are locked', () async {
      await app.seedCommute();
      final entry = await app.ride(
        date: '2026-03-02',
        driver: 0,
        passengers: [1],
      );
      final expense = ok(
        await app.expenses.create(
          app.group.id,
          ExpenseDraft(
            title: 'Maerz',
            amountCents: 100,
            currency: Currency.eur,
            date: DateTime.utc(2026, 3, 31),
            payers: {id(0): 100},
            split: EqualSplit({id(0), id(1)}),
          ),
        ),
      );
      ok(await app.rides.markSettled([entry.ride.id], expense.expense.id));
      await open();
      expect(loaded().entries.single.isSettled, isTrue);
      expect(err(await vm().deleteRide(entry.ride.id)), isA<Locked>());
      expect(loaded().entries, hasLength(1));
    });
  });

  group('list', () {
    test('rides of a month', () async {
      await app.seedCommute();
      await app.ride(date: '2026-02-27', driver: 0);
      await app.ride(date: '2026-03-02', driver: 0);
      final list = ok(await vm().list(const Month(2026, 3)));
      expect(list.map((e) => e.ride.date), [DateTime.utc(2026, 3, 2)]);
    });

    test('a failing stream is an error', () async {
      await app.seedCommute();
      app.rides.watchError = const Storage('disk');
      expect(
        err(await vm().list(const Month(2026, 3))),
        const Storage('disk'),
      );
      app.rides.watchError = StateError('x');
      expect(err(await vm().list(const Month(2026, 3))), isA<Storage>());
    });
  });

  group('debugSnapshot', () {
    test('loading and error', () async {
      await app.seedCommute();
      app.rides.watchError = const Storage('disk');
      container.listen(ridesViewModelProvider(app.group.id), (_, _) {});
      expect(vm().debugSnapshot()['status'], 'loading');
      await pumpEventQueue();
      expect(vm().debugSnapshot()['status'], 'error');
    });

    test('empty and data', () async {
      await app.seedVehicle();
      await open();
      expect(vm().debugSnapshot()['status'], 'empty');
      expect(vm().debugSnapshot()['quick'], isNull);

      await app.seedCommute();
      final other = container.read(
        ridesViewModelProvider(app.group.id).notifier,
      );
      container.listen(ridesViewModelProvider(app.group.id), (_, _) {});
      await pumpEventQueue();
      await app.ride(date: '2026-03-02', driver: 0, passengers: [1]);
      await pumpEventQueue();
      final snap = other.debugSnapshot();
      expect(snap['status'], 'data');
      expect(snap['month'], '2026-03');
      expect(snap['templates'], 1);
      expect(snap['rides'], hasLength(1));
      final q = snap['quick']! as Map<String, Object?>;
      expect(q['date'], '2026-03-01');
      expect(q['canSave'], isTrue);
    });
  });

  group('hasRideTemplatesProvider', () {
    test('follows the templates of the group', () async {
      await app.seedVehicle();
      final seen = <bool>[];
      container.listen(
        hasRideTemplatesProvider(app.group.id),
        (_, next) {
          if (next.hasValue) seen.add(next.value!);
        },
        fireImmediately: true,
      );
      await pumpEventQueue();
      ok(
        await app.templates.add(
          app.group.id,
          RideTemplate(
            id: '',
            name: 'A',
            distanceMeters: 1000,
            vehicleId: app.golf.id,
          ),
        ),
      );
      await pumpEventQueue();
      expect(seen.last, isTrue);
      expect(seen.first, isFalse);
    });
  });
}
