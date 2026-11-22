import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/features/rides/ui/commute_template_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../profile/ui/car_flow_support.dart';
import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

void main() {
  late RidesApp app;
  late ProviderContainer c;

  setUp(() {
    app = RidesApp();
    c = app.container();
    addTearDown(c.dispose);
  });

  RepositoryError errorOf(RepoResult<void> r) =>
      (r as Err<void, RepositoryError>).error;

  SetupFlowConfig flow() => commuteTemplateFlowFor(app.group.id);
  CommuteTemplateViewModel vm() =>
      c.read(commuteTemplateViewModelProvider(app.group.id).notifier);

  Future<void> answerAll({
    String name = ' Arbeit ',
    int meters = 12500,
    bool roundTrip = true,
  }) async {
    await c.start(flow());
    await c.answer(flow(), name);
    await c.answer(flow(), commuteRouteAnswer(meters, roundTrip: roundTrip));
    await c.answer(flow(), app.golf.id);
  }

  group('steps', () {
    test('five steps; the last two are optional', () {
      expect(
        [for (final s in commuteTemplateFlow.steps) s.id],
        ['name', 'route', 'vehicle', 'people', 'tolls'],
      );
      expect(
        [for (final s in commuteTemplateFlow.steps) s.skippable],
        [false, false, false, true, true],
      );
    });

    test('every group has its own progress', () {
      expect(commuteTemplateFlowFor('g1'), isNot(commuteTemplateFlowFor('g2')));
      expect(commuteTemplateFlowFor('g1').id, 'commute_template:g1');
    });

    test('name: not blank', () async {
      await app.seedVehicle();
      await c.start(flow());
      for (final bad in [null, ' ', 3]) {
        expect(
          errorOf(await c.flow(flow()).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
    });

    test('route: a distance above zero and a round-trip flag', () async {
      await app.seedVehicle();
      await c.start(flow());
      await c.answer(flow(), 'Arbeit');
      for (final bad in [
        null,
        12500,
        {'meters': 0, 'roundTrip': true},
        {'meters': -5, 'roundTrip': true},
        {'meters': 1000},
        {'meters': '1000', 'roundTrip': true},
      ]) {
        expect(
          errorOf(await c.flow(flow()).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
      await c.answer(flow(), commuteRouteAnswer(1000, roundTrip: false));
    });

    test('people: a driver or none and a list of passengers', () async {
      await app.seedVehicle();
      await answerAll();
      for (final bad in [
        'Ann',
        {'driver': 1, 'passengers': <String>[]},
        {'driver': null, 'passengers': 'Ben'},
      ]) {
        expect(
          errorOf(await c.flow(flow()).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
    });

    test('tolls: cents, not negative', () async {
      await app.seedVehicle();
      await answerAll();
      await c.skip(flow());
      expect(
        errorOf(await c.flow(flow()).next(answer: -1)),
        isA<InvalidData>(),
      );
      expect(
        errorOf(await c.flow(flow()).next(answer: 2.5)),
        isA<InvalidData>(),
      );
    });
  });

  group('save', () {
    test('stores the template with every answer', () async {
      await app.seedVehicle();
      await answerAll();
      await c.answer(
        flow(),
        commutePeopleAnswer(
          driverId: app.people[0].id,
          passengerIds: [app.people[1].id],
        ),
      );
      await c.answer(flow(), 250);
      final t = ok(await vm().save());
      expect(t.name, 'Arbeit');
      expect(t.distanceMeters, 12500);
      expect(t.roundTrip, isTrue);
      expect(t.vehicleId, app.golf.id);
      expect(t.defaultDriverId, app.people[0].id);
      expect(t.defaultPassengerIds, {app.people[1].id});
      expect(t.tollsCents, 250);
      final stored = await app.templates.watchTemplates(app.group.id).first;
      expect(stored, hasLength(1));
    });

    test('the optional steps skipped: no driver, no tolls', () async {
      await app.seedVehicle();
      await answerAll(roundTrip: false);
      await c.skip(flow());
      await c.skip(flow());
      final t = ok(await vm().save());
      expect(t.roundTrip, isFalse);
      expect(t.defaultDriverId, isNull);
      expect(t.defaultPassengerIds, isEmpty);
      expect(t.tollsCents, 0);
    });

    test('the driver is never also a passenger', () async {
      await app.seedVehicle();
      await answerAll();
      await c.answer(
        flow(),
        commutePeopleAnswer(
          driverId: app.people[0].id,
          passengerIds: [app.people[0].id, app.people[1].id],
        ),
      );
      await c.skip(flow());
      final t = ok(await vm().save());
      expect(t.defaultPassengerIds, {app.people[1].id});
    });

    test('clears the flow of this group only', () async {
      await app.seedVehicle();
      await answerAll();
      await c.skip(flow());
      await c.skip(flow());
      ok(await vm().save());
      final fresh = app.container();
      addTearDown(fresh.dispose);
      await fresh.start(flow());
      expect(fresh.flowState(flow()).answers, isEmpty);
    });

    test('unfinished answers are a conflict and store nothing', () async {
      await app.seedVehicle();
      await c.start(flow());
      expect(errorOf(await vm().save()), isA<Conflict>());
      expect(await app.templates.watchTemplates(app.group.id).first, isEmpty);
    });

    test('a failing store is returned and the answers stay', () async {
      await app.seedVehicle();
      await answerAll();
      await c.skip(flow());
      await c.skip(flow());
      app.templates.failWith = const Storage('disk');
      expect(errorOf(await vm().save()), const Storage('disk'));
      expect(c.flowState(flow()).answers['name'], ' Arbeit ');
      app.templates.failWith = null;
      expect(ok(await vm().save()).name, 'Arbeit');
    });

    test('a double tap stores one template', () async {
      await app.seedVehicle();
      await answerAll();
      await c.skip(flow());
      await c.skip(flow());
      final results = await Future.wait([vm().save(), vm().save()]);
      expect(
        results.whereType<Ok<RideTemplate, RepositoryError>>(),
        hasLength(1),
      );
      expect(
        await app.templates.watchTemplates(app.group.id).first,
        hasLength(1),
      );
    });
  });
}
