import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/first_value.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Which template the form works on: a new one in `groupId`, or, with a
/// `templateId`, the stored one.
typedef TemplateFormKey = ({String groupId, String? templateId});

sealed class TemplateFormState {
  const TemplateFormState();
}

final class TemplateFormLoading extends TemplateFormState {
  const TemplateFormLoading();
}

/// Also covers a group or template that does not exist ([NotFound]).
final class TemplateFormFailure extends TemplateFormState {
  const TemplateFormFailure(this.error);

  final RepositoryError error;
}

final class TemplateFormReady extends TemplateFormState {
  const TemplateFormReady({
    required this.group,
    required this.members,
    required this.vehicles,
    required this.editing,
    required this.name,
    required this.distanceMeters,
    required this.roundTrip,
    required this.vehicleId,
    required this.defaultDriverId,
    required this.defaultPassengerIds,
    required this.tollsCents,
    required this.showErrors,
    required this.saving,
  });

  final Group group;

  /// In position order.
  final List<GroupMember> members;
  final List<Vehicle> vehicles;
  final bool editing;
  final String name;

  /// One way, in metres; null while empty or invalid.
  final int? distanceMeters;
  final bool roundTrip;
  final String? vehicleId;
  final String? defaultDriverId;
  final Set<String> defaultPassengerIds;
  final int? tollsCents;
  final bool showErrors;
  final bool saving;

  bool get nameMissing => name.trim().isEmpty;
  bool get distanceMissing => distanceMeters == null || distanceMeters == 0;
  bool get vehicleMissing => vehicleId == null;
  bool get hasIssues => nameMissing || distanceMissing || vehicleMissing;
}

/// Add or edit one ride template ("Arbeit"): distance, round trip, vehicle,
/// default driver and passengers, tolls. Saves through
/// [RidesSetupViewModel].
class TemplateFormViewModel extends Notifier<TemplateFormState> {
  TemplateFormViewModel(this.key);

  final TemplateFormKey key;

  late Group _group;
  late List<GroupMember> _members;
  late List<Vehicle> _vehicles;
  var _name = '';
  int? _distance;
  var _roundTrip = true;
  String? _vehicleId;
  String? _driverId;
  var _passengers = <String>{};
  int? _tolls;
  var _showErrors = false;
  var _saving = false;
  var _loaded = false;

  @override
  TemplateFormState build() {
    _loaded = false;
    unawaited(_load());
    return const TemplateFormLoading();
  }

  void _set(TemplateFormState next) {
    if (ref.mounted) state = next;
  }

  Future<void> _load() async {
    try {
      final group = await ref.read(groupsRepositoryProvider).get(key.groupId);
      if (group case Err(:final error)) return _set(TemplateFormFailure(error));
      final members =
          (await ref.read(membersRepositoryProvider).list(key.groupId))
              .orThrow();
      final vehicles = await firstValue(
        ref.read(vehiclesRepositoryProvider).watchVehicles(key.groupId),
      );
      RideTemplate? stored;
      final id = key.templateId;
      if (id != null) {
        final got = await ref.read(rideTemplatesRepositoryProvider).get(id);
        if (got case Err(:final error)) {
          return _set(TemplateFormFailure(error));
        }
        stored = (got as Ok<RideTemplate, RepositoryError>).value;
      }
      if (!ref.mounted) return;
      _group = (group as Ok<Group, RepositoryError>).value;
      _members = members;
      _vehicles = vehicles;
      // Smart default: the only vehicle (or the first one).
      _vehicleId = vehicles.isEmpty ? null : vehicles.first.id;
      if (stored != null) {
        _name = stored.name;
        _distance = stored.distanceMeters;
        _roundTrip = stored.roundTrip;
        _vehicleId = stored.vehicleId;
        _driverId = stored.defaultDriverId;
        _passengers = {...stored.defaultPassengerIds};
        _tolls = stored.tollsCents == 0 ? null : stored.tollsCents;
      }
      _loaded = true;
      _emit();
    } on Object catch (e) {
      _set(TemplateFormFailure(e is RepositoryError ? e : Storage(e)));
    }
  }

  void _emit() {
    if (!_loaded) return;
    _set(
      TemplateFormReady(
        group: _group,
        members: _members,
        vehicles: _vehicles,
        editing: key.templateId != null,
        name: _name,
        distanceMeters: _distance,
        roundTrip: _roundTrip,
        vehicleId: _vehicleId,
        defaultDriverId: _driverId,
        defaultPassengerIds: Set.unmodifiable(_passengers),
        tollsCents: _tolls,
        showErrors: _showErrors,
        saving: _saving,
      ),
    );
  }

  void retry() {
    state = const TemplateFormLoading();
    ref.invalidateSelf();
  }

  void setName(String value) {
    _name = value;
    _emit();
  }

  /// One-way distance in metres; null while the field is empty or invalid.
  void setDistance(int? meters) {
    _distance = meters;
    _emit();
  }

  void setRoundTrip({required bool on}) {
    _roundTrip = on;
    _emit();
  }

  void setVehicle(String id) {
    _vehicleId = id;
    _emit();
  }

  /// The usual driver; null for "no fixed driver". The driver cannot also be
  /// a passenger.
  void setDefaultDriver(String? id) {
    _driverId = id;
    if (id != null) _passengers.remove(id);
    _emit();
  }

  /// Toggles [id] among the usual passengers (the driver is ignored).
  void togglePassenger(String id) {
    if (id == _driverId) return;
    if (!_passengers.remove(id)) _passengers.add(id);
    _emit();
  }

  void setTolls(int? cents) {
    _tolls = cents;
    _emit();
  }

  /// Stores the template. A form with problems answers [InvalidData] and
  /// shows them inline from then on.
  Future<RepoResult<RideTemplate>> save() async {
    final form = state;
    if (form is! TemplateFormReady || form.saving) {
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
    final id = key.templateId;
    final template = RideTemplate(
      id: id ?? '',
      name: _name,
      distanceMeters: _distance!,
      roundTrip: _roundTrip,
      vehicleId: _vehicleId!,
      defaultDriverId: _driverId,
      defaultPassengerIds: Set.of(_passengers),
      tollsCents: _tolls ?? 0,
    );
    final result = id == null
        ? await setup.addTemplate(template)
        : await setup.updateTemplate(template);
    _saving = false;
    _emit();
    return result;
  }

  JsonMap debugSnapshot() => switch (state) {
    TemplateFormLoading() => {'status': 'loading'},
    TemplateFormFailure(:final error) => {
      'status': 'error',
      'error': error.toString(),
    },
    final TemplateFormReady f => {
      'status': 'ready',
      'editing': f.editing,
      'name': f.name,
      'distanceMeters': f.distanceMeters,
      'roundTrip': f.roundTrip,
      'vehicleId': f.vehicleId,
      'defaultDriverId': f.defaultDriverId,
      'defaultPassengerIds': f.defaultPassengerIds.toList()..sort(),
      'tollsCents': f.tollsCents,
      'valid': !f.hasIssues,
    },
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final templateFormViewModelProvider =
    NotifierProvider.family<
      TemplateFormViewModel,
      TemplateFormState,
      TemplateFormKey
    >(TemplateFormViewModel.new);
