import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/handlers/fuel.dart';
import 'package:mitlio/debug/handlers/groups.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_providers.dart';
import 'package:mitlio/features/fuel/data/services/fake_fuel_price_service.dart';
import 'package:mitlio/features/fuel/data/services/location_service.dart';

/// Fuel price chips (P6c-T05) on the Linux desktop device with an in-memory
/// Drift database and the fake price backend: filled through the trip form
/// UI, and read through DebugDrive.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeFuelPriceService fuel;
  late FakeLocationService location;
  late String groupId;

  Future<void> start(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    fuel = FakeFuelPriceService(now: DateTime.now);
    location = FakeLocationService();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        fuelPriceServiceProvider.overrideWithValue(fuel),
        locationServiceProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
    final created = await groupsDriveHandlers(container)['groups.create']!({
      'name': 'Pendeln',
      'members': '["Anna","Ben"]',
    });
    groupId = created['id']! as String;
    container.read(routerProvider).go('/groups/$groupId');
    await tester.pumpAndSettle();
  }

  testWidgets('the trip form fills the price from the chips, no location', (
    tester,
  ) async {
    // A tall screen: the whole form is built, nothing waits behind a scroll.
    tester.view
      ..physicalSize = const Size(800, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await start(tester);
    await tester.tap(find.byTooltip('Fahrt hinzufügen'));
    await tester.pumpAndSettle();

    String price() => tester
        .widget<TextField>(find.widgetWithText(TextField, 'Preis pro Liter'))
        .controller!
        .text;
    // E5 is pre-selected and filled in without a tap: the national average.
    expect(price(), '1,799');
    expect(find.textContaining('Ø Deutschland'), findsOneWidget);
    expect(find.textContaining('Daten: MTS-K'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Diesel'));
    await tester.pumpAndSettle();
    expect(price(), '1,659');

    // Nothing asked for the position, nothing sent but the grade.
    expect(location.asked, 0);
    expect(fuel.calls.every((c) => c.area == null), isTrue);
  });

  testWidgets('DebugDrive reads the same value from the service', (
    tester,
  ) async {
    await start(tester);
    final r = await fuelDriveHandlers(container)['fuel.prices']!({
      'type': 'e10',
    });
    expect(r['priceMilli'], 1739);
    expect(r['scope'], 'national');
    expect(r['attribution'], contains('MTS-K'));
  });
}
