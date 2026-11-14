import 'dart:convert';
import 'dart:io';

import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../helpers/fake_app.dart';
import '../repo_test_support.dart' show ok;

final _block = RegExp(
  r'<!--\s*examples:(\w+)\s*-->\s*```json\s*\n(.*?)\n\s*```',
  dotAll: true,
);

/// The rows of `<!-- examples:name -->` in `docs/domain-rules.md` (found by
/// walking up from the package dir), the single source of golden data.
List<Map<String, dynamic>> domainRulesRows(String name) {
  var dir = Directory.current.absolute;
  while (!File('${dir.path}/docs/domain-rules.md').existsSync()) {
    if (dir.parent.path == dir.path) throw StateError('domain-rules.md');
    dir = dir.parent;
  }
  final text = File('${dir.path}/docs/domain-rules.md').readAsStringSync();
  for (final m in _block.allMatches(text)) {
    if (m.group(1) == name) {
      return (jsonDecode(m.group(2)!) as List).cast<Map<String, dynamic>>();
    }
  }
  throw StateError('examples:$name not found');
}

/// A group with named members created through the fake repositories, so
/// scenarios never touch another slice's UI.
class Scenario {
  Scenario._(this.app, this.group, this.ids);

  final FakeApp app;
  final Group group;

  /// Doc label (`A`) or name to the generated member id.
  final Map<String, String> ids;

  static Future<Scenario> create(
    FakeApp app,
    List<String> labels, {
    Currency currency = Currency.eur,
  }) async {
    final group = ok(
      await app.groups.create(
        name: 'Trip',
        currency: currency,
        createdBy: 'dev',
      ),
    );
    final ids = <String, String>{};
    for (final label in labels) {
      ids[label] = ok(await app.members.add(group.id, name: label)).id;
    }
    return Scenario._(app, group, ids);
  }

  String label(String id) => ids.entries.firstWhere((e) => e.value == id).key;

  /// An expense with exact shares; the amount is their sum.
  Future<ExpenseEntry> expense(
    Map<String, int> payers,
    Map<String, int> shares, {
    DateTime? date,
  }) async => ok(
    await app.expenses.create(
      group.id,
      ExpenseDraft(
        title: 'Ausgabe',
        amountCents: shares.values.fold(0, (a, b) => a + b),
        currency: group.currency,
        date: date ?? DateTime.utc(2026, 2),
        payers: {for (final e in payers.entries) ids[e.key]!: e.value},
        split: ExactSplit({
          for (final e in shares.entries) ids[e.key]!: e.value,
        }),
      ),
    ),
  );

  Future<SettlementEntry> settle(String from, String to, int cents) async => ok(
    await app.settlements.create(
      group.id,
      SettlementDraft(
        fromId: ids[from]!,
        toId: ids[to]!,
        amountCents: cents,
        currency: group.currency,
        date: DateTime.utc(2026, 2, 2),
        method: SettlementMethod.cash,
      ),
    ),
  );

  /// One expense that produces exactly [balances]: creditors pay, debtors
  /// carry the shares. No entry for an all-zero map.
  Future<void> seedBalances(Map<String, int> balances) async {
    final payers = {
      for (final e in balances.entries)
        if (e.value > 0) e.key: e.value,
    };
    final shares = {
      for (final e in balances.entries)
        if (e.value < 0) e.key: -e.value,
    };
    if (payers.isNotEmpty) await expense(payers, shares);
  }
}
