import 'dart:convert';

import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio/features/trips/data/trip_meta.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Reads the JSON text of scenario `name`
/// (`tool/fixtures/scenarios/<name>.json`).
typedef ScenarioSource = Future<String> Function(String name);

typedef _Json = Map<String, dynamic>;

/// Loads a scenario file into the local database through the repositories
/// (never raw SQL). File format: `tool/fixtures/README.md`.
class ScenarioSeeder {
  ScenarioSeeder({
    required this.source,
    required this.groups,
    required this.members,
    required this.expenses,
    required this.vehicles,
    required this.templates,
    required this.rides,
    required this.ids,
  });

  final ScenarioSource source;
  final GroupsRepository groups;
  final MembersRepository members;
  final ExpensesRepository expenses;
  final VehiclesRepository vehicles;
  final RideTemplatesRepository templates;
  final RidesRepository rides;
  final IdGenerator ids;

  /// Creates everything the scenario describes. Returns `ids` (group, members
  /// in position order, vehicles, templates, expenses, rides), `groupId` and
  /// `members` (name to id).
  Future<DriveResult> load(String name) async {
    final spec = jsonDecode(await source(name)) as _Json;
    final currency = Currency.tryParse(spec['currency'] as String? ?? 'EUR')!;
    final group = (await groups.create(
      name: spec['group'] as String,
      currency: currency,
      createdBy: 'debug',
    )).orThrow();
    final created = <String>[group.id];
    final byName = <String, String>{};
    for (final n in (spec['members'] as List<dynamic>).cast<String>()) {
      final m = (await members.add(group.id, name: n)).orThrow();
      byName[n] = m.id;
      created.add(m.id);
    }
    String member(Object? n) => byName[n]!;
    Set<String> memberSet(Object? l) => {
      for (final n in (l as List<dynamic>? ?? const <dynamic>[])) member(n),
    };

    final vehicleIds = <String, String>{};
    for (final v in _list(spec, 'vehicles')) {
      final vehicle = (await vehicles.add(
        group.id,
        name: v['name'] as String,
        fuelType: FuelType.values.byName(v['fuelType'] as String),
        consumptionMilliPer100km: v['consumptionMilliPer100km'] as int,
        wearMilliPerKm: v['wearMilliPerKm'] as int? ?? 0,
        kmRateMilliPerKm: v['kmRateMilliPerKm'] as int?,
      )).orThrow();
      vehicleIds[v['name'] as String] = vehicle.id;
      created.add(vehicle.id);
    }
    final templateSpecs = <String, _Json>{};
    for (final t in _list(spec, 'templates')) {
      final template = (await templates.add(
        group.id,
        RideTemplate(
          id: 'new',
          name: t['name'] as String,
          distanceMeters: t['distanceMeters'] as int,
          vehicleId: vehicleIds[t['vehicle']]!,
          roundTrip: t['roundTrip'] as bool? ?? false,
          defaultDriverId: t['driver'] == null ? null : member(t['driver']),
          defaultPassengerIds: memberSet(t['passengers']),
          tollsCents: t['tollsCents'] as int? ?? 0,
        ),
      )).orThrow();
      templateSpecs[t['name'] as String] = t;
      created.add(template.id);
    }

    final domainMembers = [
      for (final (i, id) in byName.values.indexed) Member(id: id, position: i),
    ];
    final drafts = [
      for (final e in _list(spec, 'expenses')) _expense(e, member, currency),
      for (final t in _list(spec, 'trips'))
        _trip(t, member, memberSet, currency, domainMembers),
      ..._generated(spec['generate'], byName.values.toList(), currency),
    ];
    for (final d in drafts) {
      created.add((await expenses.create(group.id, d)).orThrow().expense.id);
    }

    for (final r in _list(spec, 'rides')) {
      final t = templateSpecs[r['template']]!;
      final driver = member(r['driver'] ?? t['driver']);
      final ride = Ride(
        id: ids.newId(),
        date: DateTime.parse(r['date'] as String),
        distanceMeters: t['distanceMeters'] as int,
        roundTrip: t['roundTrip'] as bool? ?? false,
        tollsCents: t['tollsCents'] as int? ?? 0,
        vehicleId: vehicleIds[t['vehicle']]!,
        driverId: driver,
        // The driver is never their own passenger.
        passengerIds: memberSet(r['passengers'] ?? t['passengers'])
          ..remove(driver),
        pricePerUnitMilli: r['pricePerUnitMilli'] as int,
      );
      created.add((await rides.log(group.id, ride)).orThrow().ride.id);
    }
    return {'ids': created, 'groupId': group.id, 'members': byName};
  }

