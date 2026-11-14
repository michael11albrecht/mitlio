import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/debug/handlers/balances.dart';
import 'package:mitlio/debug/handlers/rides.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';

import '../features/repo_test_support.dart';
import 'seed_support.dart';

/// Same flow as the desktop integration test: seed `commute_3p`, settle
/// October through `ext.mitlio.rides.settle`, then the balances equal the
/// values committed in the scenario file.
void main() {
  for (final drift in [true, false]) {
    test(
      'commute_3p settled in October (${drift ? 'drift' : 'fake'})',
      () async {
        final r = drift ? await driftRepos() : await fakeRepos();
        final seeded = await seederFor(r).load('commute_3p');
        final groupId = seeded['groupId']! as String;
        final container = ProviderContainer(
          overrides: [
            clockProvider.overrideWithValue(r.clock),
            idGeneratorProvider.overrideWithValue(
              SequentialIdGenerator(prefix: 'set'),
            ),
            groupsRepositoryProvider.overrideWithValue(r.groups),
            membersRepositoryProvider.overrideWithValue(r.members),
            expensesRepositoryProvider.overrideWithValue(r.expenses),
            settlementsRepositoryProvider.overrideWithValue(r.settlements),
            vehiclesRepositoryProvider.overrideWithValue(r.vehicles),
            rideTemplatesRepositoryProvider.overrideWithValue(r.rideTemplates),
            ridesRepositoryProvider.overrideWithValue(r.rides),
          ],
        );
        addTearDown(container.dispose);
        final drive = {
          ...ridesDriveHandlers(container),
          ...balancesDriveHandlers(container),
        };

        final settled = await drive['rides.settle']!({
          'groupId': groupId,
          'month': '2026-10',
        });
        expect(settled['error'], isNull);
        expect(settled['rideCount'], 20);
        expect(settled['expenseIds'], hasLength(3));

        final nameOf = {
          for (final e in (seeded['members']! as Map<String, String>).entries)
            e.value: e.key,
        };
        final expected = await committedExpected('commute_3p');
        final got = await drive['balances.get']!({'groupId': groupId});
        expect(
          {
            for (final e in (got['balances']! as Map<String, Object?>).entries)
              nameOf[e.key]!: e.value,
          },
          expected['balances'],
        );
        expect(
          jsonDecode(
            jsonEncode([
              for (final t
                  in (got['transfers']! as List<Object?>)
                      .cast<Map<String, Object?>>())
                {
                  'from': nameOf[t['from']],
                  'to': nameOf[t['to']],
                  'amountCents': t['amount'],
                },
            ]),
          ),
          jsonDecode(jsonEncode(expected['transfers'])),
        );
      },
    );
  }
}
