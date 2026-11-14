import 'dart:convert';
import 'dart:io';

import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/debug/seed/scenario_seeder.dart';
import 'package:mitlio/features/balances/ui/balances_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart';

/// `app/` is the working directory of `flutter test`.
const scenarioDir = '../tool/fixtures/scenarios';

const scenarioNames = [
  'empty',
  'trip_4p',
  'household_2p',
  'rounding_edge',
  'commute_3p',
  'large_200_expenses',
];

Future<String> readScenario(String name) =>
    File('$scenarioDir/$name.json').readAsString();

ScenarioSeeder seederFor(Repos r) => ScenarioSeeder(
  source: readScenario,
  groups: r.groups,
  members: r.members,
  expenses: r.expenses,
  vehicles: r.vehicles,
  templates: r.rideTemplates,
  rides: r.rides,
  ids: SequentialIdGenerator(prefix: 'ride'),
);

/// Balances (by member name) and simplified transfers of a seeded scenario,
/// in the JSON shape of the `expected` block.
///
/// Scenarios with rides are settled per month first: the rides of October
/// 2026 become one expense per driver (`aggregateRides`).
Future<Map<String, Object?>> computeExpected(
  Repos r,
  Map<String, Object?> seeded,
) async {
  final groupId = seeded['groupId']! as String;
  final byName = seeded['members']! as Map<String, String>;
  final nameOf = {for (final e in byName.entries) e.value: e.key};
  final group = ok(await r.groups.get(groupId));
  final members = [
    for (final m in ok(await r.members.list(groupId))) m.toDomain(),
  ];
  final expenses = [
    for (final e in await r.expenses.watchExpenses(groupId).first) e.expense,
  ];
  final rideEntries = await r.rides
      .watchRides(groupId, const Month(2026, 10))
      .first;
  if (rideEntries.isNotEmpty) {
    final vehicles = {
      for (final v in await r.vehicles.watchVehicles(groupId).first) v.id: v,
    };
    final aggregates = switch (aggregateRides(
      rides: [for (final e in rideEntries) e.ride],
      vehicles: vehicles,
      currency: group.currency,
      members: members,
      period: const Month(2026, 10),
    )) {
      Ok<List<RideAggregate>, TripError>(:final value) => value,
      Err<List<RideAggregate>, TripError>(:final error) => throw StateError(
        '$error',
      ),
    };
    for (final a in aggregates) {
      final expense = rideAggregateToExpense(
        id: 'ride-expense-${a.driverId}',
        title: 'Oktober',
        date: DateTime.utc(2026, 10, 31),
        aggregate: a,
        currency: group.currency,
        members: members,
      );
      expenses.add((expense as Ok<Expense, ExpenseError>).value);
    }
  }
  final result = computeBalancesResult(
    members: members,
    expenses: expenses,
    settlements: const [],
  );
  return {
    'balances': {
      for (final m in members) nameOf[m.id]!: result.balances[m.id],
    },
    'transfers': [
      for (final t in result.simplified)
        {
          'from': nameOf[t.fromId],
          'to': nameOf[t.toId],
          'amountCents': t.amountCents,
        },
    ],
  };
}

/// The `expected` block committed in the scenario file.
Future<Map<String, Object?>> committedExpected(String name) async =>
    (jsonDecode(await readScenario(name)) as Map<String, dynamic>)['expected']
        as Map<String, Object?>;
