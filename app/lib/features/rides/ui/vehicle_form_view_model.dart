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
    this.suggestions = const [],
    this.noMatch = false,
    this.catalogUnavailable = false,
    this.fromCatalog,
    this.realisticApplied = false,
    this.nameRevision = 0,
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

  /// Car catalog hits for the typed name, best first (at most 5).
  final List<CarCatalogEntry> suggestions;

  /// The typed name is long enough but nothing in the catalog matches.
  final bool noMatch;

  /// The catalog could not be loaded; the form works as before, by hand.
  final bool catalogUnavailable;

  /// The picked catalog car while fuel and consumption still come from it;
  /// a manual edit of either clears it.
  final CarCatalogEntry? fromCatalog;

  /// Consumption is the "realistic" estimate of [fromCatalog], not WLTP.
  final bool realisticApplied;

  /// Counts name changes the form made itself (pick, undo), so the text
  /// field knows to adopt [name].
  final int nameRevision;

  /// The realistic estimate for [fromCatalog], null when it has none.
  int? get realisticMilli {
    final car = fromCatalog;
    return car == null
        ? null
        : realisticConsumptionMilli(
            car.fuelType,
            car.consumptionMilliPer100km,
          );
  }

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
  var _suggestions = const <CarCatalogEntry>[];
  var _noMatch = false;
  var _catalogFailed = false;
  CarCatalogEntry? _picked;
  var _realistic = false;
  var _nameRevision = 0;
  var _searchSeq = 0;

  @override
  VehicleFormState build() {
    _loaded = false;
    _suggestions = const [];
    _noMatch = false;
    _catalogFailed = false;
    _picked = null;
    _realistic = false;
    _searchSeq++;
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
        suggestions: _suggestions,
        noMatch: _noMatch,
        catalogUnavailable: _catalogFailed,
        fromCatalog: _picked,
        realisticApplied: _realistic,
        nameRevision: _nameRevision,
      ),
    );
  }

  void retry() {
    state = const VehicleFormLoading();
    ref.invalidateSelf();
  }

  /// The user typed [value]: also looks it up in the car catalog.
  void setName(String value) {
    _name = value;
    _emit();
    unawaited(searchCatalog(value));
  }

  void setFuelType(FuelType value) {
    if (value != _fuel) _forgetCatalog();
    _fuel = value;
    _emit();
  }

  void setConsumption(int? milli) {
    if (milli != _consumption) _forgetCatalog();
    _consumption = milli;
    _emit();
  }

  /// The values no longer come from the catalog: drop the WLTP note.
  void _forgetCatalog() {
    _picked = null;
    _realistic = false;
  }

  /// Fills [VehicleFormReady.suggestions] with up to five catalog cars for
  /// [query] (offline, from the bundled EEA list). Fewer than two letters
  /// clears them. A catalog that cannot be loaded is reported through
  /// [VehicleFormReady.catalogUnavailable]; the next call tries again.
  Future<void> searchCatalog(String query) async {
    final seq = ++_searchSeq;
    if (query.trim().length < 2) {
      _suggestions = const [];
      _noMatch = false;
      _emit();
      return;
    }
    final loaded = await ref.read(carCatalogRepositoryProvider).load();
    if (!ref.mounted || seq != _searchSeq) return; // A newer search won.
    switch (loaded) {
      case Err():
        _catalogFailed = true;
        _suggestions = const [];
        _noMatch = false;
      case Ok(:final value):
        _catalogFailed = false;
        _suggestions = value.search(query);
        _noMatch = _suggestions.isEmpty;
    }
    _emit();
  }

  /// Takes name, fuel and consumption (manufacturer value, WLTP) from the
  /// catalog car [entry]; everything stays editable. Returns an [Undo] only
  /// when a consumption the user had entered was replaced; null otherwise.
  Undo? applyCatalogEntry(CarCatalogEntry entry) {
    if (!_loaded) return null;
    final before = (
      name: _name,
      fuel: _fuel,
      consumption: _consumption,
      picked: _picked,
      realistic: _realistic,
    );
    final overwrote =
        before.consumption != null &&
        before.consumption != entry.consumptionMilliPer100km;
    _searchSeq++; // Drop a lookup that is still running.
    _name = entry.name;
    _fuel = entry.fuelType;
    _consumption = entry.consumptionMilliPer100km;
    _picked = entry;
    _realistic = false;
    _suggestions = const [];
    _noMatch = false;
    _nameRevision++;
    _emit();
    if (!overwrote) return null;
    return Undo(() async {
      if (ref.mounted) {
        _name = before.name;
        _fuel = before.fuel;
        _consumption = before.consumption;
        _picked = before.picked;
        _realistic = before.realistic;
        _nameRevision++;
        _emit();
      }
      return const Ok(null);
    });
  }

  /// Replaces the catalog value with the realistic estimate (WLTP plus the
  /// documented real-world gap). Does nothing without a picked car or when
  /// the fuel has no sourced estimate.
  void useRealisticConsumption() {
    final car = _picked;
    if (car == null) return;
    final real = realisticConsumptionMilli(
      car.fuelType,
      car.consumptionMilliPer100km,
    );
    if (real == null) return;
    _consumption = real;
    _realistic = true;
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
      'fromCatalog': f.fromCatalog?.name,
      'realisticApplied': f.realisticApplied,
      'catalogUnavailable': f.catalogUnavailable,
      'noMatch': f.noMatch,
      'suggestions': [
        for (final e in f.suggestions)
          {
            'name': e.name,
            'fuelType': e.fuelType.name,
            'hybrid': e.hybrid,
            'engineCc': e.engineCc,
            'powerKw': e.powerKw,
            'consumptionMilliPer100km': e.consumptionMilliPer100km,
          },
      ],
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
