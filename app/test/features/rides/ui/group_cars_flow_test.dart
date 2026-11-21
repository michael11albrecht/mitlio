import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

/// "Mein Auto" in the vehicle list of a group (PU-T10, PU-T11) on the real
/// app, router and in-memory repositories (German, the default locale).
void main() {
  late RidesApp app;

  setUp(() {
    app = RidesApp();
  });

  /// The cards and the picker read streams, which need the real event loop.
  Future<void> loaded(WidgetTester tester) async {
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  const carCard = 'Dein Auto einmal einrichten';
  const dismiss = 'Nicht mehr anzeigen';

  Future<Vehicle> addPersonalGolf() async => ok(
    await app.base.userVehicles.add(
      name: 'Golf',
      fuelType: FuelType.petrol,
      consumptionMilliPer100km: 6500,
    ),
  );

  testWidgets('without a personal car it offers to set one up once', (
    tester,
  ) async {
    app.tester = tester;
    await app.seedGroup();
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}/rides/settings',
    );
    await loaded(tester);
    expect(find.text(carCard), findsOneWidget);
    await tester.tap(find.byTooltip(dismiss));
    await tester.pumpAndSettle();
    expect(find.text(carCard), findsNothing);

    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}/rides/settings',
    );
    await loaded(tester);
    expect(find.text(carCard), findsNothing);
  });

  testWidgets('"Mein Auto" makes a linked copy, which can be unlinked', (
    tester,
  ) async {
    app.tester = tester;
    await app.seedGroup();
    await tester.runAsync(addPersonalGolf);
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}/rides/settings',
    );
    await loaded(tester);
    expect(find.text(carCard), findsNothing);
    expect(find.text('Aus Meine Autos'), findsOneWidget);
    await tester.tap(find.text('Nutzen'));
    await loaded(tester);

    expect(find.text('Aus Meine Autos'), findsNothing);
    final copy = (await tester.runAsync(
      () => app.vehicles.watchVehicles(app.group.id).first,
    ))!.single;
    expect(copy.name, 'Golf');

    await tester.tap(find.text('Golf'));
    await loaded(tester);
    expect(find.textContaining('kommt aus Meine Autos'), findsOneWidget);
    await tester.tap(find.text('Trennen'));
    await loaded(tester);
    expect(find.textContaining('kommt aus Meine Autos'), findsNothing);
    expect(find.textContaining('Nicht mehr mit Meine Autos'), findsOneWidget);
    expect(
      await tester.runAsync(() => app.vehicles.sourceOf(copy.id)),
      isA<Ok<String?, RepositoryError>>().having((r) => r.value, 'v', isNull),
    );
  });

  testWidgets('a failing "Mein Auto" says so and adds nothing', (tester) async {
    app.tester = tester;
    await app.seedGroup();
    await tester.runAsync(addPersonalGolf);
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}/rides/settings',
    );
    await loaded(tester);
    app.vehicles.failWith = const Storage('disk full');
    await tester.tap(find.text('Nutzen'));
    await loaded(tester);
    expect(find.text('Aus Meine Autos'), findsOneWidget);
    expect(find.textContaining('Das hat nicht geklappt'), findsOneWidget);
  });
}
