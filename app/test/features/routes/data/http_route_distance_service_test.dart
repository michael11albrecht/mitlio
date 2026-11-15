import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/routes/data/route_models.dart';
import 'package:mitlio/features/routes/data/services/route_distance_service.dart';

/// Talks to a loopback server: the real `dart:io` client, no network.
void main() {
  late HttpServer server;
  late List<({HttpRequest request, String body})> seen;
  var status = 200;
  var body = '';
  String? retryAfter;

  setUp(() async {
    seen = [];
    status = 200;
    retryAfter = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.forEach((request) async {
        final text = await utf8.decoder.bind(request).join();
        seen.add((request: request, body: text));
        request.response.statusCode = status;
        if (retryAfter != null) {
          request.response.headers.set('retry-after', retryAfter!);
        }
        request.response.write(body);
        await request.response.close();
      }),
    );
  });
  tearDown(() => server.close(force: true));

  HttpRouteDistanceService service({String? base}) => HttpRouteDistanceService(
    baseUrl: base ?? 'http://${server.address.host}:${server.port}/',
    anonKey: 'anon',
    timeout: const Duration(seconds: 2),
  );

  const a = PlaceSuggestion(label: 'A', lat: 49.0069, lng: 8.4037);
  const b = PlaceSuggestion(label: 'B', lat: 48.7758, lng: 9.1829);

  final suggestions = jsonEncode({
    'suggestions': [
      {'label': 'Karlsruhe, BW', 'lat': 49.0069, 'lng': 8.4037},
      {'label': '', 'lat': 1, 'lng': 2},
      {'label': 'Bad', 'lat': 'x', 'lng': 2},
      'junk',
    ],
    'attribution': '© OSM, via openrouteservice',
  });

  test(
    'suggest posts JSON (text in the body, not the URL) with the keys',
    () async {
      body = suggestions;
      final r = await service().suggest('Karlsruhe', lang: 'de');
      final ok = r as RouteOk<List<PlaceSuggestion>>;
      expect(ok.value, [
        const PlaceSuggestion(
          label: 'Karlsruhe, BW',
          lat: 49.0069,
          lng: 8.4037,
        ),
      ]);
      expect(ok.attribution, '© OSM, via openrouteservice');
      final s = seen.single;
      expect(s.request.method, 'POST');
      expect(s.request.uri.path, '/functions/v1/route-distance');
      expect(s.request.uri.query, isEmpty);
      expect(s.request.headers.value('apikey'), 'anon');
      expect(s.request.headers.value('authorization'), 'Bearer anon');
      expect(jsonDecode(s.body), {
        'action': 'suggest',
        'text': 'Karlsruhe',
        'lang': 'de',
      });
    },
  );

  test('distance posts both coordinates and reads metres', () async {
    body = '{"meters":81234,"attribution":"credit"}';
    final r = await service().distance(a, b) as RouteOk<int>;
    expect(r.value, 81234);
    expect(r.attribution, 'credit');
    expect(jsonDecode(seen.single.body), {
      'action': 'distance',
      'from': {'lat': 49.0069, 'lng': 8.4037},
      'to': {'lat': 48.7758, 'lng': 9.1829},
    });
  });

  test('a base URL with a trailing slash works', () async {
    body = '{"meters":1}';
    final base = 'http://${server.address.host}:${server.port}/';
    await service(base: base).distance(a, b);
    expect(seen.single.request.uri.path, '/functions/v1/route-distance');
  });

  test('status codes map to failures, each told apart', () async {
    for (final (code, text, reason) in [
      (400, '{"error":"invalid_params"}', RouteFailure.invalidParams),
      (404, '{"error":"no_route"}', RouteFailure.noRoute),
      (404, '{"error":"other"}', RouteFailure.provider),
      (429, '{"error":"rate_limited"}', RouteFailure.rateLimited),
      (500, '{"error":"x"}', RouteFailure.provider),
      (503, '{"error":"provider_unavailable"}', RouteFailure.provider),
      (503, '{"error":"provider_unconfigured"}', RouteFailure.provider),
    ]) {
      status = code;
      body = text;
      final r = await service().distance(a, b) as RouteFail<int>;
      expect(r.reason, reason, reason: '$code $text');
    }
  });

  test('429 reads Retry-After in whole minutes', () async {
    status = 429;
    body = '{"error":"rate_limited"}';
    for (final (header, minutes) in [
      ('1800', 30),
      ('61', 2),
      ('60', 1),
      (null, null),
      ('later', null),
    ]) {
      retryAfter = header;
      final r = await service().suggest('abc', lang: 'de') as RouteFail;
      expect(r.reason, RouteFailure.rateLimited);
      expect(
        r.retryAfter,
        minutes == null ? isNull : Duration(minutes: minutes),
        reason: '$header',
      );
    }
  });

  test('malformed 200 bodies are the service failing, not offline', () async {
    for (final text in [
      'not json',
      '[]',
      '{}',
      '{"meters":"5"}',
      '{"meters":-1}',
    ]) {
      body = text;
      final r = await service().distance(a, b) as RouteFail<int>;
      expect(r.reason, RouteFailure.provider, reason: text);
    }
    body = '{"nope":1}';
    final s = await service().suggest('abc', lang: 'de') as RouteFail;
    expect(s.reason, RouteFailure.provider);
  });

  test('at most five suggestions are kept', () async {
    body = jsonEncode({
      'suggestions': [
        for (var i = 0; i < 8; i++) {'label': 'P$i', 'lat': i, 'lng': i},
      ],
    });
    final r = await service().suggest(
      'abc',
      lang: 'en',
    ) as RouteOk<List<PlaceSuggestion>>;
    expect(r.value, hasLength(5));
    expect(r.attribution, isEmpty);
  });

  test('nothing listens: offline', () async {
    final port = server.port;
    await server.close(force: true);
    final r = await service(
      base: 'http://127.0.0.1:$port',
    ).distance(a, b) as RouteFail<int>;
    expect(r.reason, RouteFailure.offline);
  });

  test('a server that never answers times out as offline', () async {
    final silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(silent.close);
    unawaited(silent.forEach((_) {}));
    final slow = HttpRouteDistanceService(
      baseUrl: 'http://127.0.0.1:${silent.port}',
      anonKey: 'k',
      timeout: const Duration(milliseconds: 200),
    );
    final r = await slow.distance(a, b) as RouteFail<int>;
    expect(r.reason, RouteFailure.offline);
  });

  test('no base URL: unavailable without a request', () async {
    final s = HttpRouteDistanceService(baseUrl: '', anonKey: 'k');
    expect(s.isConfigured, isFalse);
    expect(
      (await s.distance(a, b) as RouteFail<int>).reason,
      RouteFailure.unavailable,
    );
    expect(seen, isEmpty);
  });

  test('the unavailable service reports unavailable', () async {
    const s = UnavailableRouteDistanceService();
    expect(s.isConfigured, isFalse);
    expect(
      (await s.suggest('abc', lang: 'de') as RouteFail).reason,
      RouteFailure.unavailable,
    );
    expect(
      (await s.distance(a, b) as RouteFail<int>).reason,
      RouteFailure.unavailable,
    );
  });
}
