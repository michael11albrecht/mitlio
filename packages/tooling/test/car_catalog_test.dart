import 'dart:convert';
import 'dart:io';

import 'package:mitlio_tooling/mitlio_tooling.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _fixture = 'test/fixtures/eea_sample.csv';

EeaRow row({
  String make = 'VOLKSWAGEN',
  String model = 'GOLF',
  String fuel = 'petrol',
  String mode = 'M',
  int year = 2023,
  int? cc = 1498,
  int? kw = 96,
  double? fc = 5.6,
  double? wh,
  int registrations = 1,
}) => EeaRow(
  make: make,
  model: model,
  fuel: fuel,
  mode: mode,
  year: year,
  engineCc: cc,
  powerKw: kw,
  fuelLPer100: fc,
  whPerKm: wh,
  registrations: registrations,
);

List<String> fixtureLines() => File(_fixture).readAsLinesSync();

CarCatalogBuilder buildFixture({int minWeight = 2, int minYear = 2021}) {
  final builder = CarCatalogBuilder(minWeight: minWeight, minYear: minYear);
  final lines = fixtureLines();
  final reader = EeaCsvReader(lines.first);
  for (final line in lines.skip(1)) {
    final r = reader.parse(line);
    if (r != null) builder.add(r);
  }
  return builder;
}

