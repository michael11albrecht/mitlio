import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/features/fx/data/repositories/fx_rates_repository.dart';
import 'package:mitlio/features/fx/data/services/fake_fx_rate_service.dart';
import 'package:mitlio/features/fx/data/services/fx_rate_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

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

  HttpFxRateService service({String? base}) => HttpFxRateService(
    baseUrl: base ?? 'http://${server.address.host}:${server.port}/',
    anonKey: 'anon',
  );

  const ok =
      '{"base":"USD","quote":"EUR","date":"2026-11-13","ratePpm":920000,'
      '"source":"frankfurter","fetchedAt":"2026-11-14T10:00:00.000Z",'
      '"attribution":"Quelle: EZB-Referenzkurse via Frankfurter"}';

  group('HttpFxRateService', () {
    test('latest request: only the pair, anon key headers', () async {
      body = ok;
      final found = await service().fetch(
        base: Currency.usd,
        quote: Currency.eur,
      );
      expect(found?.ppm, 920000);
      expect(found?.date, DateTime.utc(2026, 11, 13));
      expect(found?.attribution, contains('EZB'));
      final r = seen.single;
      expect(r.uri.path, '/functions/v1/fx-rates');
      expect(r.uri.queryParameters, {'base': 'USD', 'quote': 'EUR'});
      expect(r.headers.value('apikey'), 'anon');
      expect(r.headers.value('authorization'), 'Bearer anon');
      expect(r.headers.value('cookie'), isNull);
    });

    test('dated request sends the day', () async {
      body = ok;
      await service().fetch(
        base: Currency.usd,
        quote: Currency.eur,
        date: DateTime.utc(2026, 3, 7),
      );
      expect(seen.single.uri.queryParameters['date'], '2026-03-07');
    });

    test('a base URL with a trailing slash works', () {
      final uri = service(
        base: 'https://x.supabase.co/',
      ).uriFor(Currency.gbp, Currency.eur, null);
      expect(
        uri.toString(),
        'https://x.supabase.co/functions/v1/fx-rates?base=GBP&quote=EUR',
      );
    });

    for (final code in [404, 429, 503]) {
      test('status $code is no suggestion', () async {
        status = code;
        body = '{"error":"x"}';
        expect(
          await service().fetch(base: Currency.usd, quote: Currency.eur),
          isNull,
        );
      });
    }

    for (final garbage in [
      'not json',
      '[]',
      '{"ratePpm":0,"date":"2026-11-13"}',
      '{"ratePpm":"920000","date":"2026-11-13"}',
      '{"ratePpm":920000}',
      '{"ratePpm":920000,"date":"nope"}',
    ]) {
      test('a 200 with $garbage is no suggestion', () async {
        body = garbage;
        expect(
          await service().fetch(base: Currency.usd, quote: Currency.eur),
          isNull,
        );
      });
    }

    test('offline is no suggestion', () async {
      final dead = service(base: 'http://127.0.0.1:1');
      expect(
        await dead.fetch(base: Currency.usd, quote: Currency.eur),
        isNull,
      );
    });

    test('an empty base URL is not configured and sends nothing', () async {
      final off = service(base: '');
      expect(off.isConfigured, isFalse);
      expect(await off.fetch(base: Currency.usd, quote: Currency.eur), isNull);
      expect(seen, isEmpty);
    });

    test('parse keeps a missing attribution empty', () {
      final s = parseFxSuggestion(
        jsonEncode({'ratePpm': 5, 'date': '2026-01-02'}),
      );
      expect(s?.attribution, '');
      final same = parseFxSuggestion('{"ratePpm":5,"date":"2026-01-02"}');
      expect(s, same);
      expect(s.hashCode, same.hashCode);
    });
  });

  group('UnavailableFxRateService', () {
    test('is off and answers nothing', () async {
      const service = UnavailableFxRateService();
      expect(service.isConfigured, isFalse);
      expect(
        await service.fetch(base: Currency.usd, quote: Currency.eur),
        isNull,
      );
    });
  });

  group('FxRatesRepository', () {
    late FakeFxRateService fake;
    late FixedClock clock;
    late FxRatesRepository repository;

    setUp(() {
      fake = FakeFxRateService();
      clock = FixedClock(DateTime.utc(2026, 3, 1, 12));
      repository = FxRatesRepository(service: fake, clock: clock);
    });

    test('asks once and reuses the answer for a while', () async {
      final a = await repository.suggest(
        base: Currency.usd,
        quote: Currency.eur,
      );
      final b = await repository.suggest(
        base: Currency.usd,
        quote: Currency.eur,
      );
      expect(a?.ppm, 920000);
      expect(b, a);
      expect(fake.calls, hasLength(1));
      clock.value = clock.value.add(const Duration(minutes: 11));
      await repository.suggest(base: Currency.usd, quote: Currency.eur);
      expect(fake.calls, hasLength(2));
    });

    test('pair and day are part of the key', () async {
      await repository.suggest(base: Currency.usd, quote: Currency.eur);
      await repository.suggest(base: Currency.gbp, quote: Currency.eur);
      await repository.suggest(
        base: Currency.usd,
        quote: Currency.eur,
        date: DateTime.utc(2026, 2, 27),
      );
      expect(fake.calls, hasLength(3));
    });

    test('failures are not remembered', () async {
      fake.failing = true;
      expect(
        await repository.suggest(base: Currency.usd, quote: Currency.eur),
        isNull,
      );
      fake.failing = false;
      expect(
        await repository.suggest(base: Currency.usd, quote: Currency.eur),
        isNotNull,
      );
      expect(fake.calls, hasLength(2));
    });

    test('without a backend nothing is asked', () async {
      fake.configured = false;
      expect(repository.isAvailable, isFalse);
      expect(
        await repository.suggest(base: Currency.usd, quote: Currency.eur),
        isNull,
      );
      expect(fake.calls, isEmpty);
    });

    test('a pair the fake does not know is no suggestion', () async {
      expect(
        await repository.suggest(base: Currency.eur, quote: Currency.usd),
        isNull,
      );
    });
  });
}
