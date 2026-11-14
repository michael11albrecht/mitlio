/// Fuel grades the price API knows (`type=` of the contract in
/// docs/fuel-prices-api.md).
enum FuelGrade {
  e5,
  e10,
  diesel;

  /// The `type` query value.
  String get apiName => name;
}

/// How wide the average behind a price reaches.
enum FuelScope { national, plz, nearby }

/// Where to look: [PlzArea] (typed by the user) or [NearbyArea] (after an
/// explicit tap). No area at all means the national average.
sealed class FuelArea {
  const FuelArea();
}

/// A postcode the user typed.
final class PlzArea extends FuelArea {
  const PlzArea(this.plz);

  /// Five digits.
  final String plz;

  static final _fiveDigits = RegExp(r'^\d{5}$');

  /// Whether [text] has the shape of a German postcode.
  static bool isValid(String text) => _fiveDigits.hasMatch(text);
}

/// The device position, handed over by the user's explicit tap.
final class NearbyArea extends FuelArea {
  const NearbyArea({
    required this.lat,
    required this.lng,
    this.radiusKm = defaultRadiusKm,
  });

  static const defaultRadiusKm = 5;

  final double lat;
  final double lng;
  final int radiusKm;
}

/// A price per litre as the API reports it.
final class FuelPrice {
  const FuelPrice({
    required this.grade,
    required this.priceMilli,
    required this.scope,
    required this.fetchedAt,
    this.stations = 0,
    this.scopeKey,
    this.source = '',
    this.attribution = '',
    this.approximation,
  });

  final FuelGrade grade;

  /// Thousandths of EUR per litre (`1799` is 1,799 EUR/l).
  final int priceMilli;
  final FuelScope scope;

  /// The postcode for [FuelScope.plz], else null.
  final String? scopeKey;

  /// When the server last fetched it from the provider (UTC).
  final DateTime fetchedAt;
  final int stations;

  /// `tankerkoenig` or `eu-oil-bulletin`.
  final String source;

  /// Credit line as the server sends it; shown as is.
  final String attribution;

  /// Set when the value stands in for another grade (`e10` reported as
  /// `e5`); shown with a "≈".
  final FuelGrade? approximation;
}

/// Why no price came back.
enum FuelFailure {
  /// No backend configured: the feature is switched off.
  unavailable,

  /// The request did not get through.
  offline,
  rateLimited,
  invalidParams,

  /// The backend has no provider key or the provider is down.
  provider,
  locationDenied,
  locationUnavailable,
}

/// What a lookup gave: a price (maybe an old one) or the reason for none.
sealed class FuelOutcome {
  const FuelOutcome();
}

final class FuelFound extends FuelOutcome {
  const FuelFound(this.price, {this.stale = false});

  final FuelPrice price;

  /// The last known value, shown because the lookup failed.
  final bool stale;
}

final class FuelMissing extends FuelOutcome {
  const FuelMissing(this.reason);

  final FuelFailure reason;
}
