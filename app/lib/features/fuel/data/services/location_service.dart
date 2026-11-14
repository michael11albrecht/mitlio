/// The device position, asked for only after an explicit tap ("in meiner
/// Nähe", plan §2.6). Never called on its own.
sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  const LocationFound({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

/// The user said no (or the permission is blocked).
final class LocationDenied extends LocationResult {
  const LocationDenied();
}

/// No position could be determined.
final class LocationUnavailable extends LocationResult {
  const LocationUnavailable();
}

abstract interface class LocationService {
  /// Whether this build can ask for a position at all. `false` hides the
  /// "in meiner Nähe" action.
  bool get isSupported;

  /// Asks for the permission now (if needed) and returns the position.
  Future<LocationResult> current();
}

/// Default until a platform location plugin is wired (it needs native
/// permission strings, see docs/fuel-prices-api.md). Only the national
/// average and a typed postcode work then.
class NoLocationService implements LocationService {
  const NoLocationService();

  @override
  bool get isSupported => false;

  @override
  Future<LocationResult> current() async => const LocationUnavailable();
}

/// Test fake: a scripted answer and a counter of how often it was asked.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.result = const LocationFound(lat: 52.52, lng: 13.405),
  });

  LocationResult result;
  int asked = 0;

  @override
  bool get isSupported => true;

  @override
  Future<LocationResult> current() async {
    asked++;
    return result;
  }
}
