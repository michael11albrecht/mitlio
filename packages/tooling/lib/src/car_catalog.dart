/// Pure logic of `build_car_catalog`: turns EEA "Monitoring of CO2 emissions
/// from passenger cars" rows (Regulation (EU) 2019/631) into the compact car
/// catalog asset shipped with the app (P9-T09, issue #131).
///
/// No I/O here: the bin script downloads or reads the data, this library
/// parses, filters, aggregates and encodes it, so it is unit-testable.
library;

import 'dart:convert';
import 'dart:io' show GZipCodec;

/// Fuel codes stored in the asset. Kept in sync with the app's
/// `CarFuel` (app/lib/features/rides/data/car_catalog.dart).
abstract final class CatalogFuel {
  static const petrol = 0;
  static const diesel = 1;
  static const electric = 2;
  static const petrolHybrid = 3;
  static const dieselHybrid = 4;
}

/// One input row, already typed. [registrations] is the weight (EEA row
/// `R`, 1 per registration in the full download; 1 when the input is a
/// DISTINCT export of variants).
class EeaRow {
  const EeaRow({
    required this.make,
    required this.model,
    required this.fuel,
    required this.mode,
    required this.year,
    this.engineCc,
    this.powerKw,
    this.fuelLPer100,
    this.whPerKm,
    this.registrations = 1,
  });

  final String make;
  final String model;

  /// EEA `Ft`, e.g. "petrol", "diesel", "petrol/electric", "electric".
  final String fuel;

  /// EEA `Fm`: M mono-fuel, H hybrid, P plug-in hybrid, B bi-fuel, F flex.
  final String mode;
  final int year;
  final int? engineCc;
  final int? powerKw;
  final double? fuelLPer100;
  final double? whPerKm;
  final int registrations;
}

/// Canonical make -> raw EEA spellings (upper case, see [normalizeKey]).
/// Anything not listed is dropped on purpose: the EEA data also holds
/// motorhome converters, one-off builds and typos ("3ERCEDES-BENZ").
const Map<String, List<String>> kMakeAliases = {
  'Abarth': ['ABARTH', 'FIAT ABARTH'],
  'Alfa Romeo': ['ALFA ROMEO', 'ALFA-ROMEO'],
  'Alpine': ['ALPINE'],
  'Aston Martin': ['ASTON MARTIN'],
  'Audi': ['AUDI', 'AUDI AG'],
  'Bentley': ['BENTLEY'],
  'BMW': ['BMW', 'BMW AG', 'BMW I', 'BMW M'],
  'BYD': ['BYD'],
  'Chevrolet': ['CHEVROLET'],
  'Citroën': ['CITROEN', 'CITROENDS'],
  'Cupra': ['CUPRA'],
  'Dacia': ['DACIA'],
  'DS': ['DS', 'DS AUTOMOBILES'],
  'Ferrari': ['FERRARI'],
  'Fiat': ['FIAT', 'FIAT GROUP AUTOMOBILES SPA'],
  'Ford': ['FORD', 'FORD (D)', 'FORD WERKE GMBH'],
  'Genesis': ['GENESIS', 'HYUNDAI GENESIS'],
  'Honda': ['HONDA'],
  'Hyundai': ['HYUNDAI', 'HYUNDAI MOTOR (ROK)'],
  'Ineos': ['INEOS', 'INEOS GRENADIER'],
  'Jaguar': ['JAGUAR'],
  'Jeep': ['JEEP'],
  'Kia': ['KIA', 'KIA MOTOR', 'KIA MOTORS'],
  'Lada': ['LADA'],
  'Lamborghini': ['LAMBORGHINI', 'AUTOMOBILI LAMBORGHINI'],
  'Land Rover': ['LAND ROVER'],
  'Leapmotor': ['LEAPMOTOR'],
  'Lexus': ['LEXUS'],
  'Lotus': ['LOTUS'],
  'Lynk & Co': ['LYNK & CO', 'LYNK&CO'],
  'Maserati': ['MASERATI'],
  'Mazda': ['MAZDA'],
  'McLaren': ['MCLAREN', 'MC LAREN'],
  'Mercedes-Benz': [
    'MERCEDES-BENZ',
    'MERCEDES BENZ',
    'MERCEDES',
    'MERCEDES-AMG',
    'MERCEDES AMG',
    'MERCEDES-BENZ AG',
  ],
  'MG': ['MG', 'MG ROEWE', 'MGROEWE'],
  'Mini': ['MINI'],
  'Mitsubishi': ['MITSUBISHI', 'MITSUBISHI MOTORS CORPORATION'],
  'Nio': ['NIO'],
  'Nissan': ['NISSAN'],
  'Opel': ['OPEL', 'OPELVAUXHALL', 'OPEL/VAUXHALL', 'VAUXHALL'],
  'Peugeot': ['PEUGEOT'],
  'Polestar': ['POLESTAR'],
  'Porsche': ['PORSCHE'],
  'Renault': ['RENAULT', 'RENAULT SAS'],
  'Rolls-Royce': ['ROLLS-ROYCE', 'ROLLS ROYCE'],
  'Seat': ['SEAT'],
  'Skoda': ['SKODA'],
  'Smart': ['SMART'],
  'SsangYong': ['SSANGYONG', 'KG MOBILITY', 'KGM'],
  'Subaru': ['SUBARU'],
  'Suzuki': ['SUZUKI'],
  'Tesla': ['TESLA', 'TESLA MOTORS'],
  'Toyota': ['TOYOTA'],
  'Volvo': ['VOLVO'],
  'VW': ['VOLKSWAGEN', 'VW', 'VOLKSWAGEN AG', 'VOLKSWAGEN VW'],
  'Xpeng': ['XPENG'],
};

