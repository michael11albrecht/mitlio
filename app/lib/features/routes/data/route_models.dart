// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// A place the user can pick as start or destination. The label is shown as
/// the provider sent it; the coordinates only go back to the proxy to get
/// the distance, they are never stored on a ride.
final class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is PlaceSuggestion &&
      other.label == label &&
      other.lat == lat &&
      other.lng == lng;

  @override
  int get hashCode => Object.hash(label, lat, lng);

  @override
  String toString() => 'PlaceSuggestion($label)';
}

/// The two remembered places. One of each, on this device only.
enum PlaceKind { home, work }

/// A saved place ("Zuhause", "Arbeit").
final class SavedPlace {
  const SavedPlace({required this.kind, required this.place});

  final PlaceKind kind;
  final PlaceSuggestion place;

  @override
  bool operator ==(Object other) =>
      other is SavedPlace && other.kind == kind && other.place == place;

  @override
  int get hashCode => Object.hash(kind, place);
}

/// Why a lookup gave nothing. Each one is shown to the user in plain words.
enum RouteFailure {
  /// No backend configured: the whole feature is hidden.
  unavailable,

  /// The request did not get through (no connection, timeout).
  offline,

  /// The server said "too many requests" (`Retry-After` known or not).
  rateLimited,

  /// The text or the places were not acceptable (too short, same spot).
  invalidParams,

  /// The service found no drivable route between the two places.
  noRoute,

  /// The routing service is down, not set up or answered garbage.
  provider,
}

/// Outcome of one call: a value plus the credit line, or the reason for none.
sealed class RouteResult<T> {
  const RouteResult();
}

final class RouteOk<T> extends RouteResult<T> {
  const RouteOk(this.value, {this.attribution = ''});

  final T value;

  /// Credit line as the server sends it; shown as is (licence requirement).
  final String attribution;
}

final class RouteFail<T> extends RouteResult<T> {
  const RouteFail(this.reason, {this.retryAfter});

  final RouteFailure reason;

  /// The server's `Retry-After`, in whole minutes (at least one).
  final Duration? retryAfter;
}
