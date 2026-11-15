// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/rides/vehicle.dart';

/// Real-world consumption is higher than the WLTP value on the type-approval
/// sheet. The EU Commission (SWD(2024) 59) puts the 2021 gap at 23.7 % for
/// new petrol and 18.1 % for diesel cars; an ICCT summary (2025) gives about
/// 20 % for combustion and hybrid cars. One flat, rounded estimate for both.
/// Always shown as an estimate, never as an official value.
const int realWorldGapPercent = 20;

/// The everyday consumption estimate for a manufacturer (WLTP) value, in
/// thousandths, rounded half up; `null` for electric cars and other fuels
/// where no sourced factor exists. See docs/domain-rules.md, "Car catalog".
int? realisticConsumptionMilli(FuelType fuel, int wltpMilli) {
  if (fuel != FuelType.petrol && fuel != FuelType.diesel) return null;
  if (wltpMilli <= 0) {
    throw ArgumentError.value(wltpMilli, 'wltpMilli', 'must be > 0');
  }
  return (wltpMilli * (100 + realWorldGapPercent) + 50) ~/ 100;
}

/// One catalog car: a (make, model, fuel, engine, power) variant with its
/// manufacturer (WLTP) consumption.
final class CarCatalogEntry {
  const CarCatalogEntry({
    required this.make,
    required this.model,
    required this.fuelType,
    required this.consumptionMilliPer100km,
    this.hybrid = false,
    this.engineCc = 0,
    this.powerKw = 0,
  });

  final String make;
  final String model;

  /// Petrol or diesel (also for hybrids) or electric.
  final FuelType fuelType;

  /// Petrol/diesel mild or full hybrid (plug-in hybrids are not catalogued).
  final bool hybrid;

  /// Rounded to 100 cm3; 0 for electric.
  final int engineCc;

  /// Rounded to 5 kW; 0 when unknown.
  final int powerKw;

  /// Litres or kWh per 100 km times 1000 (WLTP, manufacturer value).
  final int consumptionMilliPer100km;

  /// What the vehicle is called after picking this entry.
  String get name => '$make $model';

  @override
  bool operator ==(Object other) =>
      other is CarCatalogEntry &&
      other.make == make &&
      other.model == model &&
      other.fuelType == fuelType &&
      other.hybrid == hybrid &&
      other.engineCc == engineCc &&
      other.powerKw == powerKw &&
      other.consumptionMilliPer100km == consumptionMilliPer100km;

  @override
  int get hashCode => Object.hash(
    make,
    model,
    fuelType,
    hybrid,
    engineCc,
    powerKw,
    consumptionMilliPer100km,
  );

  @override
  String toString() => 'CarCatalogEntry($name, $fuelType, $engineCc cm3)';
}

/// Alternative spellings people type for a make.
const Map<String, List<String>> _makeAliases = {
  'VW': ['volkswagen'],
  'Mercedes-Benz': ['mercedes', 'benz'],
};

const Map<String, String> _fold = {
  'ä': 'a',
  'ö': 'o',
  'ü': 'u',
  'ß': 'ss',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'í': 'i',
  'ó': 'o',
  'ô': 'o',
  'ú': 'u',
  'š': 's',
  'č': 'c',
  'ž': 'z',
  'ç': 'c',
  'ñ': 'n',
  'ø': 'o',
  'å': 'a',
};

final RegExp _alnum = RegExp('[a-z0-9]');
final RegExp _spaces = RegExp(r'\s+');

/// Folds case, umlauts and accents and turns punctuation into spaces:
/// "Citroën C3" -> "citroen c3", "ID.3" -> "id 3".
String foldCatalogText(String raw) {
  final out = StringBuffer();
  for (final rune in raw.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final mapped = _fold[ch];
    if (mapped != null) {
      out.write(mapped);
    } else if (_alnum.hasMatch(ch)) {
      out.write(ch);
    } else {
      out.write(' ');
    }
  }
  return out.toString().trim().replaceAll(_spaces, ' ');
}