final Map<String, String> _aliasToCanonical = {
  for (final e in kMakeAliases.entries)
    for (final a in e.value) a: e.key,
};

/// Upper case, diacritics of the Nordic/Czech spellings folded, spaces
/// collapsed. Used for aliases and model grouping.
String normalizeKey(String raw) {
  const fold = {
    'Š': 'S',
    'Č': 'C',
    'Ž': 'Z',
    'Ë': 'E',
    'É': 'E',
    'È': 'E',
    'Ê': 'E',
    'Ö': 'O',
    'Ø': 'O',
    'Ó': 'O',
    'Ä': 'A',
    'Å': 'A',
    'Á': 'A',
    'À': 'A',
    'Â': 'A',
    'Ü': 'U',
    'Ú': 'U',
    'Í': 'I',
    'Ç': 'C',
    'Ñ': 'N',
  };
  final buffer = StringBuffer();
  for (final rune in raw.toUpperCase().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(fold[ch] ?? ch);
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Canonical make for a raw EEA spelling, or null when it is not a make we
/// ship (see [kMakeAliases]).
String? canonicalMake(String raw) => _aliasToCanonical[normalizeKey(raw)];

/// Reduces an EEA commercial name to the model: "Golf / 1.5 / Tsi Aut." and
/// "GOLF 1.5 TSI" -> "Golf", "ID.3 Pro 150 Kw" -> "ID.3 Pro", quotes and
/// repeated words ("Giulia Giulia Quadrifoglio") removed. Title case, but
/// words with digits and short words keep reading naturally ("ID.3", "A4").
String displayModel(String raw, {String? make}) {
  var text = normalizeKey(raw)
      .replaceAll('"', ' ')
      .replaceAll(' !', '!')
      // "2,0" is an engine size; any other comma separates words.
      .replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}')
      .replaceAll(',', ' ');
  if (make != null) {
    // "Toyota Corolla" -> "Corolla", "VOLKSWAGEN GOLF" -> "Golf".
    for (final alias in [normalizeKey(make), ...?kMakeAliases[make]]) {
      if (text.startsWith('$alias ')) {
        text = text.substring(alias.length + 1);
        break;
      }
    }
  }
  final slash = text.indexOf('/');
  if (slash >= 0) text = text.substring(0, slash);
  final words = text.split(' ').where((w) => w.isNotEmpty).toList();
  final kept = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final next = i + 1 < words.length ? words[i + 1] : '';
    if (i > 0) {
      // Engine size ("1.5", "2,0"), power ("150 KW", "250KW") and plain
      // trailing numbers followed by a unit end the model name.
      if (RegExp(r'^\d[.,]\d$').hasMatch(w)) break;
      if (RegExp(r'^\d{2,3}K?W$').hasMatch(w)) break;
      if (RegExp(r'^\d{2,3}$').hasMatch(w) && (next == 'KW' || next == 'PS')) {
        break;
      }
      if (w == kept.last) continue;
    }
    kept.add(w);
  }
  return kept
      .map((w) {
        if (RegExp(r'\d').hasMatch(w) || w.length <= 2) return w;
        return w[0] + w.substring(1).toLowerCase();
      })
      .join(' ');
}

