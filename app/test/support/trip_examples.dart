import 'dart:convert';
import 'dart:io';

import 'package:mitlio/features/trips/ui/trip_form_view_model.dart';

/// One row of `<!-- examples:trip -->` in `docs/domain-rules.md` (the single
/// source of golden trip data), translated to what a user would type.
class TripExample {
  TripExample(this.json);

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  Map<String, dynamic> get _in => json['input'] as Map<String, dynamic>;

  int get total => json['total'] as int;

  /// Expected shares by the example's member letters (`A`, `B`, ...).
  Map<String, int> get shares => (json['shares'] as Map).cast<String, int>();

  /// Letters of everybody involved, driver first.
  List<String> get letters => [
    _in['driver'] as String,
    ...(_in['passengers'] as List).cast<String>(),
  ];

  /// The form inputs; [ids] maps the example letters to member ids.
  TripInputs inputs(Map<String, String> ids) {
    final i = _in;
    return TripInputs(
      distance: _decimal((i['distanceMeters'] as int) ~/ 1000, 0),
      roundTrip: i['roundTrip'] as bool,
      useKmRate: i.containsKey('kmRate'),
      consumption: _milli(i['consumption']),
      price: _milli(i['price']),
      wear: _milli(i['wear']),
      kmRate: _milli(i['kmRate']),
      tolls: i.containsKey('tollsCents')
          ? _decimal(
              (i['tollsCents'] as int) ~/ 100,
              (i['tollsCents'] as int) % 100,
            )
          : '',
      driverId: ids[i['driver']],
      passengerIds: {
        for (final p in (i['passengers'] as List).cast<String>()) ids[p]!,
      },
      driverCounts: i['driverCounts'] as bool,
    );
  }

  static String _decimal(int whole, int fraction) => fraction == 0
      ? '$whole'
      : '$whole.${fraction.toString().padLeft(2, '0')}';

  static String _milli(Object? milli) {
    if (milli == null) return '';
    final m = milli as int;
    return '${m ~/ 1000}.${(m % 1000).toString().padLeft(3, '0')}';
  }
}

final _block = RegExp(
  r'<!--\s*examples:trip\s*-->\s*```json\s*\n(.*?)\n\s*```',
  dotAll: true,
);

/// All rows of `examples:trip`, read from `docs/domain-rules.md` found by
/// walking up from the working directory.
List<TripExample> tripExamples() {
  var dir = Directory.current.absolute;
  while (true) {
    final file = File('${dir.path}/docs/domain-rules.md');
    if (file.existsSync()) {
      final match = _block.firstMatch(file.readAsStringSync())!;
      return [
        for (final row in jsonDecode(match.group(1)!) as List)
          TripExample(row as Map<String, dynamic>),
      ];
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('docs/domain-rules.md not found above the cwd.');
    }
    dir = parent;
  }
}
