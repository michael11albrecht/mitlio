import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_data_control.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart';
import 'seed_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every scenario file is registered with seed and vice versa', () {
    expect(fileScenarios, scenarioNames);
    expect(seedScenarios, containsAll(scenarioNames));
  });

  group('loading through the repositories matches the committed values', () {
    for (final name in scenarioNames) {
      for (final drift in [true, false]) {
        test('$name (${drift ? 'drift' : 'fake'})', () async {
          final r = drift ? await driftRepos() : await fakeRepos();
          final seeded = await seederFor(r).load(name);
          final expected = await committedExpected(name);
          // Compare as JSON: key order and number types are irrelevant.
          expect(
            jsonDecode(jsonEncode(await computeExpected(r, seeded))),
            jsonDecode(jsonEncode(expected)),
          );
        });
      }
    }
  });

  group('scenario contents', () {
    late Repos r;
    setUp(() async => r = await driftRepos());

    Future<Map<String, Object?>> load(String name) => seederFor(r).load(name);

    test('empty has a group and no members or expenses', () async {
      final seeded = await load('empty');
      expect(seeded['ids'], hasLength(1));
      final groupId = seeded['groupId']! as String;
      expect(await r.expenses.watchExpenses(groupId).first, isEmpty);
    });

    test('trip_4p has 4 members, 3 trips and 5 regular expenses', () async {
      final seeded = await load('trip_4p');
      final groupId = seeded['groupId']! as String;
      final entries = await r.expenses.watchExpenses(groupId).first;
      expect(seeded['ids'], hasLength(1 + 4 + 8));
      expect(entries.where((e) => e.tripMeta != null), hasLength(3));
      expect(entries.where((e) => e.tripMeta == null), hasLength(5));
    });

    test('household_2p spans 30 days with shares and percent', () async {
      final seeded = await load('household_2p');
      final entries = await r.expenses
          .watchExpenses(seeded['groupId']! as String)
          .first;
      expect(entries, hasLength(30));
      expect(
        {for (final e in entries) e.split.runtimeType.toString()},
        containsAll(['SharesSplit', 'PercentSplit', 'EqualSplit']),
      );
    });

    test('commute_3p has a vehicle, a template and 20 rides', () async {
      final seeded = await load('commute_3p');
      final groupId = seeded['groupId']! as String;
      expect(await r.vehicles.watchVehicles(groupId).first, hasLength(1));
      expect(await r.rideTemplates.watchTemplates(groupId).first, hasLength(1));
      final rides = await r.rides
          .watchRides(groupId, const Month(2026, 10))
          .first;
      expect(rides, hasLength(20));
    });

    test('large_200_expenses is deterministic', () async {
      final first = await load('large_200_expenses');
      final other = await driftRepos();
      final again = await seederFor(other).load('large_200_expenses');
      expect(first['ids'], hasLength(1 + 8 + 200));
      expect(
        await computeExpected(other, again),
        await computeExpected(r, first),
      );
    });
  });

  group('bundled assets (what the app seeds from)', () {
    test('the asset of every scenario equals the committed file', () async {
      for (final name in scenarioNames) {
        expect(
          await rootBundle.loadString('assets/scenarios/$name.json'),
          await readScenario(name),
        );
      }
    });
  });

  group('ext.mitlio.seed handler', () {
    for (final name in scenarioNames) {
      test('seeds $name and returns the created ids', () async {
        final r = await driftRepos();
        final seeder = seederFor(r);
        final control = DriftDebugDataControl(
          db: r.db!,
          groups: r.groups,
          members: r.members,
          seeder: seeder,
        );
        final result = await control.seed(name);
        expect(result['error'], isNull);
        final ids = result['ids']! as List<Object?>;
        expect(ids.first, result['groupId']);
        expect(ids.toSet(), hasLength(ids.length));
        expect(ok(await r.groups.get(ids.first! as String)).name, isNotEmpty);
      });
    }

    test('seed then reset leaves an empty database', () async {
      final r = await driftRepos();
      final control = DriftDebugDataControl(
        db: r.db!,
        groups: r.groups,
        members: r.members,
        seeder: seederFor(r),
      );
      await control.seed('commute_3p');
      await control.wipe();
      expect(await r.groups.watchGroups().first, isEmpty);
      // A second seed after the wipe works (ids are not reused).
      expect((await control.seed('trip_4p'))['error'], isNull);
    });

    test('an unknown scenario is invalid_params and lists the known', () async {
      final r = await driftRepos();
      final control = DriftDebugDataControl(
        db: r.db!,
        groups: r.groups,
        members: r.members,
        seeder: seederFor(r),
      );
      final result = await control.seed('nope');
      expect(result['error'], 'invalid_params');
      expect(result['message'], contains('large_200_expenses'));
    });
  });
}
