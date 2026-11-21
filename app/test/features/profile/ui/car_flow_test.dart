import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import 'car_flow_support.dart';

final _de = AppLocalizationsDe();
final _en = AppLocalizationsEn();

void main() {
  late CarFlowFakes fakes;
  late FakeApp app;
  late WidgetTester current;

  setUp(() {
    fakes = CarFlowFakes();
    app = FakeApp()
      ..userVehicles = fakes.cars
      ..setupState = fakes.setup;
  });

  Future<ProviderContainer> open(
    WidgetTester tester,
    String location, {
    Locale locale = const Locale('de'),
  }) {
    current = tester;
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return pumpMitlio(
      tester,
      app,
      location: location,
      locale: locale,
    );
  }

  /// The stored cars; the stream needs real async, not the test clock.
  Future<List<Vehicle>> cars() async =>
      (await current.runAsync(() => fakes.cars.watchVehicles().first))!;

  testWidgets('Settings has a "Meine Autos" row; the list starts empty', (
    tester,
  ) async {
    await open(tester, '/settings');
    await tester.tap(find.text(_de.carsEntry));
    await tester.pumpAndSettle();
    expect(find.text(_de.carsEmptyTitle), findsOneWidget);
    await tester.tap(find.text(_de.carsAdd));
    await tester.pumpAndSettle();
    expect(find.text(_de.carHasCarTitle), findsOneWidget);
    expect(find.text(_de.setupStepProgress(1, 5)), findsOneWidget);
  });

  testWidgets('"Nein": nothing to set up, back to the list', (tester) async {
    await open(tester, '/settings/cars/new');
    await tester.tap(find.text(_de.setupNo));
    await tester.pumpAndSettle();
    expect(find.text(_de.carsTitle), findsOneWidget);
    expect(await cars(), isEmpty);
  });

  testWidgets('whole car flow with the flat rate stays in car_setup', (
    tester,
  ) async {
    await open(tester, '/settings/cars/new');
    final taps = TapCounter(tester);

    await taps.tap(find.text(_de.setupYes));
    await tester.pumpAndSettle();
    expect(find.text(_de.carNameTitle), findsOneWidget);
    expect(find.text(_de.carNameLabel), findsOneWidget);
    await taps.enterText(find.byType(TextField), 'Golf');
    await taps.tap(find.text(_de.setupNext));
    await tester.pumpAndSettle();

    expect(find.text(_de.carFuelTitle), findsOneWidget);
    await taps.tap(find.text(_de.carFuelPetrol));
    await tester.pumpAndSettle();

    expect(find.text(_de.carConsumptionTitle), findsOneWidget);
    await taps.enterText(find.byType(TextField), '6,5');
    await taps.tap(find.text(_de.setupNext));
    await tester.pumpAndSettle();

    expect(find.text(_de.carExtraTitle), findsOneWidget);
    expect(find.text(_de.carExtraFlat('5,0')), findsOneWidget);
    await taps.tap(find.text(_de.carExtraFlat('5,0')));
    await tester.pumpAndSettle();

    // Result first: what a kilometre costs, with the chart legend.
    expect(find.text(_de.carFinishTitle('16,4')), findsOneWidget);
    expect(find.text(_de.carPartFuel), findsOneWidget);
    expect(find.text(_de.carPartFlat), findsOneWidget);
    expect(find.text(_de.carHintOperatingCost), findsNothing);
    await taps.tap(find.text(_de.carSave));
    await tester.pumpAndSettle();

    taps.expectWithinBudget('car_setup');
    expect(taps.taps, 6);
    expect(await cars(), [
      isA<Vehicle>()
          .having((v) => v.name, 'name', 'Golf')
          .having((v) => v.consumptionMilliPer100km, 'consumption', 6500),
    ]);
    // Back on the list, showing the car.
    expect(find.text('Golf'), findsOneWidget);
    expect(find.text(_de.carRowSubtitle('Benzin', '6,5 l/100 km')), findsOne);
  });

  testWidgets('consumption: "Weiß ich nicht" takes the typical value', (
    tester,
  ) async {
    await open(tester, '/settings/cars/new');
    await tester.tap(find.text(_de.setupYes));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tesla');
    await tester.tap(find.text(_de.setupNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_de.carFuelElectric));
    await tester.pumpAndSettle();
    expect(
      find.text(_de.carConsumptionTypical('16', _de.carUnitKwh)),
      findsOneWidget,
    );
    await tester.tap(find.text(_de.carConsumptionDontKnow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_de.setupNext));
    await tester.pumpAndSettle();
    expect(find.text(_de.carExtraTitle), findsOneWidget);
  });

  testWidgets('empty name and empty consumption say what to do', (
    tester,
  ) async {
    await open(tester, '/settings/cars/new');
    await tester.tap(find.text(_de.setupYes));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_de.setupNext));
    await tester.pumpAndSettle();
    expect(find.text(_de.carNameRequired), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Golf');
    await tester.tap(find.text(_de.setupNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_de.carFuelDiesel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_de.setupNext));
    await tester.pumpAndSettle();
    expect(find.text(_de.carConsumptionInvalid), findsOneWidget);
    expect(find.text(_de.carConsumptionTitle), findsOneWidget);
  });

  testWidgets('a repository failure on save shows a plain message', (
    tester,
  ) async {
    final c = await open(tester, '/settings/cars/new');
    await c.start(carSetupFlow);
    await answerCarUntilExtraOn(c);
    await tester.pumpAndSettle();
    fakes.cars.failAddWith = const Storage('disk full');
    await tester.tap(find.text(_de.carSave));
    await tester.pumpAndSettle();
    expect(find.text(_de.errorStorage), findsOneWidget);
    expect(find.text(_de.carSave), findsOneWidget);
  });

  group('cost calculator', () {
    testWidgets('exact path: every screen, skips, basis, result, back', (
      tester,
    ) async {
      final c = await open(tester, '/settings/cars/new');
      await answerCarUntilExtraOn(c, finish: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_de.carExtraExact));
      await tester.pumpAndSettle();

      // Annual km: presets and the field.
      expect(find.text(_de.carCostKmTitle), findsOneWidget);
      expect(find.text(_de.setupStepProgress(1, 13)), findsOneWidget);
      await tester.tap(find.text(_de.carCostKmPreset(10)));
      await tester.pumpAndSettle();
      expect(find.text('10000'), findsOneWidget);
      await tester.tap(find.text(_de.setupNext));
      await tester.pumpAndSettle();

      // Insurance: 100 EUR per month, live result.
      expect(find.text(_de.carCostInsuranceTitle), findsOneWidget);
      await tester.enterText(find.byType(TextField), '100');
      await tester.pump();
      expect(find.text(_de.carCostSoFar('0,0')), findsOneWidget);
      await tester.tap(find.text(_de.setupNext));
      await tester.pumpAndSettle();

      // Tax: a typo is refused on screen, then skipped.
      expect(find.text(_de.carCostTaxTitle), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.text(_de.carCostAmountInvalid), findsOneWidget);
      await tester.tap(find.text(_de.setupNext));
      await tester.pumpAndSettle();
      expect(find.text(_de.carCostTaxTitle), findsOneWidget);
      await tester.tap(find.text(_de.setupSkip));
      await tester.pumpAndSettle();

      // Maintenance by the year, then skip the rest up to the basis.
      expect(find.text(_de.carCostMaintenanceTitle), findsOneWidget);
      await tester.enterText(find.byType(TextField), '600');
      await tester.tap(find.text(_de.carCostYear));
      await tester.pump();
      expect(find.text(_de.carCostSoFar('6,0')), findsOneWidget);
      await tester.tap(find.text(_de.setupNext));
      await tester.pumpAndSettle();
      for (final title in [
        _de.carCostTyresTitle,
        _de.carCostRepairsTitle,
        _de.carCostLoanTitle,
        _de.carCostPurchaseTitle,
        _de.carCostResaleTitle,
        _de.carCostYearsTitle,
        _de.carCostParkingTitle,
        _de.carCostOtherTitle,
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
        await tester.tap(find.text(_de.setupSkip));
        await tester.pumpAndSettle();
      }

      // Basis: both with their ct/km, the PBefG note always there.
      expect(find.text(_de.carCostBasisTitle), findsOneWidget);
      expect(find.text(_de.carCostBasisRunning('6,0')), findsOneWidget);
      expect(find.text(_de.carCostBasisFull('18,0')), findsOneWidget);
      expect(find.text(_de.carHintOperatingCost), findsOneWidget);
      await tester.tap(find.text(_de.carCostBasisFull('18,0')));
      await tester.pumpAndSettle();

      // Result: ct/km, chart legend per category, the hint for full costs.
      expect(find.text(_de.carCostResultTitle('18,0')), findsOneWidget);
      expect(find.text(_de.carPartInsurance), findsOneWidget);
      expect(find.text(_de.carPartMaintenance), findsOneWidget);
      expect(find.text(_de.carPartTyres), findsNothing);
      expect(find.text(_de.carHintOperatingCost), findsOneWidget);
      await tester.tap(find.text(_de.carCostResultAccept));
      await tester.pumpAndSettle();

      // Back in the car flow, which moved on to its result.
      expect(find.text(_de.carFinishTitle('29,4')), findsOneWidget);
      expect(
        find.text(_de.carSummaryExtraExact('18,0')),
        findsOneWidget,
      );
      await tester.tap(find.text(_de.carSave));
      await tester.pumpAndSettle();
      final car = (await cars()).single;
      expect(car.wearMilliPerKm, 180);
      final stored = (await fakes.cars.getCosts(
        car.id,
      ) as Ok<UserVehicleCostDetails?, RepositoryError>).value;
      expect(stored?.annualKm, 10000);
      expect(stored?.shareBasis, UserVehicleShareBasis.full);
      expect(stored?.annualCents, {
        UserVehicleCostCategory.insurance: 120000,
        UserVehicleCostCategory.maintenance: 60000,
      });
    });

    testWidgets('leaving the calculator keeps the car flow on its step', (
      tester,
    ) async {
      final c = await open(tester, '/settings/cars/new');
      await answerCarUntilExtraOn(c, finish: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_de.carExtraExact));
      await tester.pumpAndSettle();
      // The first calculator step has no back; the system back leaves it.
      c.read(routerProvider).pop();
      await tester.pumpAndSettle();
      expect(find.text(_de.carExtraTitle), findsOneWidget);
      expect(c.flowState(carSetupFlow).finished, isFalse);
    });

    testWidgets('the calculator resumes where it was left', (tester) async {
      final c = await open(tester, '/settings/cars/new/costs');
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 15000);
      await c.answer(carCostFlow, costEntryAnswer(5000, CostPeriod.year));
      c.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/settings/cars/new/costs');
      await tester.pumpAndSettle();
      expect(find.text(_de.carCostTaxTitle), findsOneWidget);
      expect(find.text(_de.setupStepProgress(3, 13)), findsOneWidget);
    });
  });

  testWidgets('English: titles and units follow the device language', (
    tester,
  ) async {
    await open(tester, '/settings/cars/new', locale: const Locale('en'));
    expect(find.text(_en.carHasCarTitle), findsOneWidget);
    await tester.tap(find.text(_en.setupYes));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Golf');
    await tester.tap(find.text(_en.setupNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.carFuelPetrol));
    await tester.pumpAndSettle();
    expect(
      find.text(_en.carConsumptionTypical('6.5', _en.carUnitLitres)),
      findsOneWidget,
    );
  });
}
