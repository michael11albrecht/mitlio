import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

void main() {
  late RidesApp app;
  late ProviderContainer container;

  RidesViewModel vm() =>
      container.read(ridesViewModelProvider(app.group.id).notifier);
  RidesLoaded loaded() =>
      container.read(ridesViewModelProvider(app.group.id)) as RidesLoaded;

  Future<void> open() async {
    container.listen(ridesViewModelProvider(app.group.id), (_, _) {});
    await pumpEventQueue();
  }

  String id(int i) => app.people[i].id;
  bool canDrive(int i) => loaded().member(id(i))!.canDrive;

  /// The owner's case: Ann drives Ben and Cy, then Ben drives Ann and Cy,
  /// 70 km round trips. Ann 0, Ben 0, Cy -280 km.
  Future<void> seedOwnerCase() async {
    await app.seedCommute();
    await app.ride(
      date: '2026-02-12',
      driver: 0,
      passengers: [1, 2],
      meters: 70000,
    );
    await app.ride(
      date: '2026-02-14',
      driver: 1,
      passengers: [0, 2],
      meters: 70000,
    );
  }

  /// Ann drives Ben once more, through the same command as the quick log.
  Future<void> logWithAnn() async {
    ok(
      await vm().logRide(
        driverId: id(0),
        templateId: app.work.id,
        passengerIds: {id(1)},
      ),
    );
    await pumpEventQueue();
  }

  setUp(() {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  group('who drives', () {
    test('owner case: the one who only rode along is next', () async {
      await seedOwnerCase();
      await open();
      expect(loaded().nextDriverId, id(2));
      expect(loaded().quick!.driverId, id(2));
      expect(loaded().driverCandidateIds, {id(0), id(1), id(2)});
      expect(loaded().fairness.every((r) => r.isDriverCandidate), isTrue);
    });

    test('a non-driver is not suggested and flagged in the fairness', () async {
      await seedOwnerCase();
      ok(await app.base.members.setCanDrive(id(2), canDrive: false));
      await open();
      // Ann and Ben tie at 0; Ann drove longest ago.
      expect(loaded().nextDriverId, id(0));
      expect(loaded().quick!.driverId, id(0));
      expect(loaded().nonDriverIds, {id(2)});
      expect(loaded().driverCandidateIds, {id(0), id(1)});
      expect(
        [
          for (final r in loaded().fairness) r.isDriverCandidate,
        ],
        [true, true, false],
      );
    });

    test('setCanDrive is visible in the state and undone by Undo', () async {
      await seedOwnerCase();
      await open();
      final undo = ok(await vm().setCanDrive(id(2), canDrive: false));
      await pumpEventQueue();
      expect(canDrive(2), isFalse);
      expect(loaded().nextDriverId, id(0));
      ok(await undo());
      await pumpEventQueue();
      expect(canDrive(2), isTrue);
      expect(loaded().nextDriverId, id(2));
    });

    test('setCanDrive for an unknown member is NotFound', () async {
      await seedOwnerCase();
      await open();
      expect(
        err(await vm().setCanDrive('nope', canDrive: false)),
        const NotFound('member', 'nope'),
      );
    });

    test('setCanDrive reports a failing repository', () async {
      await seedOwnerCase();
      await open();
      app.base.members.failWith = const Storage('disk');
      expect(
        err(await vm().setCanDrive(id(2), canDrive: false)),
        const Storage('disk'),
      );
      app.base.members.failWith = null;
      await pumpEventQueue();
      expect(canDrive(2), isTrue);
    });
  });

  group('driver prompt', () {
    /// Ben rides along with Ann again and again, and never drives.
    Future<void> seedPassenger(int rides) async {
      await app.seedCommute();
      for (var i = 0; i < rides; i++) {
        await app.ride(
          date: '2026-02-${(i + 1).toString().padLeft(2, '0')}',
          driver: 0,
          passengers: [1],
        );
      }
    }

    test('nothing is asked before a ride is logged', () async {
      await seedPassenger(6);
      await open();
      expect(loaded().driverPrompt, isNull);
    });

    test('after a logged ride the passenger is asked, once', () async {
      await seedPassenger(4);
      await open();
      await logWithAnn();
      await pumpEventQueue();
      final prompt = loaded().driverPrompt!;
      expect(prompt.memberId, id(1));
      expect(prompt.rides, greaterThanOrEqualTo(4));

      // Keeping them as a driver: no undo, never asked again.
      final kept = await vm().answerDriverPrompt(id(1), canDrive: true);
      expect((kept as Ok<Undo?, RepositoryError>).value, isNull);
      expect(loaded().driverPrompt, isNull);
      expect(canDrive(1), isTrue);
      await logWithAnn();
      expect(loaded().driverPrompt, isNull);
    });

    test('marking as non-driver offers undo', () async {
      await seedPassenger(4);
      await open();
      await logWithAnn();
      await pumpEventQueue();
      final undo = ok(await vm().answerDriverPrompt(id(1), canDrive: false));
      await pumpEventQueue();
      expect(canDrive(1), isFalse);
      expect(loaded().driverPrompt, isNull);
      ok(await undo!());
      await pumpEventQueue();
      expect(canDrive(1), isTrue);
      // Undo does not ask again.
      expect(loaded().driverPrompt, isNull);
    });

    test('too few rides, or a ride as driver, ask nothing', () async {
      await seedPassenger(2);
      await open();
      await logWithAnn();
      await pumpEventQueue();
      expect(loaded().driverPrompt, isNull);
    });

    test('a failing repository is reported and keeps the question', () async {
      await seedPassenger(4);
      await open();
      await logWithAnn();
      await pumpEventQueue();
      app.base.members.failWith = const Storage('disk');
      expect(
        err(await vm().answerDriverPrompt(id(1), canDrive: false)),
        const Storage('disk'),
      );
      expect(loaded().driverPrompt, isNotNull);
    });

    test('an unknown member is NotFound', () async {
      await seedPassenger(1);
      await open();
      expect(
        err(await vm().answerDriverPrompt('nope', canDrive: false)),
        const NotFound('member', 'nope'),
      );
    });
  });
}
