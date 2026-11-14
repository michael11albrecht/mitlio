import 'dart:convert';

import 'package:mitlio_domain/mitlio_domain.dart';

/// Which energy the vehicle uses; only changes labels (l or kWh per 100 km).
enum TripEnergy { fuel, electric }

/// The inputs of a trip expense in domain units, stored as JSON in
/// `expenses.trip_meta` so the trip can be re-edited and the next trip can
/// start from the last driver, passengers and vehicle values.
final class TripMeta {
  const TripMeta({
    required this.distanceMeters,
    required this.roundTrip,
    required this.energy,
    required this.mode,
    required this.tollsCents,
    required this.ferryCents,
    required this.driverId,
    required this.passengerIds,
    required this.driverCounts,
  });

  /// Reads [json]; null if it is not a version 1 trip meta document.
  static TripMeta? tryParse(String? json) {
    if (json == null) return null;
    try {
      final m = jsonDecode(json);
      if (m is! Map<String, dynamic> || m['v'] != 1) return null;
      final mode = switch (m['mode']) {
        'consumption' => Consumption(
          consumptionMilliPer100km: m['consumptionMilliPer100km'] as int,
          pricePerUnitMilli: m['pricePerUnitMilli'] as int,
          wearMilliPerKm: m['wearMilliPerKm'] as int,
        ),
        'kmRate' => KmRate(m['kmRateMilliPerKm'] as int),
        _ => null,
      };
      if (mode == null) return null;
      return TripMeta(
        distanceMeters: m['distanceMeters'] as int,
        roundTrip: m['roundTrip'] as bool,
        energy: m['energy'] == 'electric'
            ? TripEnergy.electric
            : TripEnergy.fuel,
        mode: mode,
        tollsCents: m['tollsCents'] as int,
        ferryCents: m['ferryCents'] as int,
        driverId: m['driverId'] as String,
        passengerIds: {...(m['passengerIds'] as List<dynamic>).cast<String>()},
        driverCounts: m['driverCounts'] as bool,
      );
    } on Object {
      // Any malformed document (bad JSON, missing or mistyped field).
      return null;
    }
  }

  final int distanceMeters;
  final bool roundTrip;
  final TripEnergy energy;
  final TripCostMode mode;
  final int tollsCents;
  final int ferryCents;
  final String driverId;
  final Set<String> passengerIds;
  final bool driverCounts;

  String toJson() => jsonEncode({
    'v': 1,
    'distanceMeters': distanceMeters,
    'roundTrip': roundTrip,
    'energy': energy.name,
    ...switch (mode) {
      Consumption(
        :final consumptionMilliPer100km,
        :final pricePerUnitMilli,
        :final wearMilliPerKm,
      ) =>
        {
          'mode': 'consumption',
          'consumptionMilliPer100km': consumptionMilliPer100km,
          'pricePerUnitMilli': pricePerUnitMilli,
          'wearMilliPerKm': wearMilliPerKm,
        },
      KmRate(:final kmRateMilliPerKm) => {
        'mode': 'kmRate',
        'kmRateMilliPerKm': kmRateMilliPerKm,
      },
    },
    'tollsCents': tollsCents,
    'ferryCents': ferryCents,
    'driverId': driverId,
    'passengerIds': passengerIds.toList()..sort(),
    'driverCounts': driverCounts,
  });
}
