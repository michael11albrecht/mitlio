import 'package:mitlio/features/routes/data/route_models.dart';
import 'package:mitlio/features/routes/data/services/route_distance_service.dart';

/// In-memory route API for tests and DebugDrive: a few German cities with
/// fixed distances, a switch for failures, and a log of what was asked.
class FakeRouteDistanceService implements RouteDistanceService {
  FakeRouteDistanceService({this.configured = true});

  static const karlsruhe = PlaceSuggestion(
    label: 'Karlsruhe, Baden-Württemberg, Deutschland',
    lat: 49.0069,
    lng: 8.4037,
  );
  static const stuttgart = PlaceSuggestion(
    label: 'Stuttgart, Baden-Württemberg, Deutschland',
    lat: 48.7758,
    lng: 9.1829,
  );
  static const berlin = PlaceSuggestion(
    label: 'Berlin, Deutschland',
    lat: 52.52,
    lng: 13.405,
  );

  static const attribution =
      'Karten- und Routendaten © OpenStreetMap-Mitwirkende, '
      'via openrouteservice';

  /// Whether a backend "is configured".
  bool configured;

  /// Makes every call fail with this reason while set.
  RouteFailure? failWith;

  /// The `Retry-After` that goes with [failWith].
  Duration? failRetryAfter;

  /// Distance for a route (either direction); others answer
  /// [RouteFailure.noRoute].
  final Map<({String a, String b}), int> distances = {
    (a: karlsruhe.label, b: stuttgart.label): 81000,
    (a: karlsruhe.label, b: berlin.label): 650400,
  };

  /// Every request in order: `suggest:<text>` or `distance:<from>><to>`.
  final List<String> calls = [];

  @override
  bool get isConfigured => configured;

  @override
  Future<RouteResult<List<PlaceSuggestion>>> suggest(
    String text, {
    required String lang,
  }) async {
    calls.add('suggest:$text');
    final failure = _failure<List<PlaceSuggestion>>();
    if (failure != null) return failure;
    final needle = text.toLowerCase();
    return RouteOk([
      for (final p in const [karlsruhe, stuttgart, berlin])
        if (p.label.toLowerCase().contains(needle)) p,
    ], attribution: attribution);
  }

  @override
  Future<RouteResult<int>> distance(
    PlaceSuggestion from,
    PlaceSuggestion to,
  ) async {
    calls.add('distance:${from.label}>${to.label}');
    final failure = _failure<int>();
    if (failure != null) return failure;
    final meters =
        distances[(a: from.label, b: to.label)] ??
        distances[(a: to.label, b: from.label)];
    return meters == null
        ? const RouteFail(RouteFailure.noRoute)
        : RouteOk(meters, attribution: attribution);
  }

  RouteFail<T>? _failure<T>() {
    if (!configured) return const RouteFail(RouteFailure.unavailable);
    final reason = failWith;
    return reason == null
        ? null
        : RouteFail(reason, retryAfter: failRetryAfter);
  }
}
