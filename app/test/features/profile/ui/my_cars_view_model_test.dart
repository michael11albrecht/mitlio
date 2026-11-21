import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/ui/my_cars_view_model.dart';
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

  Future<Vehicle> addCar(String name) async => ((await fakes.cars.add(
    name: name,
    fuelType: FuelType.petrol,
    consumptionMilliPer100km: 6500,
  )) as Ok<Vehicle, RepositoryError>).value;

  /// Lets the repository stream deliver.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  MyCarsState state() => c.read(myCarsViewModelProvider);

  test('loads, then lists the cars in creation order', () async {
    await addCar('Golf');
    await addCar('Zoe');
    expect(state(), isA<MyCarsLoading>());
    await settle();
    expect(
      [for (final v in c.read(myCarsViewModelProvider.notifier).cars) v.name],
      [
        'Golf',
        'Zoe',
      ],
    );
  });

  test('no cars is loaded and empty, not a failure', () async {
    c.read(myCarsViewModelProvider);
    await settle();
    expect(state(), isA<MyCarsLoaded>());
    expect(c.read(myCarsViewModelProvider.notifier).cars, isEmpty);
  });

  test('follows the repository: a new car appears', () async {
    c.read(myCarsViewModelProvider);
    await settle();
    await addCar('Golf');
    await settle();
    expect(c.read(myCarsViewModelProvider.notifier).cars, hasLength(1));
  });

  test('remove hides the car, undo brings it back', () async {
    final golf = await addCar('Golf');
    c.read(myCarsViewModelProvider);
    await settle();
    final vm = c.read(myCarsViewModelProvider.notifier);
    final undo =
        ((await vm.remove(golf.id)) as Ok<Undo, RepositoryError>).value;
    await settle();
    expect(vm.cars, isEmpty);
    await undo.call();
    await settle();
    expect(vm.cars.single.id, golf.id);
  });

  test('remove of an unknown car is NotFound', () async {
    final r = await c.read(myCarsViewModelProvider.notifier).remove('nope');
    expect((r as Err<Undo, RepositoryError>).error, isA<NotFound>());
  });

  test('a failing repository is reported, not swallowed', () async {
    final golf = await addCar('Golf');
    fakes.cars.failDeleteWith = const Storage('disk full');
    final r = await c.read(myCarsViewModelProvider.notifier).remove(golf.id);
    expect((r as Err<Undo, RepositoryError>).error, isA<Storage>());
  });

  test('a failing stream is a failure state, retry starts over', () async {
    fakes.cars.watchError = const Storage('disk gone');
    c.read(myCarsViewModelProvider);
    await settle();
    expect(
      (state() as MyCarsFailure).error,
      const Storage('disk gone'),
    );
    fakes.cars.watchError = null;
    c.read(myCarsViewModelProvider.notifier).retry();
    expect(state(), isA<MyCarsLoading>());
    await settle();
    expect(state(), isA<MyCarsLoaded>());
  });
}
