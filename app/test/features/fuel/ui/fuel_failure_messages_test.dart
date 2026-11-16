import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/fuel/ui/fuel_price_view_model.dart';

import '../../../helpers/themed_app.dart';
import 'fuel_fixtures.dart';

/// No silent errors: every cause shows its own message, never a wrong one.
void main() {
  Future<void> pump(WidgetTester tester, FuelPriceState state) async {
    await tester.pumpWidget(themedApp(fuelChipsHost(state)));
    await tester.pump();
  }

  FuelPriceState nothing(FuelFailure f, {Duration? wait}) => FuelPriceState(
    available: true,
    grade: FuelGrade.e5,
    failure: f,
    retryAfter: wait,
  );

  testWidgets('rate limited without a wait: says so and to retry', (
    tester,
  ) async {
    await pump(tester, nothing(FuelFailure.rateLimited));
    expect(
      find.textContaining(
        'Zu viele Preisabfragen – versuch es in ein paar Minuten nochmal.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Gerade kein aktueller Preis'), findsNothing);
  });

  testWidgets('rate limited with Retry-After: names the minutes', (
    tester,
  ) async {
    await pump(
      tester,
      nothing(FuelFailure.rateLimited, wait: const Duration(minutes: 7)),
    );
    expect(find.textContaining('in 7 Min. nochmal'), findsOneWidget);
  });

  testWidgets('provider not set up: says areas are unavailable here', (
    tester,
  ) async {
    await pump(
      tester,
      const FuelPriceState(
        available: true,
        grade: FuelGrade.e5,
        canPlz: false,
        failure: FuelFailure.providerUnconfigured,
      ),
    );
    expect(
      find.textContaining('gibt es auf diesem Server nicht'),
      findsOneWidget,
    );
    expect(find.textContaining('Postleitzahl'), findsOneWidget);
  });

  testWidgets('offline: connection hint', (tester) async {
    await pump(tester, nothing(FuelFailure.offline));
    expect(find.textContaining('Keine Verbindung'), findsOneWidget);
  });

  testWidgets('price service down: its own hint, not "offline"', (
    tester,
  ) async {
    await pump(tester, nothing(FuelFailure.provider));
    expect(
      find.textContaining('Preisdienst gerade nicht erreichbar'),
      findsOneWidget,
    );
    expect(find.textContaining('Keine Verbindung'), findsNothing);
  });

  testWidgets('stale because of a rate limit does not say "offline"', (
    tester,
  ) async {
    await pump(tester, fuelStaleRateLimited);
    expect(find.textContaining('zu viele Anfragen'), findsOneWidget);
    expect(find.textContaining('in 5 Min.'), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);
  });

  testWidgets('stale because the service is down says so', (tester) async {
    await pump(tester, fuelStaleServer);
    expect(find.textContaining('Preisdienst nicht erreichbar'), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);
  });

  testWidgets('stale and truly offline still says offline', (tester) async {
    await pump(tester, fuelStale);
    expect(find.textContaining('offline, zuletzt bekannt'), findsOneWidget);
  });
}
