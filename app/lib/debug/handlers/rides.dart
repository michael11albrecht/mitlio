import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/ui/ride_settle_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
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

bool? _bool(String? raw) => switch (raw) {
  'true' => true,
  'false' => false,
  _ => null,
};

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

Month? _month(String? raw) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(raw ?? '');
  final month = m == null ? null : int.parse(m.group(2)!);
  return m == null || month! < 1 || month > 12
      ? null
      : Month(int.parse(m.group(1)!), month);
}

const _logUsage =
    'need groupId, driverId and templateId (or vehicleId and distanceMeters); '
    'optional passengerIds (JSON list, default: the template carpool), '
    'date (YYYY-MM-DD, default today), priceMilli (default: last price of the '
    'vehicle), roundTrip, tollsCents';

/// The vehicle form of ([groupId], [vehicleId]) once it has loaded; the same
/// instance the screen uses. [VehicleFormFailure] answers its error.
Future<({VehicleFormViewModel vm, DriveResult? error})> _openVehicleForm(
  ProviderContainer c,
  String groupId,
  String? vehicleId,
) async {
  final key = (groupId: groupId, vehicleId: vehicleId);
  final provider = vehicleFormViewModelProvider(key);
  final subscription = c.listen(provider, (_, _) {});
  try {
    for (var i = 0; i < 500 && c.read(provider) is VehicleFormLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final error = switch (c.read(provider)) {
      VehicleFormFailure(:final error) => driveError(error),
      VehicleFormLoading() => driveError(const Storage('form did not load')),
      VehicleFormReady() => null,
    };
    return (vm: c.read(provider.notifier), error: error);
  } finally {
    subscription.close();
  }
}

/// `ext.mitlio.rides.*`, `vehicles.*` and `templates.create`: thin
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
    'rides.settle': (p) async {
      final groupId = p['groupId'];
      final month = _month(p['month']);
      if (groupId == null || month == null) {
        return invalidParams('need groupId and month (YYYY-MM)');
      }
      final l10n = lookupAppLocalizations(const Locale('de'));
      return _result(
        await c
            .read(rideSettleViewModelProvider(groupId).notifier)
            .settle(
              month,
              titleOf: (name, m) =>
                  l10n.ridesSettleExpenseTitle(monthKey(m), name),
            ),
        (done) => {
          'month': monthKey(done.month),
          'rideCount': done.rideCount,
          'expenseIds': [for (final e in done.expenses) e.expense.id],
        },
      );
    },
    'rides.fairness': (p) async {
      final groupId = p['groupId'];
      final month = _month(p['month']);
      if (groupId == null || month == null) {
        return invalidParams('need groupId and month (YYYY-MM)');
      }
      return _result(
        await c
            .read(rideSettleViewModelProvider(groupId).notifier)
            .fairness(month),
        (json) => json,
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
    'rides.setCanDrive': (p) async {
      final groupId = p['groupId'];
      final memberId = p['memberId'];
      final canDrive = _bool(p['canDrive']);
      if (groupId == null || memberId == null || canDrive == null) {
        return invalidParams(
          'need groupId, memberId and canDrive (true|false)',
        );
      }
      return _result(
        await rides(groupId).setCanDrive(memberId, canDrive: canDrive),
        (_) => {'memberId': memberId, 'canDrive': canDrive},
      );
    },
    'rides.answerDriverPrompt': (p) async {
      final groupId = p['groupId'];
      final memberId = p['memberId'];
      final canDrive = _bool(p['canDrive']);
      if (groupId == null || memberId == null || canDrive == null) {
        return invalidParams(
          'need groupId, memberId and canDrive (true|false)',
        );
      }
      return _result(
        await rides(groupId).answerDriverPrompt(memberId, canDrive: canDrive),
        (undo) => {
          'memberId': memberId,
          'canDrive': canDrive,
          'undoable': undo != null,
        },
      );
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
    // The typeahead of the vehicle form (P9-T09), same VM as the screen.
    'vehicles.catalogSearch': (p) async {
      final groupId = p['groupId'];
      final query = p['query'];
      if (groupId == null || query == null) {
        return invalidParams('need groupId and query; optional vehicleId');
      }
      final form = await _openVehicleForm(c, groupId, p['vehicleId']);
      if (form.error != null) return form.error!;
      await form.vm.searchCatalog(query);
      final snap = form.vm.debugSnapshot();
      return {
        'query': query,
        'suggestions': snap['suggestions'],
        'noMatch': snap['noMatch'],
        'catalogUnavailable': snap['catalogUnavailable'],
      };
    },
    'vehicles.catalogPick': (p) async {
      final groupId = p['groupId'];
      final index = int.tryParse(p['index'] ?? '');
      if (groupId == null || index == null) {
        return invalidParams(
          'need groupId and index into the last catalogSearch result; '
          'optional vehicleId',
        );
      }
      final form = await _openVehicleForm(c, groupId, p['vehicleId']);
      if (form.error != null) return form.error!;
      final state = c.read(
        vehicleFormViewModelProvider((
          groupId: groupId,
          vehicleId: p['vehicleId'],
        )),
      );
      final suggestions = state is VehicleFormReady
          ? state.suggestions
          : const <CarCatalogEntry>[];
      if (index < 0 || index >= suggestions.length) {
        return invalidParams(
          'index $index outside the ${suggestions.length} suggestions',
        );
      }
      final undo = form.vm.applyCatalogEntry(suggestions[index]);
      final snap = form.vm.debugSnapshot();
      return {
        'name': snap['name'],
        'fuelType': snap['fuelType'],
        'consumptionMilliPer100km': snap['consumptionMilliPer100km'],
        'fromCatalog': snap['fromCatalog'],
        'undoable': undo != null,
      };
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
