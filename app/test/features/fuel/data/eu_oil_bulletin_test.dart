import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/features/fuel/data/fuel_price.dart';
import 'package:mitlio/features/fuel/data/services/eu_oil_bulletin_parser.dart';
import 'package:mitlio/features/fuel/data/services/eu_oil_bulletin_service.dart';
import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart';

/// Real-shaped fixture: the published bulletin file (same one the Edge
/// Function tests use). Germany, week of 2026-11-09.
void main() {
  final fixture = File(
    'test/fixtures/oil_bulletin_sample.xlsx',
  ).readAsBytesSync();

  group('parser', () {
    test('Germany: E5, diesel in milli-EUR per litre and the date', () {
      final p = parseBulletinXlsx(fixture);
      expect(p.e5Milli, 2067);
      expect(p.dieselMilli, 2253);
      expect(p.date, DateTime.utc(2026, 11, 9));
    });

    test('another country is read from its own row', () {
      final p = parseBulletinXlsx(fixture, country: 'Austria');
      expect(p.e5Milli, isNot(2067));
    });

    test('unknown country', () {
      expect(
        () => parseBulletinXlsx(fixture, country: 'Atlantis'),
        throwsA(isA<BulletinFormatException>()),
      );
    });

    test('not a zip, truncated, empty', () {
      expect(
        () => parseBulletinXlsx(Uint8List.fromList('hello'.codeUnits)),
        throwsA(isA<BulletinFormatException>()),
      );
      expect(
        () => parseBulletinXlsx(Uint8List(0)),
        throwsA(isA<BulletinFormatException>()),
      );
      expect(
        () => parseBulletinXlsx(fixture.sublist(0, fixture.length ~/ 2)),
        throwsA(isA<BulletinFormatException>()),
      );
    });

    test('corrupt deflate data in an entry', () {
      final broken = Uint8List.fromList(fixture);
      // Local header (30 bytes) + name of the sheet, then garbage as data.
      final name = 'xl/worksheets/sheet1.xml'.codeUnits;
      var at = 0;
      while (at < broken.length - name.length) {
        if (broken[at] == 0x50 &&
            broken[at + 1] == 0x4b &&
            broken[at + 2] == 3 &&
            broken[at + 3] == 4 &&
            broken[at + 30] == name[0] &&
            broken[at + 31] == name[1]) {
          final start = at + 30 + name.length;
          if (String.fromCharCodes(broken.sublist(at + 30, start)) ==
              'xl/worksheets/sheet1.xml') {
            for (var i = start; i < start + 40; i++) {
              broken[i] = 0xFF;
            }
            break;
          }
        }
        at++;
      }
      expect(
        () => parseBulletinXlsx(broken),
        throwsA(isA<BulletinFormatException>()),
      );
    });

    test('oversized input is rejected', () {
      expect(
        () => parseBulletinXlsx(Uint8List(5000001)),
        throwsA(isA<BulletinFormatException>()),
      );
    });

    test('Excel serial to UTC date', () {
      expect(excelSerialToDate(46335), DateTime.utc(2026, 11, 9));
      expect(excelSerialToDate(25569), DateTime.utc(1970));
    });
  });

  group('service', () {
    late HttpServer server;
    late int hits;
    late int status;
    late List<int> body;
    late Duration delay;
    late FixedClock clock;
    late Directory tmp;

    setUp(() async {
      hits = 0;
      status = 200;
      body = fixture;
      delay = Duration.zero;
      clock = FixedClock(DateTime.utc(2026, 11, 15, 12));
      tmp = await Directory.systemTemp.createTemp('bulletin_test');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(
        server.forEach((request) async {
          hits++;
          await Future<void>.delayed(delay);
          request.response
            ..statusCode = status
            ..add(body);
          await request.response.close();
        }),
      );
    });
    tearDown(() async {
      await server.close(force: true);
      await tmp.delete(recursive: true);
    });

    EuOilBulletinService service({
      File? cache,
      Uri? uri,
      Duration timeout = const Duration(seconds: 5),
    }) => EuOilBulletinService(
      clock: clock,
      cacheFile: cache,
      bulletinUri:
          uri ??
          Uri.parse('http://${server.address.host}:${server.port}/b.xlsx'),
      timeout: timeout,
    );

    test(
      'success: E5, diesel, E10 as E5 approximation, bulletin date',
      () async {
        final s = service();
        final e5 = await s.fetch(FuelGrade.e5) as FuelServiceOk;
        expect(e5.price.priceMilli, 2067);
        expect(e5.price.scope, FuelScope.national);
        expect(e5.price.fetchedAt, DateTime.utc(2026, 11, 9));
        expect(e5.price.source, 'eu-oil-bulletin');
        expect(e5.price.attribution, contains('EU Weekly Oil Bulletin'));
        expect(e5.price.approximation, isNull);
        final diesel = await s.fetch(FuelGrade.diesel) as FuelServiceOk;
        expect(diesel.price.priceMilli, 2253);
        final e10 = await s.fetch(FuelGrade.e10) as FuelServiceOk;
        expect(e10.price.priceMilli, 2067);
        expect(e10.price.approximation, FuelGrade.e5);
      },
    );

    test('is configured but national only', () {
      final s = service();
      expect(s.isConfigured, isTrue);
      expect(s.supportsAreas, isFalse);
    });

    test('an area is refused without any request', () async {
      final r = await service().fetch(
        FuelGrade.e5,
        area: const PlzArea('10115'),
      );
      expect((r as FuelServiceFailure).reason, FuelFailure.unavailable);
      expect(hits, 0);
    });

    test('HTTP error is a provider failure', () async {
      status = 500;
      final r = await service().fetch(FuelGrade.e5);
      expect((r as FuelServiceFailure).reason, FuelFailure.provider);
    });

    test('malformed file is a provider failure', () async {
      body = 'not a spreadsheet'.codeUnits;
      final r = await service().fetch(FuelGrade.e5);
      expect((r as FuelServiceFailure).reason, FuelFailure.provider);
    });

    test('oversized download is a provider failure', () async {
      body = Uint8List(5100000);
      final r = await service().fetch(FuelGrade.e5);
      expect((r as FuelServiceFailure).reason, FuelFailure.provider);
    });

    test('timeout is offline', () async {
      delay = const Duration(milliseconds: 600);
      final r = await service(
        timeout: const Duration(milliseconds: 100),
      ).fetch(FuelGrade.e5);
      expect((r as FuelServiceFailure).reason, FuelFailure.offline);
    });

    test('connection refused is offline', () async {
      final port = server.port;
      await server.close(force: true);
      final r = await service(
        uri: Uri.parse('http://127.0.0.1:$port/b.xlsx'),
      ).fetch(FuelGrade.e5);
      expect((r as FuelServiceFailure).reason, FuelFailure.offline);
    });

    test('plain http to a remote host is refused, nothing is sent', () async {
      final r = await service(
        uri: Uri.parse('http://example.com/b.xlsx'),
      ).fetch(FuelGrade.e5);
      expect((r as FuelServiceFailure).reason, FuelFailure.unavailable);
    });

    test('cache file: no refetch within 12 h, refetch after', () async {
      final cache = File('${tmp.path}/q.json');
      await service(cache: cache).fetch(FuelGrade.e5);
      expect(hits, 1);
      expect(cache.existsSync(), isTrue);

      clock.advance(const Duration(hours: 11));
      // A fresh service instance (app restart) reads the file.
      final again =
          await service(cache: cache).fetch(FuelGrade.diesel) as FuelServiceOk;
      expect(again.price.priceMilli, 2253);
      expect(hits, 1);

      clock.advance(const Duration(hours: 2));
      await service(cache: cache).fetch(FuelGrade.e5);
      expect(hits, 2);
    });

    test('offline with an old cache: last file is served', () async {
      final cache = File('${tmp.path}/q.json');
      await service(cache: cache).fetch(FuelGrade.e5);
      clock.advance(const Duration(days: 3));
      status = 503;
      final r =
          await service(cache: cache).fetch(FuelGrade.e5) as FuelServiceOk;
      expect(r.price.priceMilli, 2067);
      expect(r.price.fetchedAt, DateTime.utc(2026, 11, 9));
    });

    test('corrupt cache file is ignored', () async {
      final cache = File('${tmp.path}/q.json')..writeAsStringSync('{nope');
      final r = await service(cache: cache).fetch(FuelGrade.e5);
      expect(r, isA<FuelServiceOk>());
      expect(hits, 1);
    });

    test('unwritable cache location does not break the answer', () async {
      final blocker = File('${tmp.path}/file')..writeAsStringSync('x');
      final r = await service(
        cache: File('${blocker.path}/sub/q.json'),
      ).fetch(FuelGrade.e5);
      expect(r, isA<FuelServiceOk>());
    });
  });
}
