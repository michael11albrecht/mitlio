import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'car_flow_support.dart';

void main() {
  late CarFlowFakes fakes;
  late ProviderContainer c;

  setUp(() {
    fakes = CarFlowFakes();
    c = fakes.container();
    addTearDown(c.dispose);
  });

  CarSetupSummary? summary() => c.read(carSetupSummaryProvider);

  RepositoryError errorOf(RepoResult<void> r) =>
      (r as Err<void, RepositoryError>).error;

  Future<List<Vehicle>> cars() => fakes.cars.watchVehicles().first;

  group('steps', () {
    test('has the five car steps, none skippable', () {
      expect(
        [for (final s in carSetupFlow.steps) s.id],
        [
          'hasCar',
          'name',
          'fuel',
          'consumption',
          'extraCost',
        ],
      );
      expect(carSetupFlow.steps.every((s) => !s.skippable), isTrue);
    });

    test('no step can be skipped', () async {
      await c.start(carSetupFlow);
      expect(errorOf(await c.flow(carSetupFlow).skip()), isA<InvalidData>());
      await c.answer(carSetupFlow, true);
      expect(errorOf(await c.flow(carSetupFlow).skip()), isA<InvalidData>());
      expect(c.flowState(carSetupFlow).step?.id, 'name');
    });

    test('name: not blank; the type defaults to compact', () async {
      await c.start(carSetupFlow);
      await c.answer(carSetupFlow, true);
      for (final bad in [
        null,
        'Golf',
        {'name': '  ', 'type': 'suv'},
        {'type': 'suv'},
      ]) {
        expect(
          errorOf(await c.flow(carSetupFlow).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
      await c.answer(carSetupFlow, {'name': ' Golf ', 'type': 'nope'});
      await c.answer(carSetupFlow, 'petrol');
      await c.answer(carSetupFlow, 6500);
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      expect(summary()?.name, 'Golf');
      expect(summary()?.type, CarType.compact);
    });

    test('fuel: one of the four', () async {
      await c.start(carSetupFlow);
      await c.answer(carSetupFlow, true);
      await c.answer(carSetupFlow, carNameAnswer('Zoe', CarType.small));
      for (final bad in ['hydrogen', 3, true]) {
        expect(
          errorOf(await c.flow(carSetupFlow).next(answer: bad)),
          isA<InvalidData>(),
        );
      }
      for (final fuel in FuelType.values) {
        await c.answer(carSetupFlow, fuel.name);
        await c.flow(carSetupFlow).back();
      }
      expect(c.flowState(carSetupFlow).step?.id, 'fuel');
    });

    test('consumption: above 0, as a whole number of thousandths', () async {
      await c.start(carSetupFlow);
      await c.answer(carSetupFlow, true);
      await c.answer(carSetupFlow, carNameAnswer('Zoe', CarType.small));
      await c.answer(carSetupFlow, FuelType.electric.name);
      for (final bad in [0, -1, 6.5, '6,5', 100001]) {
        expect(
          errorOf(await c.flow(carSetupFlow).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
      await c.answer(carSetupFlow, 15000);
      expect(c.flowState(carSetupFlow).step?.id, 'extraCost');
    });

    test('extra cost: flat or exact, finishing the flow', () async {
      await answerCarUntilExtra(c);
      expect(
        errorOf(await c.flow(carSetupFlow).next(answer: 'maybe')),
        isA<InvalidData>(),
      );
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      expect(c.flowState(carSetupFlow).finished, isTrue);
    });

    test('typical consumption: by type and fuel, all above 0', () {
      for (final type in CarType.values) {
        for (final fuel in FuelType.values) {
          expect(typicalConsumptionMilli(type, fuel), greaterThan(0));
        }
      }
      expect(typicalConsumptionMilli(CarType.compact, FuelType.petrol), 6500);
      expect(
        typicalConsumptionMilli(CarType.suv, FuelType.petrol),
        greaterThan(typicalConsumptionMilli(CarType.small, FuelType.petrol)),
      );
    });
  });

  group('result equals rideCost (domain fixtures rides)', () {
    test('the golf ride r1: 20 km round trip, 6.5 l, 1.799 -> 468 ct', () {
      final golf = Vehicle(
        id: 'golf',
        name: 'Golf',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: 6500,
      );
      final cost = referenceRideCost(
        golf,
        priceMilli: 1799,
        meters: 20000,
        roundTrip: true,
      );
      expect(cost.totalCents, 468);
    });

    test('ct/km is the 100 km ride cost of rideCost, to the tenth', () async {
      await answerCarUntilExtra(c);
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      final s = summary()!;
      final golf = Vehicle(
        id: 'golf',
        name: 'Golf',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: 6500,
        wearMilliPerKm: flatWearMilliPerKm,
      );
      // 100 km at the default petrol price 1.750: 6.5 l -> 1137.5 -> 1138 ct
      // fuel (rounded half up), plus 5 ct/km wear = 500 ct.
      final ride = referenceRideCost(golf);
      expect(ride.fuelCents, 1138);
      expect(ride.wearCents, 500);
      expect(ride.totalCents, 1638);
      expect(s.totalTenths, 164);
      expect(s.fuelTenths, 114);
      expect(formatTenths(s.totalTenths, ','), '16,4');
      expect(s.segments, [
        (part: CostPart.fuel, tenths: 114),
        (part: CostPart.flat, tenths: 50),
      ]);
    });

    test(
      'exact costs replace the flat rate: fuel plus the breakdown',
      () async {
        await answerCarUntilExtra(c);
        await answerCostFixture(c);
        await c.answer(carSetupFlow, ExtraCostChoice.exact);
        final s = summary()!;
        expect(s.exact, isTrue);
        expect(s.wearMilli, 240);
        // 100 km: 1138 ct fuel + 2400 ct wear.
        expect(s.totalTenths, 354);
        expect(s.segments, [
          (part: CostPart.fuel, tenths: 114),
          (part: CostPart.maintenance, tenths: 32),
          (part: CostPart.tyres, tenths: 8),
          (part: CostPart.depreciation, tenths: 200),
        ]);
        expect(s.segments.fold<int>(0, (a, e) => a + e.tenths), s.totalTenths);
      },
    );

    test('exact without a finished calculator falls back to flat', () async {
      await answerCarUntilExtra(c);
      await c.answer(carSetupFlow, ExtraCostChoice.exact);
      expect(summary()?.exact, isFalse);
      expect(summary()?.wearMilli, flatWearMilliPerKm);
    });

    test('an electric car is priced per kWh', () async {
      await c.start(carSetupFlow);
      await c.answer(carSetupFlow, true);
      await c.answer(carSetupFlow, carNameAnswer('Zoe', CarType.small));
      await c.answer(carSetupFlow, FuelType.electric.name);
      await c.answer(carSetupFlow, 15000);
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      // 15 kWh x 0.350 = 5.25 EUR per 100 km -> 525 ct fuel.
      expect(summary()?.fuelTenths, 53);
    });
  });

  group('hints (PU-T15)', () {
    test('flat rate: no operating-cost hint, no typo hint', () async {
      await answerCarUntilExtra(c);
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      expect(summary()?.check.hasHint, isFalse);
    });

    test('full basis with fixed costs: the operating-cost hint', () async {
      await answerCarUntilExtra(c);
      await answerCostFixture(c, basis: 'full');
      await c.answer(carSetupFlow, ExtraCostChoice.exact);
      expect(summary()?.check.exceedsOperatingCost, isTrue);
    });

    test('running basis: no operating-cost hint', () async {
      await answerCarUntilExtra(c);
      await answerCostFixture(c);
      await c.answer(carSetupFlow, ExtraCostChoice.exact);
      expect(summary()?.check.exceedsOperatingCost, isFalse);
    });

    test('above 30 l per 100 km is flagged "Bitte prüfen"', () async {
      await c.start(carSetupFlow);
      await c.answer(carSetupFlow, true);
      await c.answer(carSetupFlow, carNameAnswer('Bus', CarType.van));
      await c.answer(carSetupFlow, FuelType.diesel.name);
      await c.answer(carSetupFlow, 31000);
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      expect(summary()?.check.plausibility, [
        PlausibilityIssue.consumptionTooHigh,
      ]);
    });

    test('a hint never blocks saving', () async {
      await answerCarUntilExtra(c);
      await answerCostFixture(c, basis: 'full');
      await c.answer(carSetupFlow, ExtraCostChoice.exact);
      final saved = await c.read(carSetupViewModelProvider.notifier).save();
      expect(saved, isA<Ok<Vehicle, RepositoryError>>());
    });
  });

  group('save', () {
    test('is incomplete before the consumption: Conflict', () async {
      await c.start(carSetupFlow);
      await c.answer(carSetupFlow, true);
      final r = await c.read(carSetupViewModelProvider.notifier).save();
      expect(errorOf(r), isA<Conflict>());
      expect(await cars(), isEmpty);
    });

    test('flat: stores the car with the flat wear, no costs', () async {
      await answerCarUntilExtra(c);
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      final r = await c.read(carSetupViewModelProvider.notifier).save();
      final car = (r as Ok<Vehicle, RepositoryError>).value;
      expect(car.name, 'Golf');
      expect(car.fuelType, FuelType.petrol);
      expect(car.consumptionMilliPer100km, 6500);
      expect(car.wearMilliPerKm, flatWearMilliPerKm);
      expect(await cars(), [isA<Vehicle>().having((v) => v.id, 'id', car.id)]);
      expect(
        (await fakes.cars.getCosts(
          car.id,
        ) as Ok<UserVehicleCostDetails?, RepositoryError>).value,
        isNull,
      );
    });

    test('exact: stores the wear of the chosen basis and the costs', () async {
      await answerCarUntilExtra(c);
      await answerCostFixture(c, basis: 'full');
      await c.answer(carSetupFlow, ExtraCostChoice.exact);
      final r = await c.read(carSetupViewModelProvider.notifier).save();
      final car = (r as Ok<Vehicle, RepositoryError>).value;
      expect(car.wearMilliPerKm, 293);
      final costs = (await fakes.cars.getCosts(
        car.id,
      ) as Ok<UserVehicleCostDetails?, RepositoryError>).value;
      expect(
        costs,
        const UserVehicleCostDetails(
          annualKm: 15000,
          shareBasis: UserVehicleShareBasis.full,
          annualCents: {
            UserVehicleCostCategory.insurance: 60000,
            UserVehicleCostCategory.tax: 20000,
            UserVehicleCostCategory.maintenance: 48000,
            UserVehicleCostCategory.tyres: 12000,
            UserVehicleCostCategory.depreciation: 300000,
          },
        ),
      );
    });

    test('the saved car costs what the screen said, in rideCost', () async {
      await answerCarUntilExtra(c);
      await answerCostFixture(c);
      await c.answer(carSetupFlow, ExtraCostChoice.exact);
      final shown = summary()!.totalTenths;
      final car =
          ((await c.read(carSetupViewModelProvider.notifier).save())
                  as Ok<Vehicle, RepositoryError>)
              .value;
      expect((referenceRideCost(car).totalCents + 5) ~/ 10, shown);
    });

    test('clears both flows: "Noch ein Auto?" starts fresh', () async {
      await answerCarUntilExtra(c);
      await answerCostFixture(c);
      await c.answer(carSetupFlow, ExtraCostChoice.exact);
      await c.read(carSetupViewModelProvider.notifier).save();
      await c.start(carSetupFlow);
      await c.start(carCostFlow);
      expect(c.flowState(carSetupFlow).step?.id, 'hasCar');
      expect(c.flowState(carSetupFlow).answers, isEmpty);
      expect(c.flowState(carCostFlow).step?.id, 'annualKm');
      expect(summary(), isNull);
      expect(c.read(carCostResultProvider), isNull);
      // And a killed app does not bring the old car back either.
      final again = fakes.container();
      addTearDown(again.dispose);
      await again.start(carSetupFlow);
      expect(again.flowState(carSetupFlow).answers, isEmpty);
    });

    test('a failing repository: the error, the flow untouched', () async {
      await answerCarUntilExtra(c);
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      fakes.cars.failAddWith = const Storage('disk full');
      final r = await c.read(carSetupViewModelProvider.notifier).save();
      expect(errorOf(r), isA<Storage>());
      expect(c.flowState(carSetupFlow).finished, isTrue);
      expect(summary()?.name, 'Golf');
      expect(await cars(), isEmpty);
      fakes.cars.failAddWith = null;
      expect(
        await c.read(carSetupViewModelProvider.notifier).save(),
        isA<Ok<Vehicle, RepositoryError>>(),
      );
    });

    test('costs that cannot be stored: no car, the error', () async {
      await answerCarUntilExtra(c);
      await answerCostFixture(c);
      await c.answer(carSetupFlow, ExtraCostChoice.exact);
      fakes.cars.failCostsWith = const Storage('disk full');
      final r = await c.read(carSetupViewModelProvider.notifier).save();
      expect(errorOf(r), isA<Storage>());
      expect(await cars(), isEmpty);
      expect(c.flowState(carCostFlow).finished, isTrue);
    });

    test('saving twice at once adds one car', () async {
      await answerCarUntilExtra(c);
      await c.answer(carSetupFlow, ExtraCostChoice.flat);
      final vm = c.read(carSetupViewModelProvider.notifier);
      final first = vm.save();
      final second = await vm.save();
      expect(errorOf(second), isA<Conflict>());
      await first;
      expect(await cars(), hasLength(1));
      expect(c.read(carSetupViewModelProvider), isFalse);
    });
  });

  test('both flows are registered for DebugDrive', () {
    expect(carFlowConfigs.keys, ['car_setup', 'car_cost']);
    expect(carFlowConfigs['car_cost'], carCostFlow);
  });

  test('the repository provider is the one the fakes override', () {
    expect(c.read(userVehiclesRepositoryProvider), same(fakes.cars));
  });
}
