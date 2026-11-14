import 'package:mitlio/core/clock.dart';
import 'package:mitlio/features/fuel/data/fuel_price.dart';
import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart';
import 'package:mitlio/features/fuel/data/services/location_service.dart';

export 'package:mitlio/features/fuel/data/fuel_price.dart';

/// Looks prices up and remembers the last known one per grade and scope, so
/// the forms still show something offline (with its age).
class FuelPricesRepository {
  FuelPricesRepository({
    required this._service,
    required this._location,
    required this._clock,
    this.reuseFor = const Duration(minutes: 1),
  });

  final FuelPriceService _service;
  final LocationService _location;
  final Clock _clock;

  /// A price fetched less ago than this is reused instead of asked again.
  final Duration reuseFor;

  final Map<String, ({FuelPrice price, DateTime at})> _cache = {};

  /// Whether the price feature is on (a backend is configured).
  bool get isAvailable => _service.isConfigured;

  /// Whether "in meiner Nähe" can be offered.
  bool get canLocate => isAvailable && _location.isSupported && !_nearbyOff;

  /// Set once the backend said `provider_unconfigured` (no provider key): the
  /// option then disappears for the session instead of failing again.
  bool _nearbyOff = false;

  /// Set once the permission is blocked for good: no further plugin calls.
  bool _blocked = false;

  /// The national average: no location involved.
  Future<FuelOutcome> national(FuelGrade grade) => _lookup(grade, null);

  /// The average for a typed postcode; `invalidParams` for a malformed one.
  Future<FuelOutcome> forPlz(FuelGrade grade, String plz) =>
      PlzArea.isValid(plz)
      ? _lookup(grade, PlzArea(plz))
      : Future.value(const FuelMissing(FuelFailure.invalidParams));

  /// Asks for the position (this is where the permission prompt happens),
  /// then looks around it. Only call after an explicit user tap.
  Future<FuelOutcome> nearby(FuelGrade grade) async {
    if (!canLocate) return const FuelMissing(FuelFailure.locationUnavailable);
    if (_blocked) return const FuelMissing(FuelFailure.locationBlocked);
    final position = await _location.current();
    return switch (position) {
      LocationFound(:final lat, :final lng) => _nearbyLookup(
        grade,
        // Rounded on the device (about 1 km): the exact spot never leaves it.
        NearbyArea(lat: _round2(lat), lng: _round2(lng)),
      ),
      LocationDeniedForever() => _block(),
      LocationDenied() => const FuelMissing(FuelFailure.locationDenied),
      LocationUnavailable() => const FuelMissing(
        FuelFailure.locationUnavailable,
      ),
    };
  }

  static double _round2(double v) => (v * 100).round() / 100;

  FuelOutcome _block() {
    _blocked = true;
    return const FuelMissing(FuelFailure.locationBlocked);
  }

  Future<FuelOutcome> _nearbyLookup(FuelGrade grade, NearbyArea area) async {
    final outcome = await _lookup(grade, area);
    if (outcome case FuelMissing(reason: FuelFailure.providerUnconfigured)) {
      _nearbyOff = true;
    }
    return outcome;
  }

  Future<FuelOutcome> _lookup(FuelGrade grade, FuelArea? area) async {
    if (!isAvailable) return const FuelMissing(FuelFailure.unavailable);
    final scope = switch (area) {
      null => FuelScope.national,
      PlzArea() => FuelScope.plz,
      NearbyArea() => FuelScope.nearby,
    };
    // Keyed by scope (and postcode), never by coordinates: the cache holds
    // no position.
    final key =
        '${grade.name}|${scope.name}|${area is PlzArea ? area.plz : ''}';
    final now = _clock.now();
    final hit = _cache[key];
    if (hit != null && now.difference(hit.at) < reuseFor) {
      return FuelFound(hit.price);
    }
    final result = await _service.fetch(grade, area: area);
    switch (result) {
      case FuelServiceOk(:final price):
        _cache[key] = (price: price, at: now);
        return FuelFound(price);
      case FuelServiceFailure(:final reason):
        return hit == null
            ? FuelMissing(reason)
            : FuelFound(hit.price, stale: true);
    }
  }
}