void main() {
  group('names', () {
    test('canonicalMake folds spellings and drops everything else', () {
      expect(canonicalMake('VOLKSWAGEN'), 'VW');
      expect(canonicalMake(' volkswagen  ag '), 'VW');
      expect(canonicalMake('MERCEDES BENZ'), 'Mercedes-Benz');
      expect(canonicalMake('Škoda'), 'Skoda');
      expect(canonicalMake('SKODA'), 'Skoda');
      expect(canonicalMake('CITROEN'), 'Citroën');
      expect(canonicalMake('KNAUS'), isNull);
      expect(canonicalMake('3ERCEDES-BENZ'), isNull);
      expect(canonicalMake(''), isNull);
    });

    test('normalizeKey', () {
      expect(normalizeKey('  Škoda   Fabia '), 'SKODA FABIA');
      expect(normalizeKey('Citroën'), 'CITROEN');
    });

    test('displayModel cuts engines, power, quotes and repeats', () {
      expect(displayModel('GOLF'), 'Golf');
      expect(displayModel('GOLF / 1.5 / TSI'), 'Golf');
      expect(displayModel('GOLF 1.5 TSI'), 'Golf');
      expect(displayModel('Golf 2,0 TDI'), 'Golf');
      expect(displayModel('"ID.3 PRO 150 KW"'), 'ID.3 Pro');
      expect(displayModel('ID.4 GTX 250KW'), 'ID.4 Gtx');
      expect(displayModel('ID.7 PRO 210 PS'), 'ID.7 Pro');
      expect(displayModel('GIULIA GIULIA QUADRIFOGLIO'), 'Giulia Quadrifoglio');
      expect(displayModel('A 180, LONG'), 'A 180 Long');
      expect(displayModel('UP !'), 'Up!');
      expect(displayModel('500'), '500');
      expect(displayModel('C3'), 'C3');
      expect(displayModel('DS 3'), 'DS 3');
      expect(displayModel('  '), '');
    });

    test('displayModel drops the make in front of the model', () {
      expect(displayModel('TOYOTA COROLLA', make: 'Toyota'), 'Corolla');
      expect(displayModel('VOLKSWAGEN GOLF', make: 'VW'), 'Golf');
      expect(displayModel('VW GOLF', make: 'VW'), 'Golf');
      expect(displayModel('TOYOTA', make: 'Toyota'), 'Toyota');
      expect(displayModel('GOLF', make: 'VW'), 'Golf');
    });

    test('catalogFuel keeps petrol, diesel, hybrids and electric', () {
      int? fuel(String ft, [String fm = 'M']) =>
          catalogFuel(row(fuel: ft, mode: fm));
      expect(fuel('petrol'), CatalogFuel.petrol);
      expect(fuel('Diesel'), CatalogFuel.diesel);
      expect(fuel('electric', 'B'), CatalogFuel.electric);
      expect(fuel('petrol/electric', 'H'), CatalogFuel.petrolHybrid);
      expect(fuel('diesel/electric', 'H'), CatalogFuel.dieselHybrid);
      expect(fuel('petrol/electric', 'P'), isNull);
      expect(fuel('diesel/electric', 'p'), isNull);
      expect(fuel('lpg'), isNull);
      expect(fuel('e85'), isNull);
      expect(fuel('hydrogen'), isNull);
    });
  });

  group('CSV', () {
    test('splitCsvLine handles quotes, escaped quotes and separators', () {
      expect(splitCsvLine('a,b,c'), ['a', 'b', 'c']);
      expect(splitCsvLine('a,"b,c",d'), ['a', 'b,c', 'd']);
      expect(splitCsvLine('"say ""hi""",x'), ['say "hi"', 'x']);
      expect(splitCsvLine('a,,c,'), ['a', '', 'c', '']);
      expect(splitCsvLine('a;"b;c"', separator: ';'), ['a', 'b;c']);
    });

    test('the reader needs the key columns', () {
      expect(() => EeaCsvReader('Mk,Cn,Ft'), throwsFormatException);
      expect(() => EeaCsvReader('Cn,Ft,Year'), throwsFormatException);
    });

    test('the reader types a row, with and without registrations', () {
      final reader = EeaCsvReader(
        'Mk,Cn,Ft,Fm,Ec (cm3),Ep (KW),Fc,Z (Wh/km),Year,R',
      );
      final r = reader.parse('VW,GOLF,petrol,M,1498,96,5.6,,2023,12')!;
      expect(r.make, 'VW');
      expect(r.engineCc, 1498);
      expect(r.powerKw, 96);
      expect(r.fuelLPer100, 5.6);
      expect(r.whPerKm, isNull);
      expect(r.registrations, 12);

      final minimal = EeaCsvReader('Mk;Cn;Ft;Year', separator: ';');
      final m = minimal.parse('VW;GOLF;petrol;2023')!;
      expect(m.registrations, 1);
      expect(m.fuelLPer100, isNull);
      expect(m.mode, '');
    });

    test('the reader skips and counts incomplete rows', () {
      final reader = EeaCsvReader('Mk,Cn,Ft,Year');
      expect(reader.parse(''), isNull);
      expect(reader.parse('  '), isNull);
      expect(reader.parse('VW,GOLF,petrol,'), isNull);
      expect(reader.parse(',GOLF,petrol,2023'), isNull);
      expect(reader.parse('VW,,petrol,2023'), isNull);
      expect(reader.parse('VW,GOLF,,2023'), isNull);
      expect(reader.parse('VW,GOLF'), isNull);
      expect(reader.skipped, 5);
    });
  });

  group('CarCatalogBuilder on the sample file', () {
    late CarCatalogBuilder builder;
    late Map<String, Object?> catalog;
    setUp(() {
      builder = buildFixture();
      catalog = builder.build();
    });

    List<List<Object?>> cars() => (catalog['cars']! as List).cast();
    List<String> makes() => (catalog['makes']! as List).cast();

    test('keeps the shipped makes, models and variants, sorted', () {
      expect(makes(), ['Citroën', 'Mercedes-Benz', 'Tesla', 'Toyota', 'VW']);
      expect(cars().map((c) => '${makes()[c[0]! as int]} ${c[1]}').toList(), [
        'Citroën C3',
        'Mercedes-Benz A 180 Long',
        'Tesla Model 3',
        'Toyota Corolla',
        'VW Golf',
        'VW Golf',
        'VW Golf',
        'VW ID.3 Pro',
      ]);
    });

    test('rows are [make, model, fuel, engine, power, hundredths]', () {
      // Citroën C3: petrol, 1.2 l (12), 61 kW -> 12 x 5 kW, 5,4 l.
      expect(cars().first, [0, 'C3', CatalogFuel.petrol, 12, 12, 540]);
      // Tesla Model 3: electric has no engine; 145 Wh/km = 14,5 kWh.
      expect(cars()[2], [2, 'Model 3', CatalogFuel.electric, 0, 42, 1450]);
    });

    test('uses the registration-weighted median, not the mean', () {
      // Golf petrol: 5,6 (10), 5,8 (30), 9,9 (1), 5,7 (5) -> 5,8.
      final golf = cars().where((c) => c[1] == 'Golf').toList();
      expect(golf[0], [4, 'Golf', CatalogFuel.petrol, 15, 19, 580]);
      // 4,4 (8) and 4,6 (8): the lower middle.
      expect(golf[1], [4, 'Golf', CatalogFuel.diesel, 20, 22, 440]);
      expect(golf[2], [4, 'Golf', CatalogFuel.petrolHybrid, 15, 22, 520]);
    });

    test('a single mis-reported electric row does not move the value', () {
      // 154 (4), 158 (4), 321 (1) Wh/km -> 158.
      expect(cars().last, [4, 'ID.3 Pro', CatalogFuel.electric, 0, 30, 1580]);
    });

    test('drops plug-ins, other fuels, other makes and old years', () {
      final names = cars().map((c) => c[1]).toSet();
      expect(names, isNot(contains('Boxstar 600')));
      expect(names, isNot(contains('Fiesta')));
      expect(names, isNot(contains('Focus')));
      // Plug-in Golf (1,2 l) is not there.
      expect(cars().where((c) => c[5] == 120), isEmpty);
    });

    test('drops groups lighter than the minimum weight', () {
      expect(cars().map((c) => c[1]), isNot(contains('Puma')));
      final lenient = buildFixture(minWeight: 1).build();
      expect(
        (lenient['cars']! as List).map((c) => (c as List)[1]),
        contains('Puma'),
      );
    });

    test('minYear moves the WLTP boundary', () {
      final recent = buildFixture(minYear: 2024).build();
      expect(recent['years'], [2024, 2024]);
      final all = buildFixture(minYear: 2019).build();
      expect(
        (all['cars']! as List).map((c) => (c as List)[1]),
        contains('Fiesta'),
      );
    });

    test('header names source, licence and the years covered', () {
      expect(catalog['v'], 1);
      expect(catalog['licence'], contains('CC BY 4.0'));
      expect(catalog['years'], [2022, 2024]);
      expect(builder.rowsUsed, greaterThan(0));
      expect(builder.rowsSeen, greaterThan(builder.rowsUsed));
    });

    test('plausibility limits drop impossible values', () {
      final b = CarCatalogBuilder(minWeight: 1)
        ..add(row(fc: 1.9))
        ..add(row(model: 'B', fc: 25.5))
        ..add(row(model: 'C', fc: 2))
        ..add(row(model: 'D', fuel: 'electric', mode: 'B', fc: null, wh: 79))
        ..add(row(model: 'E', fuel: 'electric', mode: 'B', fc: null, wh: 401))
        ..add(row(model: 'F', fuel: 'electric', mode: 'B', fc: null, wh: 80))
        ..add(row(model: 'G', fuel: 'electric', mode: 'B', fc: null, wh: 400))
        ..add(row(model: 'X' * 30));
      final names = (b.build()['cars']! as List).map((c) => (c as List)[1]);
      expect(names, ['C', 'F', 'G']);
    });

    test('a group with no cars builds an empty catalog without years', () {
      final empty = CarCatalogBuilder().build();
      expect(empty['cars'], isEmpty);
      expect(empty['years'], isEmpty);
    });
  });

  group('encoding', () {
    test('is gzip JSON and reproducible byte for byte', () {
      final a = encodeCatalog(buildFixture().build());
      final b = encodeCatalog(buildFixture().build());
      expect(a, b);
      final json = jsonDecode(utf8.decode(gzip.decode(a))) as Map;
      expect(json['v'], 1);
      expect(json['cars'] as List, hasLength(8));
    });
  });

  group('build_car_catalog CLI', () {
    late Directory dir;
    late StringBuffer out;
    late StringBuffer err;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('car_catalog_test');
      out = StringBuffer();
      err = StringBuffer();
    });
    tearDown(() => dir.deleteSync(recursive: true));

    String target() => p.join(dir.path, 'out', 'catalog.json.gz');

    Future<int> run(
      List<String> args, {
      Future<List<String>> Function(void Function(String))? fetch,
    }) => runBuildCarCatalog(args, out: out, err: err, fetch: fetch);

    test('builds the asset from a CSV and reports the numbers', () async {
      final code = await run(['--input', _fixture, '--output', target()]);
      expect(code, 0, reason: '$err');
      expect(File(target()).existsSync(), isTrue);
      expect('$out', contains('cars 8'));
      expect('$out', contains('makes 5'));
      expect('$out', contains('years [2022, 2024]'));
      final json = jsonDecode(
        utf8.decode(gzip.decode(File(target()).readAsBytesSync())),
      ) as Map;
      expect(json['source'], contains('EEA'));
    });

    test('--source, --min-year and --min-weight are honoured', () async {
      final code = await run([
        '--input',
        _fixture,
        '--output',
        target(),
        '--source',
        'my source',
        '--min-year',
        '2024',
        '--min-weight',
        '1',
      ]);
      expect(code, 0, reason: '$err');
      final json = jsonDecode(
        utf8.decode(gzip.decode(File(target()).readAsBytesSync())),
      ) as Map;
      expect(json['source'], 'my source');
      expect(json['years'], [2024, 2024]);
    });

    test('several inputs are concatenated', () async {
      final second = p.join(dir.path, 'more.csv');
      File(second).writeAsStringSync(
        'Mk,Cn,Ft,Fm,Ec (cm3),Ep (KW),Fc,Z (Wh/km),Year,R\n'
        'SKODA,OCTAVIA,petrol,M,999,81,5.1,,2023,5\n',
      );
      final code = await run([
        '--input',
        _fixture,
        '--input',
        second,
        '--output',
        target(),
      ]);
      expect(code, 0, reason: '$err');
      expect('$out', contains('cars 9'));
    });

    test('without --input it downloads, and can keep the rows', () async {
      final saved = p.join(dir.path, 'rows.csv');
      final lines = fixtureLines();
      final logs = <String>[];
      final code = await run(
        ['--output', target(), '--save-csv', saved],
        fetch: (log) async {
          log('fetching');
          logs.add('called');
          return lines;
        },
      );
      expect(code, 0, reason: '$err');
      expect(logs, ['called']);
      expect('$out', contains('fetching'));
      expect(File(saved).readAsLinesSync(), lines);
    });

    test('a download that fails exits 1 and says why', () async {
      final code = await run(
        ['--output', target()],
        fetch: (_) async => throw StateError('gateway said no'),
      );
      expect(code, 1);
      expect('$err', contains('Could not read the EEA data'));
      expect('$err', contains('gateway said no'));
      expect(File(target()).existsSync(), isFalse);
    });

    test('a missing input file exits 1', () async {
      final code = await run([
        '--input',
        p.join(dir.path, 'nope.csv'),
        '--output',
        target(),
      ]);
      expect(code, 1);
      expect('$err', contains('Could not read the EEA data'));
    });

    test('a CSV without header or key columns exits 1', () async {
      final noHeader = p.join(dir.path, 'a.csv')
        ..let((f) => File(f).writeAsStringSync('VW,GOLF,petrol,2023\n'));
      expect(await run(['--input', noHeader, '--output', target()]), 1);
      expect('$err', contains('header'));
    });

    test('a CSV with a header lacking columns exits 1', () async {
      final bad = p.join(dir.path, 'b.csv')
        ..let((f) => File(f).writeAsStringSync('Mk,Cn,Ft\nVW,GOLF,petrol\n'));
      expect(await run(['--input', bad, '--output', target()]), 1);
      expect('$err', contains('Year'));
    });

    test('nothing surviving the filters refuses to write', () async {
      final none = p.join(dir.path, 'c.csv')
        ..let(
          (f) => File(f).writeAsStringSync(
            'Mk,Cn,Ft,Year\nKNAUS,BOXSTAR,diesel,2023\n',
          ),
        );
      expect(await run(['--input', none, '--output', target()]), 1);
      expect('$err', contains('empty asset'));
      expect(File(target()).existsSync(), isFalse);
    });

    test('bad arguments print the usage', () async {
      expect(await run(['--input', _fixture]), 64);
      expect(await run(['--bogus']), 64);
      expect('$err', contains('--output'));
    });

    test('--help prints the usage', () async {
      expect(await run(['--help']), 0);
      expect('$out', contains('--input'));
    });
  });

  group('fetchDiscodataCsv', () {
    late HttpServer server;
    late List<String> queries;
    late int failures;
    var errorReply = false;

    setUp(() async {
      queries = [];
      failures = 0;
      errorReply = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((request) async {
          final sql = request.uri.queryParameters['query']!;
          queries.add(sql);
          final year = RegExp(r'co2cars_(\d{4})').firstMatch(sql)?.group(1);
          request.response.headers.contentType = ContentType.json;
          if (failures > 0) {
            failures--;
            request.response.statusCode = 403;
            request.response.write('<html>403</html>');
          } else if (errorReply) {
            request.response.write(
              jsonEncode({
                'errors': ['nope'],
              }),
            );
          } else {
            final y = int.parse(year ?? '2021');
            request.response.write(
              jsonEncode({
                'results': [
                  {
                    'Mk': 'VOLKSWAGEN',
                    'Cn': 'GOLF, "VARIANT"',
                    'Ft': 'petrol',
                    'Fm': 'M',
                    'Ec (cm3)': 1498,
                    'Ep (KW)': 96,
                    'Fc': 5.6,
                    'Z (Wh/km)': null,
                    'Year': y,
                  },
                  {
                    // The generic table answers other years too.
                    'Mk': 'VOLKSWAGEN',
                    'Cn': 'POLO',
                    'Ft': 'petrol',
                    'Fm': 'M',
                    'Ec (cm3)': 999,
                    'Ep (KW)': 70,
                    'Fc': 5.0,
                    'Z (Wh/km)': null,
                    'Year': 2015,
                  },
                ],
              }),
            );
          }
          await request.response.close();
        });
    });
    tearDown(() => server.close(force: true));

    Uri endpoint() => Uri.parse('http://127.0.0.1:${server.port}/sql');

    test('one query per table, filtered to the table year', () async {
      final logs = <String>[];
      final lines = await fetchDiscodataCsv(
        log: logs.add,
        endpoint: endpoint(),
        retryDelay: Duration.zero,
      );
      expect(queries, hasLength(kDiscodataTables.length));
      expect(queries.first, contains('WHERE Year = 2021'));
      expect(queries[1], isNot(contains('WHERE')));
      expect(
        queries.every((q) => q.startsWith('SELECT DISTINCT Mk, Cn')),
        isTrue,
      );
      expect(logs, hasLength(kDiscodataTables.length));
      expect(lines.first, startsWith('Mk,Cn,Ft,Fm'));
      // Header + one row per table; the 2015 row is filtered out.
      expect(lines, hasLength(1 + kDiscodataTables.length));
      expect(
        lines[1],
        'VOLKSWAGEN,"GOLF, ""VARIANT""",petrol,M,1498,96,5.6,,2021,1',
      );
      // The output reads back through the same CSV reader.
      final reader = EeaCsvReader(lines.first);
      expect(reader.parse(lines[1])!.model, 'GOLF, "VARIANT"');
    });

    test('an SQL error from the endpoint is reported', () async {
      errorReply = true;
      await expectLater(
        fetchDiscodataCsv(
          log: (_) {},
          endpoint: endpoint(),
          retryDelay: Duration.zero,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a 403 is retried, a persistent one is reported', () async {
      failures = 2;
      final lines = await fetchDiscodataCsv(
        log: (_) {},
        endpoint: endpoint(),
        retryDelay: Duration.zero,
      );
      expect(lines.length, greaterThan(1));
      failures = 100;
      await expectLater(
        fetchDiscodataCsv(
          log: (_) {},
          endpoint: endpoint(),
          retryDelay: Duration.zero,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

extension on String {
  /// Runs [f] with this string and returns it (for compact fixtures).
  String let(void Function(String) f) {
    f(this);
    return this;
  }
}