String _compact(String s) => foldCatalogText(s).replaceAll(' ', '');

class _Indexed {
  _Indexed(this.entry)
    : tokens = [
        ...foldCatalogText(entry.make).split(' '),
        ...foldCatalogText(entry.model).split(' '),
        for (final a in _makeAliases[entry.make] ?? const <String>[])
          ...foldCatalogText(a).split(' '),
      ],
      compactModel = _compact(entry.model),
      compactNames = [
        _compact('${entry.make}${entry.model}'),
        for (final a in _makeAliases[entry.make] ?? const <String>[])
          _compact('$a${entry.model}'),
      ];

  final CarCatalogEntry entry;
  final List<String> tokens;
  final String compactModel;
  final List<String> compactNames;

  bool _starts(String q) =>
      tokens.any((t) => t.startsWith(q)) ||
      compactModel.startsWith(q) ||
      compactNames.any((n) => n.startsWith(q));

  bool matches(List<String> queryTokens) => queryTokens.every(_starts);

  /// 0 when the whole query reads as the start of the model or of
  /// "make model" ("golf", "vw golf", "model3"), 1 for looser token hits.
  int tier(String compactQuery) =>
      compactModel.startsWith(compactQuery) ||
          compactNames.any((n) => n.startsWith(compactQuery))
      ? 0
      : 1;
}

/// The bundled car list with prefix search. Pure and synchronous: the app
/// loads and decodes the asset, this class only searches.
class CarCatalog {
  CarCatalog(Iterable<CarCatalogEntry> entries)
    : _all = [for (final e in entries) _Indexed(e)];

  final List<_Indexed> _all;

  int get length => _all.length;

  /// Up to [limit] entries whose make or model starts with every word of
  /// [query] (at least [minLength] characters). Best matches first, and the
  /// list prefers different fuels and models over several variants of one.
  List<CarCatalogEntry> search(
    String query, {
    int limit = 5,
    int minLength = 2,
  }) {
    final folded = foldCatalogText(query);
    final compactQuery = folded.replaceAll(' ', '');
    if (compactQuery.length < minLength || limit < 1) return const [];
    final tokens = folded.split(' ');
    final hits = _all.where((i) => i.matches(tokens)).toList()
      ..sort((a, b) => _compare(a, b, compactQuery));
    final picked = <CarCatalogEntry>[];
    final seen = <String>{};
    for (final h in hits) {
      if (picked.length == limit) break;
      if (seen.add('${h.entry.name}|${_fuelRank(h.entry)}')) {
        picked.add(h.entry);
      }
    }
    for (final h in hits) {
      if (picked.length == limit) break;
      if (!picked.contains(h.entry)) picked.add(h.entry);
    }
    return picked;
  }

  static int _compare(_Indexed a, _Indexed b, String compactQuery) {
    final byTier = a.tier(compactQuery).compareTo(b.tier(compactQuery));
    if (byTier != 0) return byTier;
    final byLength = a.compactModel.length.compareTo(b.compactModel.length);
    if (byLength != 0) return byLength;
    final byName = a.entry.name.compareTo(b.entry.name);
    if (byName != 0) return byName;
    final byFuel = _fuelRank(a.entry).compareTo(_fuelRank(b.entry));
    if (byFuel != 0) return byFuel;
    final byEngine = a.entry.engineCc.compareTo(b.entry.engineCc);
    if (byEngine != 0) return byEngine;
    return a.entry.powerKw.compareTo(b.entry.powerKw);
  }

  static int _fuelRank(CarCatalogEntry e) => switch (e.fuelType) {
    FuelType.petrol => e.hybrid ? 1 : 0,
    FuelType.diesel => e.hybrid ? 3 : 2,
    FuelType.electric => 4,
    FuelType.other => 5,
  };
}
