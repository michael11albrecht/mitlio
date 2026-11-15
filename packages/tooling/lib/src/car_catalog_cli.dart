import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:mitlio_tooling/src/car_catalog.dart';

/// EEA Discodata tables: final WLTP-era years. 2021 sits in the generic
/// `co2cars` table (versions up to 2022), later years have one table each.
/// 2025 is a provisional release; see docs/car-catalog.md.
const kDiscodataTables = <({String table, int year, String label})>[
  (table: 'co2cars', year: 2021, label: '2021 final (v24)'),
  (table: 'co2cars_2022Fv26', year: 2022, label: '2022 final (v26)'),
  (table: 'co2cars_2023Fv28', year: 2023, label: '2023 final (v28)'),
  (table: 'co2cars_2024Fv30', year: 2024, label: '2024 final (v30)'),
  (table: 'co2cars_2025Pv31', year: 2025, label: '2025 provisional (v31)'),
];

const _endpoint = 'https://discodata.eea.europa.eu/sql';
const _pageLimit = 500000;

/// Downloads distinct variants (make, model, fuel, engine, power, WLTP
/// consumption) per table, one request each. Returns CSV lines (with header)
/// in the EEA column naming so the same reader handles an official CSV.
///
/// The Discodata gateway rejects GROUP BY / ORDER BY, so registration counts
/// cannot be summed server-side: every distinct variant weighs 1 (documented
/// in docs/car-catalog.md).
Future<List<String>> fetchDiscodataCsv({
  required void Function(String) log,
  Uri? endpoint,
  Duration retryDelay = const Duration(seconds: 15),
}) async {
  final http = HttpClient();
  Future<List<Map<String, Object?>>> query(String sql) async {
    final uri = (endpoint ?? Uri.parse(_endpoint)).replace(
      queryParameters: {'query': sql, 'p': '1', 'nrOfHits': '$_pageLimit'},
    );
    for (var attempt = 1; ; attempt++) {
      final request = await http.getUrl(uri);
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, Object?>;
        if (json['errors'] != null) {
          throw StateError('Discodata error for "$sql": ${json['errors']}');
        }
        return (json['results']! as List).cast<Map<String, Object?>>();
      }
      if (attempt >= 4) {
        throw StateError('Discodata HTTP ${response.statusCode} for "$sql"');
      }
      await Future<void>.delayed(retryDelay * attempt);
    }
  }

  final lines = <String>['Mk,Cn,Ft,Fm,Ec (cm3),Ep (KW),Fc,Z (Wh/km),Year,R'];
  String csv(Object? v) {
    final s = v?.toString() ?? '';
    return s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  for (final t in kDiscodataTables) {
    final fq = '[CO2Emission].[latest].[${t.table}]';
    // The generic table holds every year, so it is filtered server-side.
    final where = t.table == 'co2cars' ? ' WHERE Year = ${t.year}' : '';
    final rows = await query(
      'SELECT DISTINCT Mk, Cn, Ft, Fm, [Ec (cm3)], [Ep (KW)], Fc, '
      '[Z (Wh/km)], Year FROM $fq$where',
    );
    if (rows.length >= _pageLimit) {
      throw StateError('${t.table}: result hit the page limit');
    }
    log('${t.label}: ${rows.length} distinct variants');
    for (final r in rows) {
      if (r['Year'] != t.year) continue;
      lines.add(
        [
          r['Mk'],
          r['Cn'],
          r['Ft'],
          r['Fm'],
          r['Ec (cm3)'],
          r['Ep (KW)'],
          r['Fc'],
          r['Z (Wh/km)'],
          r['Year'],
          1,
        ].map(csv).join(','),
      );
    }
  }
  http.close();
  return lines;
}

/// `build_car_catalog`: see docs/car-catalog.md.
Future<int> runBuildCarCatalog(
  List<String> args, {
  required StringSink out,
  required StringSink err,
  Future<List<String>> Function(void Function(String log))? fetch,
}) async {
  final parser = ArgParser()
    ..addMultiOption(
      'input',
      help:
          'EEA-shaped CSV to read instead of downloading (repeatable; header '
          'names Mk,Cn,Ft,Fm,Ec (cm3),Ep (KW),Fc,Z (Wh/km),Year[,R]).',
    )
    ..addOption('output', help: 'Asset to write (.json.gz). Required.')
    ..addOption(
      'save-csv',
      help: 'Also keep the downloaded rows as CSV (not committed).',
    )
    ..addOption('min-year', defaultsTo: '2021')
    ..addOption('min-weight', defaultsTo: '2')
    ..addOption('source', help: 'Source text stored in the asset header.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults r;
  try {
    r = parser.parse(args);
  } on FormatException catch (e) {
    err.writeln('${e.message}\n${parser.usage}');
    return 64;
  }
  if (r.flag('help')) {
    out.writeln(parser.usage);
    return 0;
  }
  final output = r.option('output');
  if (output == null) {
    err.writeln('Missing --output.\n${parser.usage}');
    return 64;
  }

  final builder = CarCatalogBuilder(
    minYear: int.parse(r.option('min-year')!),
    minWeight: int.parse(r.option('min-weight')!),
    source:
        r.option('source') ??
        'EEA, Monitoring of CO2 emissions from passenger cars, '
            'Regulation (EU) 2019/631, WLTP, final data 2021-2024, '
            '2025 provisional',
  );
  final inputs = r.multiOption('input');
  final List<String> lines;
  try {
    if (inputs.isEmpty) {
      lines = await (fetch ?? (log) => fetchDiscodataCsv(log: log))(
        out.writeln,
      );
      final save = r.option('save-csv');
      if (save != null) File(save).writeAsStringSync('${lines.join('\n')}\n');
    } else {
      lines = [for (final path in inputs) ...File(path).readAsLinesSync()];
    }
  } on Object catch (e) {
    err.writeln('Could not read the EEA data: $e');
    return 1;
  }
  try {
    _feed(builder, lines);
  } on FormatException catch (e) {
    err.writeln(e.message);
    return 1;
  }
  final catalog = builder.build();
  final cars = (catalog['cars']! as List).length;
  if (cars == 0) {
    err.writeln(
      'No car survived the filters; refusing to write an empty asset.',
    );
    return 1;
  }
  final bytes = encodeCatalog(catalog);
  File(output)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  out.writeln(
    'rows read ${builder.rowsSeen}, used ${builder.rowsUsed}, '
    'cars $cars, makes ${(catalog['makes']! as List).length}, '
    'years ${catalog['years']}, ${bytes.length} bytes gzipped',
  );
  return 0;
}

/// Feeds CSV [lines]; a new header line (several inputs) re-maps columns.
void _feed(CarCatalogBuilder builder, List<String> lines) {
  EeaCsvReader? reader;
  for (final line in lines) {
    if (line.startsWith('Mk,') || line.startsWith('Mk;')) {
      reader = EeaCsvReader(line, separator: line[2]);
      continue;
    }
    if (reader == null) {
      throw const FormatException('CSV must start with a header line');
    }
    final row = reader.parse(line);
    if (row != null) builder.add(row);
  }
}