  static List<_Json> _list(_Json m, String key) =>
      (m[key] as List<dynamic>? ?? const <dynamic>[]).cast<_Json>();

  ExpenseDraft _expense(
    _Json e,
    String Function(Object?) member,
    Currency currency,
  ) {
    final s = e['split'] as _Json;
    Map<String, int> weights() => {
      for (final w in (s['weights'] as _Json).entries)
        member(w.key): w.value as int,
    };
    final split = switch (s['mode']) {
      'equal' => EqualSplit({
        for (final n in (s['participants'] as List<dynamic>)) member(n),
      }),
      'shares' => SharesSplit(weights()),
      'percent' => PercentSplit(weights()),
      'exact' => ExactSplit(weights()),
      final other => throw ArgumentError('unknown split mode: $other'),
    };
    return ExpenseDraft(
      title: e['title'] as String,
      amountCents: e['amountCents'] as int,
      currency: currency,
      date: DateTime.parse(e['date'] as String),
      payers: {
        for (final p in (e['payers'] as _Json).entries)
          member(p.key): p.value as int,
      },
      split: split,
      category: e['category'] as String?,
    );
  }

  ExpenseDraft _trip(
    _Json t,
    String Function(Object?) member,
    Set<String> Function(Object?) memberSet,
    Currency currency,
    List<Member> domainMembers,
  ) {
    final mode = t['kmRateMilliPerKm'] != null
        ? KmRate(t['kmRateMilliPerKm'] as int)
        : Consumption(
            consumptionMilliPer100km: t['consumptionMilliPer100km'] as int,
            pricePerUnitMilli: t['pricePerUnitMilli'] as int,
            wearMilliPerKm: t['wearMilliPerKm'] as int? ?? 0,
          );
    final input = TripInput(
      distanceMeters: t['distanceMeters'] as int,
      roundTrip: t['roundTrip'] as bool? ?? false,
      currency: currency,
      mode: mode,
      tollsCents: t['tollsCents'] as int? ?? 0,
      ferryCents: t['ferryCents'] as int? ?? 0,
      driverId: member(t['driver']),
      passengerIds: memberSet(t['passengers']),
      driverCounts: t['driverCounts'] as bool? ?? true,
    );
    final cost = switch (computeTripCost(input, domainMembers)) {
      Ok<TripCost, TripError>(:final value) => value,
      Err<TripCost, TripError>(:final error) => throw ArgumentError(
        'trip ${t['title']}: $error',
      ),
    };
    return ExpenseDraft(
      title: t['title'] as String,
      amountCents: cost.totalCents,
      currency: currency,
      date: DateTime.parse(t['date'] as String),
      payers: {input.driverId: cost.totalCents},
      split: ExactSplit(cost.shares),
      tripMeta: TripMeta(
        distanceMeters: input.distanceMeters,
        roundTrip: input.roundTrip,
        energy: TripEnergy.fuel,
        mode: mode,
        tollsCents: input.tollsCents,
        ferryCents: input.ferryCents,
        driverId: input.driverId,
        passengerIds: input.passengerIds,
        driverCounts: input.driverCounts,
      ).toJson(),
    );
  }

  /// `generate: {seed, count, from, days}`: deterministic pseudo-random
  /// expenses. Uses its own LCG so the output never depends on the platform.
  List<ExpenseDraft> _generated(
    Object? g,
    List<String> memberIds,
    Currency currency,
  ) {
    if (g is! _Json) return const [];
    var state = g['seed'] as int;
    int next(int bound) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return (state >> 8) % bound;
    }

    final from = DateTime.parse(g['from'] as String);
    final days = g['days'] as int;
    return [
      for (var i = 0; i < (g['count'] as int); i++)
        () {
          final amount = 100 + next(19900);
          final start = next(memberIds.length);
          final size = 2 + next(memberIds.length - 1);
          final participants = {
            for (var k = 0; k < size; k++)
              memberIds[(start + k) % memberIds.length],
          };
          return ExpenseDraft(
            title: 'Expense ${i + 1}',
            amountCents: amount,
            currency: currency,
            date: from.add(Duration(days: next(days))),
            payers: {memberIds[next(memberIds.length)]: amount},
            split: switch (next(3)) {
              0 => EqualSplit(participants),
              1 => SharesSplit({for (final p in participants) p: 1 + next(3)}),
              _ => EqualSplit(memberIds.toSet()),
            },
          );
        }(),
    ];
  }
}
