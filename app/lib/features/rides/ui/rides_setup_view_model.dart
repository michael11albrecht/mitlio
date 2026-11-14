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
import 'package:mitlio_domain/mitlio_domain.dart';

sealed class RidesSetupState {
  const RidesSetupState();
}

final class RidesSetupLoading extends RidesSetupState {
  const RidesSetupLoading();
}

final class RidesSetupFailure extends RidesSetupState {
  const RidesSetupFailure(this.error);

  final RepositoryError error;
}

final class RidesSetupLoaded extends RidesSetupState {
  const RidesSetupLoaded({
    required this.group,
    required this.members,
    required this.vehicles,
    required this.templates,
  });

  final Group group;

  /// In position order.
  final List<GroupMember> members;
  final List<Vehicle> vehicles;
  final List<RideTemplate> templates;

  Vehicle? vehicle(String id) => vehicles.where((v) => v.id == id).firstOrNull;

  GroupMember? member(String id) =>
      members.where((m) => m.id == id).firstOrNull;

  /// Templates that ride on [vehicleId].
  List<RideTemplate> templatesOf(String vehicleId) => [
    for (final t in templates)
      if (t.vehicleId == vehicleId) t,
  ];
}

/// Vehicles and ride templates of a group: the list behind the settings icon
/// of the rides tab and the add/update/delete commands the two forms and
/// DebugDrive share.
class RidesSetupViewModel extends Notifier<RidesSetupState> {
  RidesSetupViewModel(this.groupId);

  final String groupId;

  Group? _group;
  var _groupKnown = false;
  List<GroupMember>? _members;
  List<Vehicle>? _vehicles;
  List<RideTemplate>? _templates;
  RepositoryError? _failure;

  @override
  RidesSetupState build() {
    _group = null;
    _groupKnown = false;
    _members = null;
    _vehicles = null;
    _templates = null;
    _failure = null;
    final subs = [
      _listen(ref.watch(groupsRepositoryProvider).watchGroups(), (groups) {
        _group = groups.where((g) => g.id == groupId).firstOrNull;
        _groupKnown = true;
      }),
      _listen(
        ref.watch(membersRepositoryProvider).watchMembers(groupId),
        (members) => _members = members,
      ),
      _listen(
        ref.watch(vehiclesRepositoryProvider).watchVehicles(groupId),
        (vehicles) => _vehicles = vehicles,
      ),
      _listen(
        ref.watch(rideTemplatesRepositoryProvider).watchTemplates(groupId),
        (templates) => _templates = templates,
      ),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    return const RidesSetupLoading();
  }

  StreamSubscription<T> _listen<T>(Stream<T> stream, void Function(T) onData) =>
      stream.listen(
        (data) {
          onData(data);
          _emit();
        },
        onError: (Object e) {
          _failure = e is RepositoryError ? e : Storage(e);
          _emit();
        },
      );

  void _emit() {
    if (!ref.mounted) return;
    if (_failure != null) {
      state = RidesSetupFailure(_failure!);
    } else if (!_groupKnown ||
        _members == null ||
        _vehicles == null ||
        _templates == null) {
      state = const RidesSetupLoading();
    } else if (_group == null) {
      state = RidesSetupFailure(NotFound('group', groupId));
    } else {
      state = RidesSetupLoaded(
        group: _group!,
        members: _members!,
        vehicles: _vehicles!,
        templates: _templates!,
      );
    }
  }

  void retry() {
    state = const RidesSetupLoading();
    ref.invalidateSelf();
  }

  /// Adds a vehicle; the repository validates name and numbers.
  Future<RepoResult<Vehicle>> addVehicle({
    required String name,
    required FuelType fuelType,
    required int consumptionMilliPer100km,
    int wearMilliPerKm = 0,
    int? kmRateMilliPerKm,
  }) => ref
      .read(vehiclesRepositoryProvider)
      .add(
        groupId,
        name: name,
        fuelType: fuelType,
        consumptionMilliPer100km: consumptionMilliPer100km,
        wearMilliPerKm: wearMilliPerKm,
        kmRateMilliPerKm: kmRateMilliPerKm,
      );

  /// Replaces the stored vehicle with [vehicle]'s id as a whole.
  Future<RepoResult<Vehicle>> updateVehicle(Vehicle vehicle) =>
      ref.read(vehiclesRepositoryProvider).update(vehicle);

  /// Adds a template. A ride needs a distance, so [InvalidData] below 1 m
  /// (the repository only refuses negatives).
  Future<RepoResult<RideTemplate>> addTemplate(RideTemplate template) async =>
      template.distanceMeters <= 0
      ? const Err(InvalidData('distance must be > 0'))
      : ref.read(rideTemplatesRepositoryProvider).add(groupId, template);

  /// Replaces the stored template with [template]'s id as a whole.
  Future<RepoResult<RideTemplate>> updateTemplate(
    RideTemplate template,
  ) async => template.distanceMeters <= 0
      ? const Err(InvalidData('distance must be > 0'))
      : ref.read(rideTemplatesRepositoryProvider).update(template);

  /// Soft delete; [Conflict] while a template still rides on the vehicle.
  Future<RepoResult<Undo>> deleteVehicle(String id) async {
    final templates = await firstValue(
      ref.read(rideTemplatesRepositoryProvider).watchTemplates(groupId),
    );
    if (templates.any((t) => t.vehicleId == id)) {
      return const Err(Conflict('vehicle is used by a template'));
    }
    return ref.read(vehiclesRepositoryProvider).softDelete(id);
  }

  /// Soft delete; the returned [Undo] brings the template back.
  Future<RepoResult<Undo>> deleteTemplate(String id) =>
      ref.read(rideTemplatesRepositoryProvider).softDelete(id);

  JsonMap debugSnapshot() => switch (state) {
    RidesSetupLoading() => {'status': 'loading', 'groupId': groupId},
    RidesSetupFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    RidesSetupLoaded(:final vehicles, :final templates) => {
      'status': vehicles.isEmpty && templates.isEmpty ? 'empty' : 'data',
      'groupId': groupId,
      'vehicles': [for (final v in vehicles) vehicleJson(v)],
      'templates': [for (final t in templates) templateJson(t)],
    },
  };
}

/// JSON shape of a vehicle in snapshots and DebugDrive results.
JsonMap vehicleJson(Vehicle v) => {
  'id': v.id,
  'name': v.name,
  'fuelType': v.fuelType.name,
  'consumptionMilliPer100km': v.consumptionMilliPer100km,
  'wearMilliPerKm': v.wearMilliPerKm,
  'kmRateMilliPerKm': v.kmRateMilliPerKm,
};

/// JSON shape of a ride template in snapshots and DebugDrive results.
JsonMap templateJson(RideTemplate t) => {
  'id': t.id,
  'name': t.name,
  'distanceMeters': t.distanceMeters,
  'roundTrip': t.roundTrip,
  'vehicleId': t.vehicleId,
  'defaultDriverId': t.defaultDriverId,
  'defaultPassengerIds': t.defaultPassengerIds.toList()..sort(),
  'tollsCents': t.tollsCents,
};

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final ridesSetupViewModelProvider =
    NotifierProvider.family<RidesSetupViewModel, RidesSetupState, String>(
      RidesSetupViewModel.new,
    );
