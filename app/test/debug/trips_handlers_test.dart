import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/trips.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart' show ok;
import '../helpers/fake_app.dart';
import '../support/trip_examples.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;
  late Group group;
  late List<GroupMember> people;

  Map<String, String> params([Map<String, String> extra = const {}]) => {
    'groupId': group.id,
    'driverId': people[0].id,
    'passengerIds': '["${people[1].id}","${people[2].id}"]',
    'distance': '250',
    'consumption': '6,5',
    'price': '1.799',
    ...extra,
  };

  setUp(() async {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
    h = tripsDriveHandlers(container);
    group = ok(
      await app.groups.create(
        name: 'Pendeln',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Anna', 'Ben', 'Chiara'])
        ok(await app.members.add(group.id, name: n)),
    ];
  });

  test('trips.add stores the trip and returns the expense', () async {
    final r = await h['trips.add']!(params());
    expect(r['totalCents'], 2923);
    expect(r['shares'], {
      people[0].id: 975,
      people[1].id: 974,
      people[2].id: 974,
    });
    final entries = await app.expenses.watchExpenses(group.id).first;
    expect(entries.single.expense.id, r['id']);
    expect(entries.single.tripMeta, isNotNull);
  });

  test('every examples:trip row gives the documented shares', () async {
    final ids = {for (var i = 0; i < 3; i++) 'ABC'[i]: people[i].id};
    for (final ex in tripExamples()) {
      final inputs = ex.inputs(ids).toJson();
      final r = await h['trips.add']!({
        'groupId': group.id,
        'driverId': inputs['driverId']! as String,
        'passengerIds': jsonEncode(inputs['passengerIds']),
        'distance': inputs['distance']! as String,
        'roundTrip': '${inputs['roundTrip']}',
        'driverCounts': '${inputs['driverCounts']}',
        if (inputs['useKmRate']! as bool) ...{
          'kmRate': inputs['kmRate']! as String,
        } else ...{
          'consumption': inputs['consumption']! as String,
          'price': inputs['price']! as String,
          if ((inputs['wear']! as String).isNotEmpty)
            'wear': inputs['wear']! as String,
        },
        'tolls': inputs['tolls']! as String,
      });
      expect(r['totalCents'], ex.total, reason: ex.name);
      expect(r['shares'], {
        for (final e in ids.entries) e.value: ex.shares[e.key] ?? 0,
      }, reason: ex.name);
    }
  });

  test('trips.add takes a km rate, flags and a title', () async {
    final r = await h['trips.add']!({
      'groupId': group.id,
      'driverId': people[0].id,
      'distance': '250',
      'kmRate': '0.30',
      'driverCounts': 'false',
      'passengerIds': '["${people[1].id}","${people[2].id}"]',
      'title': 'Büro',
      'energy': 'electric',
      'roundTrip': 'false',
    });
    expect(r['totalCents'], 7500);
    final e = (await app.expenses.watchExpenses(group.id).first).single;
    expect(e.expense.title, 'Büro');
    expect(e.tripMeta, contains('"energy":"electric"'));
  });

  test('trips.add validates params', () async {
    for (final bad in [
      <String, String>{},
      {...params()..remove('groupId')},
      {...params()..remove('driverId')},
      params({'passengerIds': 'not json'}),
      params({'passengerIds': '[1]'}),
      params({'roundTrip': 'yes'}),
      params({'driverCounts': '1'}),
    ]) {
      expect((await h['trips.add']!(bad))['error'], 'invalid_params');
    }
    expect(await app.expenses.watchExpenses(group.id).first, isEmpty);
  });

  test('trips.add reports numbers that give no result', () async {
    final r = await h['trips.add']!(params({'distance': 'abc'}));
    expect(r['error'], 'invalid_params');
  });

  test('trips.add maps repository errors', () async {
    expect(
      (await h['trips.add']!(params({'groupId': 'nope'})))['error'],
      'not_found',
    );
  });
}
