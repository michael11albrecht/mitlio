import 'package:mitlio_domain/mitlio_domain.dart';

/// Version of the domain rules this facade computes with.
const int version = domainRulesVersion;

/// Largest supported number of persons.
const maxPersons = 100;

/// Calculates a trip cost from a plain (JS-like) input map.
///
/// Boundary conversion (decimal user input to the domain's integer units,
/// each rounded half up, i.e. `(value * scale).round()` for non-negative
/// values):
///
/// | Field | Unit | Domain unit |
/// |---|---|---|
/// | `distanceKm` | km | metres (x 1000) |
/// | `consumptionPer100km` | l or kWh | thousandths (x 1000) |
/// | `pricePerUnit` | EUR per l/kWh | thousandths (x 1000) |
/// | `wearPerKm` (optional) | EUR per km | thousandths (x 1000) |
/// | `kmRate` (optional) | EUR per km | thousandths (x 1000) |
/// | `tollsEur` (optional) | EUR | cents (x 100) |
/// | `extrasEur` (optional) | EUR, ferry/other | cents (x 100) |
///
/// If `kmRate` is given it replaces fuel and wear (consumption and price are
/// then ignored, as is `wearPerKm`). Persons are anonymous: ids `p0..pN-1`,
/// `p0` is the driver,
/// `driverPays` maps to `driverCounts`.
///
/// Returns `{ok: true, totalCents, perPersonCents, breakdown}` or
/// `{ok: false, error: <name>[, field: <input field>]}`.
Map<String, Object?> calculateTrip(Map<String, Object?> input) {
  try {
    return _calculate(input);
  } on MoneyOverflow {
    return _fail('MoneyOverflow');
  }
}

Map<String, Object?> _fail(String error, [String? field]) => {
  'ok': false,
  'error': error,
  'field': ?field,
};

typedef _Scaled = ({int? value, Map<String, Object?>? error});

// Reads a non-negative finite number scaled to an integer.
_Scaled _scaled(
  Map<String, Object?> input,
  String field,
  int scale, {
  required bool required,
}) {
  final raw = input[field];
  if (raw == null) {
    return required
        ? (value: null, error: _fail('InvalidNumber', field))
        : (value: 0, error: null);
  }
  if (raw is! num || raw.isNaN || raw.isInfinite) {
    return (value: null, error: _fail('InvalidNumber', field));
  }
  final scaled = scaleDecimal(raw, scale);
  return switch (scaled.failure) {
    null => (value: scaled.units, error: null),
    ScaleFailure.negative => (
      value: null,
      error: _fail('TripNegativeValue', field),
    ),
    ScaleFailure.invalid => (value: null, error: _fail('InvalidNumber', field)),
  };
}

Map<String, Object?> _calculate(Map<String, Object?> input) {
  final persons = input['persons'];
  if (persons is! num ||
      !persons.isFinite ||
      persons != persons.truncate() ||
      persons < 1 ||
      persons > maxPersons) {
    return _fail('InvalidPersons', 'persons');
  }
  final driverPays = input['driverPays'];
  if (driverPays is! bool) return _fail('InvalidBoolean', 'driverPays');
  final roundTrip = input['roundTrip'] ?? false;
  if (roundTrip is! bool) return _fail('InvalidBoolean', 'roundTrip');

  final hasKmRate = input['kmRate'] != null;
  final distance = _scaled(input, 'distanceKm', kmToMeters, required: true);
  // With a km rate, consumption, price and wear are ignored entirely.
  final consumption = hasKmRate
      ? (value: 0, error: null)
      : _scaled(input, 'consumptionPer100km', unitToMilli, required: true);
  final price = hasKmRate
      ? (value: 0, error: null)
      : _scaled(input, 'pricePerUnit', unitToMilli, required: true);
  final wear = hasKmRate
      ? (value: 0, error: null)
      : _scaled(input, 'wearPerKm', unitToMilli, required: false);
  final kmRate = _scaled(input, 'kmRate', unitToMilli, required: false);
  final tolls = _scaled(input, 'tollsEur', eurToCents, required: false);
  final extras = _scaled(input, 'extrasEur', eurToCents, required: false);
  for (final r in [distance, consumption, price, wear, kmRate, tolls, extras]) {
    if (r.error != null) return r.error!;
  }

  final n = persons.toInt();
  final ids = [for (var i = 0; i < n; i++) 'p$i'];
  final members = [
    for (var i = 0; i < n; i++) Member(id: ids[i], position: i),
  ];
  final mode = hasKmRate
      ? KmRate(kmRate.value!)
      : Consumption(
          consumptionMilliPer100km: consumption.value!,
          pricePerUnitMilli: price.value!,
          wearMilliPerKm: wear.value!,
        );
  final result = computeTripCost(
    TripInput(
      distanceMeters: distance.value!,
      roundTrip: roundTrip,
      currency: Currency.eur,
      mode: mode,
      tollsCents: tolls.value!,
      ferryCents: extras.value!,
      driverId: ids.first,
      passengerIds: ids.skip(1).toSet(),
      driverCounts: driverPays,
    ),
    members,
  );
  return switch (result) {
    Ok(:final value) => {
      'ok': true,
      'totalCents': value.totalCents,
      'perPersonCents': [for (final id in ids) value.shares[id]!],
      'breakdown': {
        'fuelCents': value.fuelCents,
        'wearCents': value.wearCents,
        'kmRateCents': value.kmRateCents,
        'tollsCents': value.tollsCents,
        'ferryCents': value.ferryCents,
      },
    },
    Err(:final error) => switch (error) {
      NonPositiveDistance() => _fail('NonPositiveDistance', 'distanceKm'),
      TripNegativeValue(:final field) => _fail('TripNegativeValue', field),
      TripNoParticipants() => _fail('TripNoParticipants', 'persons'),
      DriverIsPassenger() => _fail('DriverIsPassenger'),
      TripUnknownMember() => _fail('TripUnknownMember'),
      UnsupportedCurrency() => _fail('UnsupportedCurrency'),
      // Rides only; the trip calculator never sets a km rate on a vehicle.
      MissingKmRate() => _fail('MissingKmRate'),
    },
  };
}
