import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/profile/data/repositories/fake_user_vehicles_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Personal vehicles fake whose writes can be made to fail.
class FlakyUserVehicles extends FakeUserVehiclesRepository {
  FlakyUserVehicles({required super.ids});

  /// Fails `add` while set.
  RepositoryError? failAddWith;

  /// Fails `saveCosts` while set.
  RepositoryError? failCostsWith;

  /// Makes `watchVehicles` emit this error while set.
  Object? watchError;

  @override
  Stream<List<Vehicle>> watchVehicles() =>
      watchError != null ? Stream.error(watchError!) : super.watchVehicles();

  /// Fails `softDelete` while set.
  RepositoryError? failDeleteWith;

  @override
  Future<RepoResult<Vehicle>> add({
    required String name,
    required FuelType fuelType,
    required int consumptionMilliPer100km,
    int wearMilliPerKm = 0,
    int? kmRateMilliPerKm,
  }) async => failAddWith != null
      ? Err(failAddWith!)
      : super.add(
          name: name,
          fuelType: fuelType,
          consumptionMilliPer100km: consumptionMilliPer100km,
          wearMilliPerKm: wearMilliPerKm,
          kmRateMilliPerKm: kmRateMilliPerKm,
        );

  @override
  Future<RepoResult<UserVehicleCostDetails>> saveCosts(
    String vehicleId,
    UserVehicleCostDetails costs,
  ) async => failCostsWith != null
      ? Err(failCostsWith!)
      : super.saveCosts(vehicleId, costs);

  @override
  Future<RepoResult<Undo>> softDelete(String id) async =>
      failDeleteWith != null ? Err(failDeleteWith!) : super.softDelete(id);
}

/// The in-memory repositories the car flow runs on.
class CarFlowFakes {
  CarFlowFakes()
    : setup = FakeSetupStateRepository(),
      cars = FlakyUserVehicles(ids: SequentialIdGenerator());

  final FakeSetupStateRepository setup;
  final FlakyUserVehicles cars;

  List<Override> get overrides => [
    setupStateRepositoryProvider.overrideWithValue(setup),
    userVehiclesRepositoryProvider.overrideWithValue(cars),
  ];

  /// A container like a fresh app start (a "kill" is a new one).
  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides);
    return c;
  }
}

/// Reads and drives one flow of a container the way the screens do.
extension FlowDriver on ProviderContainer {
  SetupFlowViewModel flow(SetupFlowConfig config) =>
      read(setupFlowViewModelProvider(config).notifier);

  SetupFlowState flowState(SetupFlowConfig config) =>
      read(setupFlowViewModelProvider(config));

  /// Waits for the saved progress to be read.
  Future<void> start(SetupFlowConfig config) => flow(config).restoring;

  /// Answers the current step of [config] and expects it to be accepted.
  Future<void> answer(SetupFlowConfig config, Object? value) async {
    final r = await flow(config).next(answer: value);
    if (r is Err) throw StateError('step refused: $r');
  }

  Future<void> skip(SetupFlowConfig config) async {
    final r = await flow(config).skip();
    if (r is Err) throw StateError('skip refused: $r');
  }
}

/// Answers the cost calculator like the domain fixture "running basis" /
/// "full basis" (docs/domain-rules.md, `vehicle_cost`): 15 000 km,
/// maintenance 40 EUR a month, tyres 120 EUR a year, insurance 600 EUR a
/// year, tax 200 EUR a year, depreciation 30 000 -> 15 000 EUR over 5 years.
/// Running basis is 240, full basis 293 milli per km.
Future<void> answerCostFixture(ProviderContainer c, {String? basis}) async {
  await c.start(carCostFlow);
  await c.answer(carCostFlow, 15000);
  await c.answer(carCostFlow, costEntryAnswer(60000, CostPeriod.year));
  await c.answer(carCostFlow, costEntryAnswer(20000, CostPeriod.year));
  await c.answer(carCostFlow, costEntryAnswer(4000, CostPeriod.month));
  await c.answer(carCostFlow, costEntryAnswer(12000, CostPeriod.year));
  await c.skip(carCostFlow); // repairs
  await c.skip(carCostFlow); // loan
  await c.answer(carCostFlow, 3000000);
  await c.answer(carCostFlow, 1500000);
  await c.answer(carCostFlow, 5);
  await c.skip(carCostFlow); // parking
  await c.skip(carCostFlow); // other
  await c.answer(carCostFlow, basis ?? 'running');
}

/// Answers the car flow up to the extra cost step: a Golf, petrol, 6.5 l.
Future<void> answerCarUntilExtra(ProviderContainer c) async {
  await c.start(carSetupFlow);
  await c.answer(carSetupFlow, true);
  await c.answer(carSetupFlow, carNameAnswer('Golf', CarType.compact));
  await c.answer(carSetupFlow, FuelType.petrol.name);
  await c.answer(carSetupFlow, 6500);
}

/// `answerCarUntilExtra` on a container a screen is already showing; with
/// [finish] the flat rate is chosen too.
Future<void> answerCarUntilExtraOn(
  ProviderContainer c, {
  bool finish = true,
}) async {
  await answerCarUntilExtra(c);
  if (finish) await c.answer(carSetupFlow, ExtraCostChoice.flat);
}
