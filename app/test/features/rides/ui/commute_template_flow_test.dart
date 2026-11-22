import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';

import '../../../support/tap_counter.dart';
import 'rides_fixtures.dart';

final _de = AppLocalizationsDe();

/// The commute template flow on the real app, router and in-memory
/// repositories (PU-T12, German).
void main() {
  late RidesApp app;

  setUp(() => app = RidesApp());

  void rideTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) {
        app.tester = tester;
        return body(tester);
      });

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}/rides/templates/new',
    );
  }

  Finder text(String t) => find.text(t);
  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> next(WidgetTester tester, [TapCounter? taps]) async {
    if (taps != null) {
      await taps.tap(text(_de.setupNext));
    } else {
      await tester.tap(text(_de.setupNext));
    }
    await tester.pumpAndSettle();
  }

  rideTest('every step answered stays within the commute_template budget', (
    tester,
  ) async {
    await app.seedVehicle();
    await open(tester);
    final taps = TapCounter(tester);

    await taps.enterText(field(_de.templateNameLabel), 'Arbeit');
    await next(tester, taps);

    expect(text('Schritt 2 von 5'), findsOneWidget);
    await taps.enterText(field(_de.templateDistanceLabel), '20');
    await next(tester, taps);

    // The only car is chosen already.
    expect(text(_de.commuteVehicleTitle), findsOneWidget);
    await next(tester, taps);

    await taps.tap(find.widgetWithText(ChoiceChip, 'Ann'));
    await taps.tap(find.widgetWithText(FilterChip, 'Ben'));
    await next(tester, taps);

    expect(text(_de.commuteTollsTitle), findsOneWidget);
    await taps.enterText(field(_de.templateTollsLabel), '2,50');
    await tester.pump();
    await next(tester, taps);

    expect(text(_de.commuteFinishTitle('Arbeit')), findsOneWidget);
    expect(text(_de.commuteSummaryRoundTrip('20')), findsOneWidget);
    expect(text(_de.commuteSummaryVehicle('Golf')), findsOneWidget);
    expect(text(_de.commuteSummaryDriver('Ann')), findsOneWidget);
    expect(text(_de.commuteSummaryPassengers('Ben')), findsOneWidget);
    expect(find.textContaining('Maut'), findsOneWidget);
    await taps.tap(text(_de.commuteSave));
    await tester.pumpAndSettle();

    taps.expectWithinBudget('commute_template');
    final saved = (await tester.runAsync(
      () => app.templates.watchTemplates(app.group.id).first,
    ))!;
    expect(saved.single.name, 'Arbeit');
    expect(saved.single.distanceMeters, 20000);
    expect(saved.single.tollsCents, 250);
    // Back where the flow was started from.
    expect(text(_de.commuteFinishTitle('Arbeit')), findsNothing);
  });

  rideTest('the shortest path: name, distance, car, skip, skip, save', (
    tester,
  ) async {
    await app.seedVehicle();
    await open(tester);
    await tester.enterText(field(_de.templateNameLabel), 'Arbeit');
    await next(tester);
    await tester.enterText(field(_de.templateDistanceLabel), '12,5');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await next(tester);
    await next(tester);
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    expect(text(_de.commuteSummaryOneWay('12,5')), findsOneWidget);
    await tester.tap(text(_de.commuteSave));
    await tester.pumpAndSettle();
    final saved = (await tester.runAsync(
      () => app.templates.watchTemplates(app.group.id).first,
    ))!;
    expect(saved.single.roundTrip, isFalse);
    expect(saved.single.defaultDriverId, isNull);
  });

  rideTest('a blank name and a missing distance say what to do', (
    tester,
  ) async {
    await app.seedVehicle();
    await open(tester);
    await next(tester);
    expect(text(_de.templateErrorName), findsOneWidget);
    await tester.enterText(field(_de.templateNameLabel), 'Arbeit');
    await next(tester);
    await next(tester);
    expect(text(_de.templateErrorDistance), findsOneWidget);
    expect(text(_de.commuteRouteTitle), findsOneWidget);
  });

  rideTest('without a car there is no "Weiter", but a way to add one', (
    tester,
  ) async {
    await app.seedGroup();
    await open(tester);
    await tester.enterText(field(_de.templateNameLabel), 'Arbeit');
    await next(tester);
    await tester.enterText(field(_de.templateDistanceLabel), '20');
    await next(tester);
    expect(text(_de.templateNoVehicle), findsOneWidget);
    expect(text(_de.setupNext), findsNothing);
    await tester.tap(text(_de.templateNoVehicleAction));
    await tester.pumpAndSettle();
    expect(text('Neues Fahrzeug'), findsOneWidget);
  });

  rideTest('the driver is no passenger; back keeps the answers', (
    tester,
  ) async {
    await app.seedVehicle();
    await open(tester);
    await tester.enterText(field(_de.templateNameLabel), 'Arbeit');
    await next(tester);
    await tester.enterText(field(_de.templateDistanceLabel), '20');
    await next(tester);
    await next(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Ann'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ann'));
    await tester.pump();
    expect(find.widgetWithText(FilterChip, 'Ann'), findsNothing);
    await tester.tap(find.byTooltip(_de.setupBack));
    await tester.pumpAndSettle();
    expect(text(_de.commuteVehicleTitle), findsOneWidget);
  });

  rideTest('a failing store says so and keeps the answers', (tester) async {
    await app.seedVehicle();
    await open(tester);
    await tester.enterText(field(_de.templateNameLabel), 'Arbeit');
    await next(tester);
    await tester.enterText(field(_de.templateDistanceLabel), '20');
    await next(tester);
    await next(tester);
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    app.templates.failWith = const Storage('down');
    await tester.tap(text(_de.commuteSave));
    await tester.pumpAndSettle();
    expect(find.textContaining('Prüf den freien Speicher'), findsOneWidget);
    expect(text(_de.commuteFinishTitle('Arbeit')), findsOneWidget);
  });
}
