import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/fuel/data/fuel_price.dart';
import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart';

/// Talks to a loopback server: the real `dart:io` client, no network.
void main() {
  late HttpServer server;
  late List<HttpRequest> seen;
  var status = 200;
  var body = '';

  setUp(() async {
    seen = [];
    status = 200;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.forEach((request) async {
        seen.add(request);
        request.response
          ..statusCode = status
          ..write(body);
        await request.response.close();
      }),
    );
  });
  tearDown(() => server.close(force: true));

  HttpFuelPriceService service({String? base}) => HttpFuelPriceService(
    baseUrl: base ?? 'http://${server.address.host}:${server.port}/',
    anonKey: 'anon',
  );

  const ok =
      '{"type":"e5","priceMilli":1799,"source":"tankerkoenig",'
      '"scope":"national","fetchedAt":"2026-11-14T11:48:00Z","stations":14000,'
      '"attribution":"Daten: MTS-K via Tankerkönig (CC BY 4.0)"}';

  test('national request: type only, anon key headers', () async {
    body = ok;
    final result = await service().fetch(FuelGrade.e5) as FuelServiceOk;
    expect(result.price.priceMilli, 1799);
    expect(result.price.scope, FuelScope.national);
    expect(result.price.fetchedAt, DateTime.utc(2026, 11, 14, 11, 48));
    expect(result.price.attribution, contains('MTS-K'));
    final r = seen.single;
    expect(r.uri.path, '/functions/v1/fuel-prices');
    expect(r.uri.queryParameters, {'type': 'e5'});
    expect(r.headers.value('apikey'), 'anon');
    expect(r.headers.value('authorization'), 'Bearer anon');
  });

  test('postcode request', () async {
    body = ok;
    await service().fetch(FuelGrade.diesel, area: const PlzArea('10115'));
    expect(seen.single.uri.queryParameters, {'type': 'diesel', 'plz': '10115'});
  });

  test('coordinates leave the device rounded to about 1 km', () async {
    body = ok;
    await service().fetch(
      FuelGrade.e10,
      area: const NearbyArea(lat: 52.520008, lng: 13.404954),
    );
    expect(seen.single.uri.queryParameters, {
      'type': 'e10',
      'lat': '52.52',
      'lng': '13.40',
      'radius': '5',
    });
  });

  test('EU bulletin answer: approximation and date are kept', () async {
    body = jsonEncode({
      'type': 'e10',
      'priceMilli': 1741,
      'source': 'eu-oil-bulletin',
      'scope': 'national',
      'fetchedAt': '2026-11-10T00:00:00Z',
      'stations': 0,
      'approximation': 'e5',
      'attribution': 'Quelle: EU Weekly Oil Bulletin',
    });
    final p = (await service().fetch(FuelGrade.e10) as FuelServiceOk).price;
    expect(p.source, 'eu-oil-bulletin');
    expect(p.approximation, FuelGrade.e5);
    expect(p.attribution, 'Quelle: EU Weekly Oil Bulletin');
  });

  test('status codes map to failures', () async {
    for (final (code, reason) in [
      (400, FuelFailure.invalidParams),
      (429, FuelFailure.rateLimited),
      (503, FuelFailure.provider),
      (500, FuelFailure.provider),
    ]) {
      status = code;
      body = '{"error":"x"}';
      final r = await service().fetch(FuelGrade.e5) as FuelServiceFailure;
      expect(r.reason, reason, reason: '$code');
    }
  });

  test('503 provider_unconfigured is told apart from an outage', () async {
    status = 503;
    body = '{"error":"provider_unconfigured"}';
    final r = await service().fetch(FuelGrade.e5) as FuelServiceFailure;
    expect(r.reason, FuelFailure.providerUnconfigured);
  });

  test('malformed 200 is a provider failure', () async {
    for (final bad in [
      'nope',
      '[]',
      '{"type":"e5"}',
      jsonEncode({
        'type': 'e5',
        'priceMilli': 0,
        'scope': 'national',
        'fetchedAt': '2026-01-01T00:00:00Z',
      }),
      '{"type":"e5","priceMilli":1,"scope":"national","fetchedAt":"x"}',
    ]) {
      body = bad;
      final r = await service().fetch(FuelGrade.e5) as FuelServiceFailure;
      expect(r.reason, FuelFailure.provider, reason: bad);
    }
  });

  test('unreachable server is offline', () async {
    final base = 'http://127.0.0.1:${server.port}';
    await server.close(force: true);
    final r = await service(base: base).fetch(FuelGrade.e5);
    expect((r as FuelServiceFailure).reason, FuelFailure.offline);
  });

  test('empty base URL is unavailable and sends nothing', () async {
    final s = service(base: '');
    expect(s.isConfigured, isFalse);
    final r = await s.fetch(FuelGrade.e5) as FuelServiceFailure;
    expect(r.reason, FuelFailure.unavailable);
    expect(seen, isEmpty);
  });

  test('the unavailable service reports unavailable', () async {
    const s = UnavailableFuelPriceService();
    expect(s.isConfigured, isFalse);
    expect(
      (await s.fetch(FuelGrade.e5) as FuelServiceFailure).reason,
      FuelFailure.unavailable,
    );
  });
}
