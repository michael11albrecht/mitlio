import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart'
    show parseRetryAfter;
import 'package:mitlio/features/routes/data/route_models.dart';

/// The `route-distance` API (contract: docs/route-distance-api.md).
abstract interface class RouteDistanceService {
  /// Whether a backend is configured. `false` hides the whole feature, so
  /// the forms show only the manual kilometre field.
  bool get isConfigured;

  /// Up to five places for [text] (at least three characters).
  Future<RouteResult<List<PlaceSuggestion>>> suggest(
    String text, {
    required String lang,
  });

  /// Driving distance in metres, fastest route.
  Future<RouteResult<int>> distance(PlaceSuggestion from, PlaceSuggestion to);
}

/// No backend configured (empty `SUPABASE_URL`): the UI shows nothing.
class UnavailableRouteDistanceService implements RouteDistanceService {
  const UnavailableRouteDistanceService();

  @override
  bool get isConfigured => false;

  @override
  Future<RouteResult<List<PlaceSuggestion>>> suggest(
    String text, {
    required String lang,
  }) async => const RouteFail(RouteFailure.unavailable);

  @override
  Future<RouteResult<int>> distance(
    PlaceSuggestion from,
    PlaceSuggestion to,
  ) async => const RouteFail(RouteFailure.unavailable);
}

/// Calls the `route-distance` Edge Function over `dart:io` (POST with a JSON
/// body, so the typed text never lands in a URL or an access log).
class HttpRouteDistanceService implements RouteDistanceService {
  HttpRouteDistanceService({
    required this.baseUrl,
    required this.anonKey,
    HttpClient Function()? clientFactory,
    this.timeout = const Duration(seconds: 10),
  }) : _clientFactory = clientFactory ?? HttpClient.new;

  final String baseUrl;
  final String anonKey;
  final Duration timeout;
  final HttpClient Function() _clientFactory;

  @override
  bool get isConfigured => baseUrl.isNotEmpty;

  Uri get uri {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base/functions/v1/route-distance');
  }

  @override
  Future<RouteResult<List<PlaceSuggestion>>> suggest(
    String text, {
    required String lang,
  }) => _post(
    {'action': 'suggest', 'text': text, 'lang': lang},
    _parseSuggestions,
  );

  @override
  Future<RouteResult<int>> distance(PlaceSuggestion from, PlaceSuggestion to) =>
      _post({
        'action': 'distance',
        'from': {'lat': from.lat, 'lng': from.lng},
        'to': {'lat': to.lat, 'lng': to.lng},
      }, _parseDistance);

  Future<RouteResult<T>> _post<T>(
    Map<String, Object?> payload,
    RouteResult<T> Function(String body) parse,
  ) async {
    if (!isConfigured) return const RouteFail(RouteFailure.unavailable);
    final client = _clientFactory()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(uri);
      request.headers
        ..set('apikey', anonKey)
        ..set(HttpHeaders.authorizationHeader, 'Bearer $anonKey')
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode == 200) return parse(body);
      return _failure(
        response.statusCode,
        body,
        response.headers.value(HttpHeaders.retryAfterHeader),
      );
    } on SocketException {
      return const RouteFail(RouteFailure.offline);
    } on TimeoutException {
      return const RouteFail(RouteFailure.offline);
    } on HandshakeException {
      return const RouteFail(RouteFailure.offline);
    } on HttpException {
      return const RouteFail(RouteFailure.offline);
    } on FormatException {
      // The answer came but was not readable: the service is broken, we are
      // not offline.
      return const RouteFail(RouteFailure.provider);
    } finally {
      client.close(force: true);
    }
  }

  static RouteResult<T> _failure<T>(int status, String body, String? wait) =>
      switch (status) {
        429 => RouteFail(
          RouteFailure.rateLimited,
          retryAfter: parseRetryAfter(wait),
        ),
        404 when body.contains('no_route') => const RouteFail(
          RouteFailure.noRoute,
        ),
        400 => const RouteFail(RouteFailure.invalidParams),
        503 when body.contains('provider_unconfigured') => const RouteFail(
          RouteFailure.providerUnconfigured,
        ),
        _ => const RouteFail(RouteFailure.provider),
      };
}

RouteResult<List<PlaceSuggestion>> _parseSuggestions(String body) {
  final json = _object(body);
  final list = json?['suggestions'];
  if (json == null || list is! List<Object?>) {
    return const RouteFail(RouteFailure.provider);
  }
  final places = <PlaceSuggestion>[];
  for (final item in list) {
    if (item is! Map<String, Object?>) continue;
    final label = item['label'];
    final lat = item['lat'];
    final lng = item['lng'];
    if (label is String && label.isNotEmpty && lat is num && lng is num) {
      places.add(
        PlaceSuggestion(
          label: label,
          lat: lat.toDouble(),
          lng: lng.toDouble(),
        ),
      );
    }
  }
  return RouteOk(places.take(5).toList(), attribution: _attribution(json));
}

RouteResult<int> _parseDistance(String body) {
  final json = _object(body);
  final meters = json?['meters'];
  if (json == null || meters is! int || meters < 0) {
    return const RouteFail(RouteFailure.provider);
  }
  return RouteOk(meters, attribution: _attribution(json));
}

String _attribution(Map<String, Object?> json) {
  final a = json['attribution'];
  return a is String ? a : '';
}

Map<String, Object?>? _object(String body) {
  final json = jsonDecode(body);
  return json is Map<String, Object?> ? json : null;
}