/// The catalogue fuel code for one row, or null when the row is not shipped
/// (plug-in hybrids: WLTP values are far too optimistic, other fuels: tiny).
int? catalogFuel(EeaRow row) {
  final fuel = row.fuel.trim().toLowerCase();
  final mode = row.mode.trim().toUpperCase();
  if (mode == 'P') return null;
  return switch (fuel) {
    'petrol' => CatalogFuel.petrol,
    'diesel' => CatalogFuel.diesel,
    'electric' => CatalogFuel.electric,
    'petrol/electric' => CatalogFuel.petrolHybrid,
    'diesel/electric' => CatalogFuel.dieselHybrid,
    _ => null,
  };
}

/// Splits one CSV line (RFC 4180 quoting, `,` or `;` separated).
List<String> splitCsvLine(String line, {String separator = ','}) {
  final out = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == separator) {
      out.add(cell.toString());
      cell.clear();
    } else {
      cell.write(c);
    }
  }
  out.add(cell.toString());
  return out;
}

/// Reads EEA-shaped CSV: header names `Mk, Cn, Ft, Fm, Ec (cm3), Ep (KW),
/// Fc, Z (Wh/km), Year` and optionally `R` (registrations). Rows without a
/// make, model, fuel or year are skipped and counted in [skipped].
class EeaCsvReader {
  EeaCsvReader(String headerLine, {this.separator = ','})
    : _index = _indexHeader(splitCsvLine(headerLine, separator: separator)) {
    for (final required in const ['Mk', 'Cn', 'Ft', 'Year']) {
      if (!_index.containsKey(required)) {
        throw FormatException('CSV header lacks column "$required"');
      }
    }
  }

  final String separator;
  final Map<String, int> _index;
  int skipped = 0;

  static Map<String, int> _indexHeader(List<String> cells) => {
    for (var i = 0; i < cells.length; i++) cells[i].trim(): i,
  };

  EeaRow? parse(String line) {
    if (line.trim().isEmpty) return null;
    final cells = splitCsvLine(line, separator: separator);
    String cell(String name) {
      final i = _index[name];
      return i == null || i >= cells.length ? '' : cells[i].trim();
    }

    final year = int.tryParse(cell('Year'));
    final make = cell('Mk');
    final model = cell('Cn');
    final fuel = cell('Ft');
    if (year == null || make.isEmpty || model.isEmpty || fuel.isEmpty) {
      skipped++;
      return null;
    }
    return EeaRow(
      make: make,
      model: model,
      fuel: fuel,
      mode: cell('Fm'),
      year: year,
      engineCc: int.tryParse(cell('Ec (cm3)')),
      powerKw: int.tryParse(cell('Ep (KW)')),
      fuelLPer100: double.tryParse(cell('Fc')),
      whPerKm: double.tryParse(cell('Z (Wh/km)')),
      registrations: int.tryParse(cell('R')) ?? 1,
    );
  }
}

class _Group {
  _Group(this.make, this.model, this.fuel, this.engineClass, this.powerClass);

  final String make;
  final String model;
  final int fuel;

  /// Engine capacity in 100 cm3 steps (15 = 1.5 l); 0 for electric.
  final int engineClass;

  /// Power in 5 kW steps (20 = 100 kW); 0 when unknown.
  final int powerClass;
  int weight = 0;
  final samples = <({double value, int weight})>[];
  final years = <int>{};
}

/// Aggregates rows to (make, model, fuel, engine class, power class) and
/// encodes the asset.
class CarCatalogBuilder {
  CarCatalogBuilder({
    this.minYear = 2021,
    this.minWeight = 2,
    this.source = '',
  });

  /// Pre-WLTP (NEDC) years are not shipped; the EEA table only carries WLTP
  /// consumption from 2020/2021 on.
  final int minYear;

