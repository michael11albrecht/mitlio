import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

DriveResult _result<T>(RepoResult<T> r, DriveResult Function(T) ok) =>
    switch (r) {
      Ok(:final value) => ok(value),
      Err(:final error) => driveError(error),
    };

/// A JSON list of strings as a set; null if [raw] is absent, a non-list or
/// has other elements.
Set<String>? _ids(String? raw) {
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is List && decoded.every((e) => e is String)
        ? decoded.cast<String>().toSet()
        : null;
  } on FormatException {
    return null;
  }
}

DateTime? _day(String? raw) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw ?? '');
  return m == null
      ? null
      : DateTime.utc(
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
        );
}

const _logUsage =
    'need groupId, driverId and templateId (or vehicleId and distanceMeters); '
    'optional passengerIds (JSON list, default: the template carpool), '
    'date (YYYY-MM-DD, default today), priceMilli (default: last price of the '
    'vehicle), roundTrip, tollsCents';

/// `ext.mitlio.rides.*`, `vehicles.create` and `templates.create`: thin
/// wrappers over the same ViewModel commands the UI calls (keys without the
/// `ext.mitlio.` prefix).
Map<String, DriveHandler> ridesDriveHandlers(ProviderContainer c) {
  RidesViewModel rides(String groupId) =>
      c.read(ridesViewModelProvider(groupId).notifier);
  RidesSetupViewModel setup(String groupId) =>
      c.read(ridesSetupViewModelProvider(groupId).notifier);
  return {
    'rides.log': (p) async {
      final groupId = p['groupId'];
      final driverId = p['driverId'];
      final passengers = p.containsKey('passengerIds')
          ? _ids(p['passengerIds'])
          : null;
      final date = p.containsKey('date') ? _day(p['date']) : null;
      final distance = int.tryParse(p['distanceMeters'] ?? '');
      if (groupId == null ||
          driverId == null ||
          (p.containsKey('passengerIds') && passengers == null) ||
          (p.containsKey('date') && date == null) ||
          (p['templateId'] == null &&
              (p['vehicleId'] == null || distance == null))) {
        return invalidParams(_logUsage);
      }
      final result = await rides(groupId).logRide(
        driverId: driverId,
        templateId: p['templateId'],
        vehicleId: p['vehicleId'],
        distanceMeters: distance,
        roundTrip: p['roundTrip'] == 'true',
        tollsCents: int.tryParse(p['tollsCents'] ?? '') ?? 0,
        passengerIds: passengers,
        date: date,
        priceMilli: int.tryParse(p['priceMilli'] ?? ''),
      );
      return _result(
        result,
        (logged) => {
          ...rideJson(logged.entry),
          'totalCents': logged.totalCents,
          'owes': [
            for (final o in logged.owes) {'name': o.name, 'cents': o.cents},
          ],
        },
      );
    },
    'rides.list': (p) async {
      final groupId = p['groupId'];
      final month = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(p['month'] ?? '');
      if (groupId == null || month == null) {
        return invalidParams('need groupId and month (YYYY-MM)');
      }
      final period = Month(
        int.parse(month.group(1)!),
        int.parse(month.group(2)!),
      );
      return _result(
        await rides(groupId).list(period),
        (list) => {'rides': list.map(rideJson).toList()},
      );
    },
    'rides.delete': (p) async {
      final id = p['id'];
      if (id == null) return invalidParams('need id');
      final entry = await c.read(ridesRepositoryProvider).get(id);
      if (entry case Err(:final error)) return driveError(error);
      final groupId = (entry as Ok<RideEntry, RepositoryError>).value.groupId;
      return _result(await rides(groupId).deleteRide(id), (_) => {'id': id});
    },
    'vehicles.create': (p) async {
      final groupId = p['groupId'];
      final name = p['name'];
      final fuel = FuelType.values
          .where((f) => f.name == (p['fuelType'] ?? 'petrol'))
          .firstOrNull;
      final consumption = int.tryParse(p['consumptionMilliPer100km'] ?? '');
      if (groupId == null ||
          name == null ||
          fuel == null ||
          consumption == null) {
        return invalidParams(
          'need groupId, name, consumptionMilliPer100km; optional fuelType '
          '(petrol|diesel|electric|other), wearMilliPerKm, kmRateMilliPerKm',
        );
      }
      return _result(
        await setup(groupId).addVehicle(
          name: name,
          fuelType: fuel,
          consumptionMilliPer100km: consumption,
          wearMilliPerKm: int.tryParse(p['wearMilliPerKm'] ?? '') ?? 0,
          kmRateMilliPerKm: int.tryParse(p['kmRateMilliPerKm'] ?? ''),
        ),
        vehicleJson,
      );
    },
    'templates.create': (p) async {
      final groupId = p['groupId'];
      final name = p['name'];
      final distance = int.tryParse(p['distanceMeters'] ?? '');
      final vehicleId = p['vehicleId'];
      final passengers = p.containsKey('defaultPassengerIds')
          ? _ids(p['defaultPassengerIds'])
          : const <String>{};
      if (groupId == null ||
          name == null ||
          distance == null ||
          vehicleId == null ||
          passengers == null) {
        return invalidParams(
          'need groupId, name, distanceMeters (one way), vehicleId; optional '
          'roundTrip, defaultDriverId, defaultPassengerIds (JSON list), '
          'tollsCents',
        );
      }
      return _result(
        await setup(groupId).addTemplate(
          RideTemplate(
            id: '',
            name: name,
            distanceMeters: distance,
            vehicleId: vehicleId,
            roundTrip: p['roundTrip'] == 'true',
            defaultDriverId: p['defaultDriverId'],
            defaultPassengerIds: passengers,
            tollsCents: int.tryParse(p['tollsCents'] ?? '') ?? 0,
          ),
        ),
        templateJson,
      );
    },
  };
}
