import 'package:mitlio/features/routes/data/route_models.dart';
import 'package:mitlio/features/routes/data/services/route_distance_service.dart';

export 'package:mitlio/features/routes/data/route_models.dart';

/// Shortest text worth sending: the proxy refuses anything below this, so
/// the app does not even ask (also keeps partial keystrokes off the wire).
const minPlaceTextLength = 3;

/// Looks places and distances up through the proxy. Keeps nothing: no cache,
/// no history of what was typed.
class RouteDistanceRepository {
  RouteDistanceRepository(this._service);

  final RouteDistanceService _service;

  /// Whether the feature is on (a backend is configured and has a routing
  /// key). Off means the forms show only the manual kilometre field. Turns
  /// false for the rest of the session once the backend answered
  /// `provider_unconfigured`.
  bool get isAvailable => _service.isConfigured && !_off;

  bool _off = false;

  RouteResult<T> _note<T>(RouteResult<T> result) {
    if (result case RouteFail(reason: RouteFailure.providerUnconfigured)) {
      _off = true;
    }
    return result;
  }

  /// Up to five places for [text]; `invalidParams` for less than
  /// [minPlaceTextLength] characters.
  Future<RouteResult<List<PlaceSuggestion>>> suggest(
    String text, {
    required String lang,
  }) {
    if (!isAvailable) {
      return Future.value(const RouteFail(RouteFailure.unavailable));
    }
    final trimmed = text.trim();
    if (trimmed.runes.length < minPlaceTextLength) {
      return Future.value(const RouteFail(RouteFailure.invalidParams));
    }
    return _service.suggest(trimmed, lang: lang).then(_note);
  }

  /// Driving distance in metres; `invalidParams` when both places are the
  /// same spot.
  Future<RouteResult<int>> distance(PlaceSuggestion from, PlaceSuggestion to) {
    if (!isAvailable) {
      return Future.value(const RouteFail(RouteFailure.unavailable));
    }
    if (from.lat == to.lat && from.lng == to.lng) {
      return Future.value(const RouteFail(RouteFailure.invalidParams));
    }
    return _service.distance(from, to).then(_note);
  }
}
