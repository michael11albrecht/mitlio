import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/fakes/fake_route_distance_service.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/routes/data/route_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../repo_test_support.dart';

const _toggle = 'Start und Ziel eingeben, Strecke berechnen';
const _credit =
    'Karten- und Routendaten © OpenStreetMap-Mitwirkende, via openrouteservice';

/// "Strecke berechnen" in the commute template flow and the trip form, on the
/// real app with the fake route backend (German).
void main() {
  late FakeApp app;
  late Group pendeln;

  setUp(() async {
    app = FakeApp();
    pendeln = ok(
      await app.groups.create(
        name: 'Pendeln',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    for (final n in ['Anna', 'Ben']) {
      ok(await app.members.add(pendeln.id, name: n));
    }
  });

  void formTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        tester.view
          ..physicalSize = const Size(800, 2600)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await body(tester);
      });

  /// The route step of the commute template flow (name answered).
  Future<void> openTemplateForm(
    WidgetTester tester, {
    bool backend = true,
  }) async {
    await pumpMitlio(
      tester,
      app,
      location: '/groups/${pendeln.id}/rides/templates/new',
      extra: [
        // The flow reads the group's routes (the helper app has none).
        rideTemplatesRepositoryProvider.overrideWithValue(
          FakeRideTemplatesRepository(
            groups: app.groups,
            members: app.members,
            vehicles: app.vehicles,
            ids: SequentialIdGenerator(),
          ),
        ),
        if (backend) ...app.routeOverrides,
      ],
    );
    // A second visit resumes on the route step: the name is already answered.
    final name = find.widgetWithText(TextField, 'Name');
    if (name.evaluate().isNotEmpty) {
      await tester.enterText(name, 'Arbeit');
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> openTripForm(WidgetTester tester) async {
    await pumpMitlio(
      tester,
      app,
      location: '/groups/${pendeln.id}',
      extra: app.routeOverrides,
    );
    await tester.tap(find.byTooltip('Fahrt hinzufügen'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  String text(WidgetTester tester, String label) =>
      tester.widget<TextField>(field(label)).controller!.text;

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text(_toggle));
    await tester.pumpAndSettle();
  }

  Future<void> choose(
    WidgetTester tester,
    String label,
    String typed,
    PlaceSuggestion place,
  ) async {
    await tester.enterText(field(label), typed);
    await tester.pumpAndSettle();
    await tester.tap(find.text(place.label));
    await tester.pumpAndSettle();
  }

  const ka = FakeRouteDistanceService.karlsruhe;
  const st = FakeRouteDistanceService.stuttgart;
  const be = FakeRouteDistanceService.berlin;

  group('template form', () {
    formTest('no backend: no row, no dead button, manual km only', (
      tester,
    ) async {
      await openTemplateForm(tester, backend: false);
      expect(find.text(_toggle), findsNothing);
      expect(field('Entfernung einfach (km)'), findsOneWidget);
      await tester.enterText(field('Entfernung einfach (km)'), '212');
      await tester.pump();
      expect(text(tester, 'Entfernung einfach (km)'), '212');
      expect(app.route.calls, isEmpty);
    });

    formTest('server without routing key: one message, then no row', (
      tester,
    ) async {
      app.route.failWith = RouteFailure.providerUnconfigured;
      await openTemplateForm(tester);
      await open(tester);
      await tester.enterText(field('Start'), 'Karls');
      await tester.pumpAndSettle();
      const message =
          'Die Streckenberechnung gibt es auf diesem Server nicht. '
          'Trag die Kilometer einfach selbst ein.';
      expect(find.text(message), findsOneWidget);
      expect(find.text(_toggle), findsNothing);
      expect(field('Entfernung einfach (km)'), findsOneWidget);
      expect(app.route.calls, hasLength(1));
    });

    formTest('collapsed row first, nothing asked until the user types', (
      tester,
    ) async {
      await openTemplateForm(tester);
      expect(find.text(_toggle), findsOneWidget);
      expect(field('Start'), findsNothing);
      expect(app.route.calls, isEmpty);
    });

    formTest('pick start and destination: the km fill, rounded to 100 m', (
      tester,
    ) async {
      app.route.distances[(a: ka.label, b: st.label)] = 81234;
      await openTemplateForm(tester);
      await open(tester);
      await choose(tester, 'Start', 'Karls', ka);
      expect(text(tester, 'Entfernung einfach (km)'), isEmpty);
      await choose(tester, 'Ziel', 'Stutt', st);
      expect(text(tester, 'Entfernung einfach (km)'), '81,2');
      expect(find.text('81,2 km, Strecke über die Straße'), findsOneWidget);
      expect(find.text(_credit), findsOneWidget);
      // The field stays a normal field.
      await tester.enterText(field('Entfernung einfach (km)'), '85');
      await tester.pump();
      expect(text(tester, 'Entfernung einfach (km)'), '85');
    });

    formTest('a hand edit wins; "Neu berechnen" is explicit', (tester) async {
      await openTemplateForm(tester);
      await open(tester);
      await choose(tester, 'Start', 'Karls', ka);
      await choose(tester, 'Ziel', 'Stutt', st);
      await tester.enterText(field('Entfernung einfach (km)'), '85');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Neu berechnen'), findsOneWidget);

      await tester.enterText(field('Ziel'), 'Berl');
      await tester.pumpAndSettle();
      await tester.tap(find.text(be.label));
      await tester.pumpAndSettle();
      expect(text(tester, 'Entfernung einfach (km)'), '85');
      expect(find.text('Neu berechnen'), findsOneWidget);

      await tester.tap(find.text('Neu berechnen'));
      await tester.pumpAndSettle();
      expect(text(tester, 'Entfernung einfach (km)'), '650,4');
      expect(find.text('Neu berechnen'), findsNothing);
    });

    formTest('offline: the hint says so, manual entry still works', (
      tester,
    ) async {
      app.route.failWith = RouteFailure.offline;
      await openTemplateForm(tester);
      await open(tester);
      await tester.enterText(field('Start'), 'Karls');
      await tester.pumpAndSettle();
      expect(
        find.text('Keine Verbindung, trag die Kilometer einfach selbst ein.'),
        findsOneWidget,
      );
      await tester.enterText(field('Entfernung einfach (km)'), '40');
      await tester.pump();
      expect(text(tester, 'Entfernung einfach (km)'), '40');
    });

    formTest('rate limit names the minutes', (tester) async {
      app.route
        ..failWith = RouteFailure.rateLimited
        ..failRetryAfter = const Duration(minutes: 3);
      await openTemplateForm(tester);
      await open(tester);
      await tester.enterText(field('Start'), 'Karls');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Zu viele Streckenanfragen. Versuch es in 3 Min. nochmal oder '
          'trag die Kilometer selbst ein.',
        ),
        findsOneWidget,
      );
    });

    formTest('rate limit without a wait still says so', (tester) async {
      app.route.failWith = RouteFailure.rateLimited;
      await openTemplateForm(tester);
      await open(tester);
      await tester.enterText(field('Start'), 'Karls');
      await tester.pumpAndSettle();
      expect(find.textContaining('Zu viele Streckenanfragen'), findsOneWidget);
    });

    formTest('service down is not called offline', (tester) async {
      app.route.failWith = RouteFailure.provider;
      await openTemplateForm(tester);
      await open(tester);
      await tester.enterText(field('Start'), 'Karls');
      await tester.pumpAndSettle();
      expect(find.textContaining('Routendienst'), findsOneWidget);
      expect(find.textContaining('Keine Verbindung'), findsNothing);
    });

    formTest('no route found has its own text and a retry', (tester) async {
      await openTemplateForm(tester);
      await open(tester);
      await choose(tester, 'Start', 'Stutt', st);
      await choose(tester, 'Ziel', 'Berl', be);
      expect(find.textContaining('keine Straßenverbindung'), findsOneWidget);
      expect(text(tester, 'Entfernung einfach (km)'), isEmpty);
      expect(find.text('Neu berechnen'), findsOneWidget);
    });

    formTest('no matches is said, not left blank', (tester) async {
      await openTemplateForm(tester);
      await open(tester);
      await tester.enterText(field('Start'), 'Nirgendwo');
      await tester.pumpAndSettle();
      expect(find.textContaining('Keine Treffer'), findsOneWidget);
    });

    formTest('saved places: quick pick and remember with undo', (
      tester,
    ) async {
      await openTemplateForm(tester);
      await open(tester);
      await choose(tester, 'Start', 'Karls', ka);
      await choose(tester, 'Ziel', 'Stutt', st);
      await tester.tap(find.text('Als Zuhause merken').first);
      await tester.pumpAndSettle();
      expect(find.text('Als Zuhause gemerkt'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Zuhause'), findsOneWidget);

      // Undo takes it back.
      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'Zuhause'), findsNothing);

      // Saved earlier: the chip fills the first empty field without typing.
      await app.places.save(PlaceKind.work, be);
      await openTemplateForm(tester);
      await open(tester);
      await tester.tap(find.widgetWithText(ActionChip, 'Arbeit'));
      await tester.pumpAndSettle();
      expect(text(tester, 'Start'), be.label);
    });

    formTest('a failing save of a place is shown', (tester) async {
      await openTemplateForm(tester);
      await open(tester);
      await choose(tester, 'Start', 'Karls', ka);
      await choose(tester, 'Ziel', 'Stutt', st);
      app.places.failWith = const Storage('disk');
      await tester.tap(find.text('Als Arbeit merken').first);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Als Arbeit gemerkt'), findsNothing);
    });
  });

  group('trip form', () {
    formTest('fills the one-way distance field with the local separator', (
      tester,
    ) async {
      app.route.distances[(a: ka.label, b: st.label)] = 81234;
      await openTripForm(tester);
      await open(tester);
      await choose(tester, 'Start', 'Karls', ka);
      await choose(tester, 'Ziel', 'Stutt', st);
      expect(text(tester, 'Strecke (einfach)'), '81,2');
    });

    formTest('typing in the field stops the auto-fill', (tester) async {
      await openTripForm(tester);
      await open(tester);
      await choose(tester, 'Start', 'Karls', ka);
      await choose(tester, 'Ziel', 'Stutt', st);
      await tester.enterText(field('Strecke (einfach)'), '99');
      await tester.pumpAndSettle();
      await tester.enterText(field('Ziel'), 'Berl');
      await tester.pumpAndSettle();
      await tester.tap(find.text(be.label));
      await tester.pumpAndSettle();
      expect(text(tester, 'Strecke (einfach)'), '99');
      expect(find.text('Neu berechnen'), findsOneWidget);
    });

    formTest('no backend: no row', (tester) async {
      await pumpMitlio(tester, app, location: '/groups/${pendeln.id}');
      await tester.tap(find.byTooltip('Fahrt hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.text(_toggle), findsNothing);
      expect(field('Strecke (einfach)'), findsOneWidget);
    });
  });
}
