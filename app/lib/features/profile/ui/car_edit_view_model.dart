import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/personal_car_links_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

sealed class CarEditState {
  const CarEditState();
}

final class CarEditLoading extends CarEditState {
  const CarEditLoading();
}

/// Also covers a car that does not exist ([NotFound]).
final class CarEditFailure extends CarEditState {
  const CarEditFailure(this.error);

  final RepositoryError error;
}

final class CarEditReady extends CarEditState {
  const CarEditReady({
    required this.name,
    required this.fuelType,
    required this.consumptionMilli,
    required this.wearMilli,
    required this.showErrors,
    required this.saving,
  });

  final String name;
  final FuelType fuelType;

  /// Litres or kWh per 100 km in thousandths; null while empty or invalid.
  final int? consumptionMilli;

  /// Extra cost per km in thousandths of the euro; null counts as none.
  final int? wearMilli;
  final bool showErrors;
  final bool saving;

  bool get nameMissing => name.trim().isEmpty;
  bool get consumptionMissing =>
      consumptionMilli == null || consumptionMilli == 0;
  bool get hasIssues => nameMissing || consumptionMissing;
}

/// Editing a personal car in one step (ADR-25 §4: a returning user gets the
/// single field, not the flow). Saving carries the values to every group
/// that uses the car and returns the way back for the undo snackbar.
class CarEditViewModel extends Notifier<CarEditState> {
  CarEditViewModel(this.carId);

  final String carId;

  Vehicle? _loaded;
  var _name = '';
  FuelType _fuel = FuelType.petrol;
  int? _consumption;
  int? _wear;
  var _showErrors = false;
  var _saving = false;

  @override
  CarEditState build() {
    _loaded = null;
    _showErrors = false;
    _saving = false;
    unawaited(_load());
    return const CarEditLoading();
  }

  Future<void> _load() async {
    final result = await ref.read(userVehiclesRepositoryProvider).get(carId);
    if (!ref.mounted) return;
    switch (result) {
      case Err(:final error):
        state = CarEditFailure(error);
      case Ok(:final value):
        _loaded = value;
        _name = value.name;
        _fuel = value.fuelType;
        _consumption = value.consumptionMilliPer100km;
        _wear = value.wearMilliPerKm;
        _emit();
    }
  }

  void _emit() {
    state = CarEditReady(
      name: _name,
      fuelType: _fuel,
      consumptionMilli: _consumption,
      wearMilli: _wear,
      showErrors: _showErrors,
      saving: _saving,
    );
  }

  /// Starts over after a failure.
  void retry() {
    state = const CarEditLoading();
    ref.invalidateSelf();
  }

  void setName(String value) {
    _name = value;
    _emit();
  }

  void setFuelType(FuelType value) {
    _fuel = value;
    _emit();
  }

  void setConsumption(int? milli) {
    _consumption = milli;
    _emit();
  }

  void setWear(int? milli) {
    _wear = milli;
    _emit();
  }

  /// Validates and saves; [InvalidData] when the form shows what is missing.
  Future<RepoResult<PersonalCarUpdate>> save() async {
    final before = _loaded;
    if (before == null || _saving) {
      return const Err(InvalidData('car is not loaded'));
    }
    _showErrors = true;
    final consumption = _consumption;
    if (_name.trim().isEmpty || consumption == null || consumption <= 0) {
      _emit();
      return const Err(InvalidData('car form has issues'));
    }
    _saving = true;
    _emit();
    final Vehicle car;
    try {
      car = Vehicle(
        id: before.id,
        name: _name.trim(),
        fuelType: _fuel,
        consumptionMilliPer100km: consumption,
        wearMilliPerKm: _wear ?? 0,
        kmRateMilliPerKm: before.kmRateMilliPerKm,
      );
      // ignore: avoid_catching_errors, the domain signals bad values with ArgumentError
    } on ArgumentError catch (e) {
      _saving = false;
      _emit();
      return Err(InvalidData('car: $e'));
    }
    final result = await ref
        .read(personalCarLinksRepositoryProvider)
        .update(car);
    _saving = false;
    if (ref.mounted) _emit();
    return result;
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final carEditViewModelProvider = NotifierProvider.autoDispose
    .family<CarEditViewModel, CarEditState, String>(CarEditViewModel.new);
