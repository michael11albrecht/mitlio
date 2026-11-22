import 'dart:convert';
import 'dart:io';

import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:test/test.dart';

/// Fixture gate (P9r-T03): every `tool/fixtures/receipts/*.json` is parsed and
/// compared with its `expected` block. See tool/fixtures/receipts/README.md.
const _dir = 'tool/fixtures/receipts';

Directory _findDir() {
  var dir = Directory.current.absolute;
  while (true) {
    final d = Directory('${dir.path}/$_dir');
    if (d.existsSync()) return d;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('$_dir not found above ${Directory.current.path}');
    }
    dir = parent;
  }
}

ReceiptLine _line(Object? raw) {
  if (raw is String) return ReceiptLine(raw);
  final m = raw! as Map<String, Object?>;
  final b = (m['box'] as List?)?.cast<num>();
  return ReceiptLine(
    m['text']! as String,
    box: b == null
        ? null
        : ReceiptBox(
            left: b[0].toDouble(),
            top: b[1].toDouble(),
            right: b[2].toDouble(),
            bottom: b[3].toDouble(),
          ),
  );
}

String? _isoDate(DateTime? d) => d?.toIso8601String().substring(0, 10);

void main() {
  final files =
      _findDir()
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final totalHits = <bool>[];
  final merchantHits = <bool>[];

  group('receipt fixtures', () {
    test('there are fixtures', () => expect(files, isNotEmpty));

    for (final f in files) {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final name = json['name']! as String;

      test(name, () {
        expect(f.uri.pathSegments.last, '$name.json');
        if (json['synthetic'] == true) {
          expect(name, startsWith('synthetic-'));
        }
        final draft = parseReceipt([
          for (final l in (json['lines']! as List)) _line(l),
        ]);
        final e = json['expected']! as Map<String, Object?>;
        final actual = <String, Object?>{
          'totalCents': draft.totalCents.value,
          'merchant': draft.merchant.value,
          'date': _isoDate(draft.date.value),
          'currency': draft.currency.value?.code,
          'category': draft.category.value?.name,
        };
        if (e.containsKey('totalCents')) {
          totalHits.add(actual['totalCents'] == e['totalCents']);
        }
        if (e.containsKey('merchant')) {
          merchantHits.add(actual['merchant'] == e['merchant']);
        }
        for (final k in e.keys) {
          expect(actual[k], e[k], reason: '$name: $k');
        }
      });
    }

    test('gate: total correct >= 90 %, merchant correct >= 80 %', () {
      expect(totalHits, isNotEmpty);
      final totalRate = totalHits.where((h) => h).length / totalHits.length;
      final merchantRate =
          merchantHits.where((h) => h).length / merchantHits.length;
      expect(totalRate, greaterThanOrEqualTo(0.9));
      expect(merchantRate, greaterThanOrEqualTo(0.8));
    });
  });
}