  /// Groups with less summed weight than this are dropped (typos, one-offs).
  final int minWeight;

  /// Free text for the asset header (dataset, versions, retrieval date).
  final String source;

  final _groups = <String, _Group>{};
  int rowsSeen = 0;
  int rowsUsed = 0;

  void add(EeaRow row) {
    rowsSeen++;
    if (row.year < minYear) return;
    final make = canonicalMake(row.make);
    final fuel = catalogFuel(row);
    if (make == null || fuel == null) return;
    final model = displayModel(row.model, make: make);
    // "Model" alone is a Tesla name cut at its slash ("MODEL / 3 / ...").
    if (model.isEmpty || model.length > 24 || model == 'Model') return;
    final electric = fuel == CatalogFuel.electric;
    final value = electric ? row.whPerKm : row.fuelLPer100;
    if (value == null || value <= 0) return;
    // Plausibility: 2-25 l/100 km, 8-40 kWh/100 km (Wh/km 80-400).
    if (electric ? (value < 80 || value > 400) : (value < 2 || value > 25)) {
      return;
    }
    final cc = electric ? 0 : ((row.engineCc ?? 0) / 100).round();
    if (!electric && cc == 0) return;
    final kw = row.powerKw == null ? 0 : (row.powerKw! / 5).round();
    final key = '$make|$model|$fuel|$cc|$kw';
    final group = _groups.putIfAbsent(
      key,
      () => _Group(make, model, fuel, cc, kw),
    );
    final weight = row.registrations < 1 ? 1 : row.registrations;
    group.weight += weight;
    group.samples.add((value: value, weight: weight));
    group.years.add(row.year);
    rowsUsed++;
  }

  /// Weighted median consumption of a group in hundredths of l or kWh per
  /// 100 km. The median keeps single mis-reported rows (a 32 kWh/100 km
  /// ID.3) from moving the value.
  static int _hundredths(_Group g) {
    final sorted = [...g.samples]..sort((a, b) => a.value.compareTo(b.value));
    var cumulative = 0;
    var median = sorted.last.value;
    for (final s in sorted) {
      cumulative += s.weight;
      if (cumulative * 2 >= g.weight) {
        median = s.value;
        break;
      }
    }
    // Electric: Wh/km -> kWh/100 km is x0.1, so hundredths = Wh/km x 10.
    return (g.fuel == CatalogFuel.electric ? median * 10 : median * 100)
        .round();
  }

  /// The asset as JSON-able map. `cars` rows are
  /// `[makeIndex, model, fuel, engineClass, powerClass, hundredths]`, sorted.
  Map<String, Object?> build() {
    final kept = _groups.values.where((g) => g.weight >= minWeight).toList()
      ..sort((a, b) {
        final byMake = a.make.compareTo(b.make);
        if (byMake != 0) return byMake;
        final byModel = a.model.compareTo(b.model);
        if (byModel != 0) return byModel;
        final byFuel = a.fuel.compareTo(b.fuel);
        if (byFuel != 0) return byFuel;
        final byEngine = a.engineClass.compareTo(b.engineClass);
        if (byEngine != 0) return byEngine;
        return a.powerClass.compareTo(b.powerClass);
      });
    final makes = <String>[];
    final cars = <List<Object?>>[];
    var firstYear = 9999;
    var lastYear = 0;
    for (final g in kept) {
      var index = makes.indexOf(g.make);
      if (index < 0) {
        makes.add(g.make);
        index = makes.length - 1;
      }
      for (final y in g.years) {
        if (y < firstYear) firstYear = y;
        if (y > lastYear) lastYear = y;
      }
      cars.add([
        index,
        g.model,
        g.fuel,
        g.engineClass,
        g.powerClass,
        _hundredths(g),
      ]);
    }
    return {
      'v': 1,
      'source': source,
      'licence': 'CC BY 4.0, European Environment Agency (EEA)',
      'years': [if (cars.isNotEmpty) firstYear, if (cars.isNotEmpty) lastYear],
      'makes': makes,
      'cars': cars,
    };
  }
}

/// Compact JSON bytes, gzip level 9.
List<int> encodeCatalog(Map<String, Object?> catalog) =>
    GZipCodec(level: 9).encode(utf8.encode(jsonEncode(catalog)));
