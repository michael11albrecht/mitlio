import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `passengerIds` param: a JSON list of member ids; malformed is null.
Set<String>? _ids(String? raw) {
  if (raw == null) return const {};
  try {
    final decoded = jsonDecode(raw);
    return decoded is List && decoded.every((e) => e is String)
        ? decoded.cast<String>().toSet()
        : null;
  } on FormatException {
    return null;
  }
}

/// `true`/`false`; absent means [fallback], anything else null.
bool? _flag(String? raw, {required bool fallback}) => switch (raw) {
  null => fallback,
  'true' => true,
  'false' => false,
  _ => null,
};

/// The trip DTO of `ext.mitlio.trips.add`. Numbers are decimal text as typed
/// in the form (`6.5` or `6,5`); `kmRate` switches to the km-rate mode.
TripInputs? _inputs(Map<String, String> p) {
  final passengers = _ids(p['passengerIds']);
  final roundTrip = _flag(p['roundTrip'], fallback: false);
  final driverCounts = _flag(p['driverCounts'], fallback: true);
  if (passengers == null || roundTrip == null || driverCounts == null) {
    return null;
  }
  return TripInputs(
    distance: p['distance'] ?? '',
    roundTrip: roundTrip,
    energy: p['energy'] == 'electric' ? TripEnergy.electric : TripEnergy.fuel,
    useKmRate: p['kmRate'] != null,
    consumption: p['consumption'] ?? '',
    price: p['price'] ?? '',
    wear: p['wear'] ?? '',
    kmRate: p['kmRate'] ?? '',
    tolls: p['tolls'] ?? '',
    ferry: p['ferry'] ?? '',
    driverId: p['driverId'],
    passengerIds: passengers,
    driverCounts: driverCounts,
    title: p['title'] ?? '',
  );
}

/// `ext.mitlio.trips.*`: a thin wrapper over the same ViewModel command the
/// form's save button calls (keys without the `ext.mitlio.` prefix).
Map<String, DriveHandler> tripsDriveHandlers(ProviderContainer c) => {
  'trips.add': (p) async {
    final groupId = p['groupId'];
    final inputs = _inputs(p);
    if (groupId == null || inputs == null || inputs.driverId == null) {
      return invalidParams(
        'need groupId, driverId, distance and consumption+price or kmRate; '
        'optional passengerIds (JSON list), roundTrip, driverCounts, '
        'energy, wear, tolls, ferry, title',
      );
    }
    final vm = c.read(tripFormViewModelProvider(groupId).notifier);
    return switch (await vm.add(inputs, fallbackTitle: 'Trip')) {
      Ok(:final value) => {
        'id': value.entry.expense.id,
        'totalCents': value.entry.expense.amountCents,
        'shares': value.entry.expense.shares,
      },
      Err(:final error) => driveError(error),
    };
  },
};
