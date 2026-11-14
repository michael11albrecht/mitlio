import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Which vehicle the form works on: a new one in `groupId`, or, with a
/// `vehicleId`, the stored one.
typedef VehicleFormKey = ({String groupId, String? vehicleId});

sealed class VehicleFormState {
  const VehicleFormState();
}

final class VehicleFormLoading extends VehicleFormState {
  const VehicleFormLoading();
}

/// Also covers a group or vehicle that does not exist ([NotFound]).
final class VehicleFormFailure extends VehicleFormState {
  const VehicleFormFailure(this.error);

  final RepositoryError error;
}

final class VehicleFormReady extends VehicleFormState {
  const VehicleFormReady({
    required this.currency,
    required this.editing,
    required this.name,
    required this.fuelType,
    required this.consumptionMilli,
    required this.wearMilli,
    required this.kmRateMilli,
    required this.showErrors,
    required this.saving,
  });

  final Currency currency;
  final bool editing;
  final String name;
  final FuelType fuelType;

  /// Litres or kWh per 100 km, in thousandths; null while empty or invalid.
  final int? consumptionMilli;

  /// Wear per km in thousandths of the major unit; null counts as none.
  final int? wearMilli;

  /// Fixed rate per km in thousandths; null means the vehicle has none.
  final int? kmRateMilli;
  final bool showErrors;
  final bool saving;

  bool get nameMissing => name.trim().isEmpty;
  bool get consumptionMissing =>
      consumptionMilli == null || consumptionMilli == 0;
  bool get hasIssues => nameMissing || consumptionMissing;
}

/// Add or edit one vehicle: name, fuel, consumption, optional wear and km
/// rate. Fields are commands; `save` validates and stores through
/// [RidesSetupViewModel], the same API DebugDrive calls.
class VehicleFormViewModel extends Notifier<VehicleFormState> {
  VehicleFormViewModel(this.key);

  final VehicleFormKey key;

  late Currency _currency;
  var _name = '';
  FuelType _fuel = FuelType.petrol;
  int? _consumption;
  int? _wear;
  int? _kmRate;
  var _showErrors = false;
  var _saving = false;
  var _loaded = false;

  @override
  VehicleFormState build() {
    _loaded = false;
    unawaited(_load());
    return const VehicleFormLoading();
  }

  void _set(VehicleFormState next) {
    if (ref.mounted) state = next;
  }

  Future<void> _load() async {
    try {
      final group = await ref.read(groupsRepositoryProvider).get(key.groupId);
      if (group case Err(:final error)) return _set(VehicleFormFailure(error));
      Vehicle? stored;
      final id = key.vehicleId;
      if (id != null) {
        final got = await ref.read(vehiclesRepositoryProvider).get(id);
        if (got case Err(:final error)) return _set(VehicleFormFailure(error));
        stored = (got as Ok<Vehicle, RepositoryError>).value;
      }
      if (!ref.mounted) return;
      _currency = (group as Ok<Group, RepositoryError>).value.currency;
      if (stored != null) {
        _name = stored.name;
        _fuel = stored.fuelType;
        _consumption = stored.consumptionMilliPer100km;
        _wear = stored.wearMilliPerKm == 0 ? null : stored.wearMilliPerKm;
        _kmRate = stored.kmRateMilliPerKm;
      }
      _loaded = true;
      _emit();
    } on Object catch (e) {
      _set(VehicleFormFailure(e is RepositoryError ? e : Storage(e)));
    }
  }

  void _emit() {
    if (!_loaded) return;
    _set(
      VehicleFormReady(
        currency: _currency,
        editing: key.vehicleId != null,
        name: _name,
        fuelType: _fuel,
        consumptionMilli: _consumption,
        wearMilli: _wear,
        kmRateMilli: _kmRate,
        showErrors: _showErrors,
        saving: _saving,
      ),
    );
  }

  void retry() {
    state = const VehicleFormLoading();
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

  void setKmRate(int? milli) {
    _kmRate = milli;
    _emit();
  }

  /// Stores the vehicle. A form with problems answers [InvalidData] and
  /// shows them inline from then on.
  Future<RepoResult<Vehicle>> save() async {
    final form = state;
    if (form is! VehicleFormReady || form.saving) {
      return const Err(InvalidData('form not ready'));
    }
    if (form.hasIssues) {
      _showErrors = true;
      _emit();
      return const Err(InvalidData('fix the highlighted fields'));
    }
    _saving = true;
    _emit();
    final setup = ref.read(ridesSetupViewModelProvider(key.groupId).notifier);
    final id = key.vehicleId;
    final result = id == null
        ? await setup.addVehicle(
            name: _name,
            fuelType: _fuel,
            consumptionMilliPer100km: _consumption!,
            wearMilliPerKm: _wear ?? 0,
            kmRateMilliPerKm: _kmRate,
          )
        : await setup.updateVehicle(
            Vehicle(
              id: id,
              name: _name.trim(),
              fuelType: _fuel,
              consumptionMilliPer100km: _consumption!,
              wearMilliPerKm: _wear ?? 0,
              kmRateMilliPerKm: _kmRate,
            ),
          );
    _saving = false;
    _emit();
    return result;
  }

  JsonMap debugSnapshot() => switch (state) {
    VehicleFormLoading() => {'status': 'loading'},
    VehicleFormFailure(:final error) => {
      'status': 'error',
      'error': error.toString(),
    },
    final VehicleFormReady f => {
      'status': 'ready',
      'editing': f.editing,
      'name': f.name,
      'fuelType': f.fuelType.name,
      'consumptionMilliPer100km': f.consumptionMilli,
      'wearMilliPerKm': f.wearMilli,
      'kmRateMilliPerKm': f.kmRateMilli,
      'valid': !f.hasIssues,
    },
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final vehicleFormViewModelProvider =
    NotifierProvider.family<
      VehicleFormViewModel,
      VehicleFormState,
      VehicleFormKey
    >(VehicleFormViewModel.new);
