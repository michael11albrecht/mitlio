import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/expenses/data/repositories/drift_expenses_repository.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/groups/data/repositories/drift_groups_repository.dart';
import 'package:mitlio/features/groups/data/repositories/fake_groups_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/members/data/repositories/drift_members_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/drift_settlements_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'repo_test_support.dart';

void main() {
  test('providers default to Drift implementations on the app database', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026))),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(groupsRepositoryProvider), isA<DriftGroupsRepository>());
    expect(c.read(membersRepositoryProvider), isA<DriftMembersRepository>());
    expect(c.read(expensesRepositoryProvider), isA<DriftExpensesRepository>());
    expect(
      c.read(settlementsRepositoryProvider),
      isA<DriftSettlementsRepository>(),
    );
  });

  test('a provider can be overridden with a fake', () async {
    final fake = FakeGroupsRepository(
      clock: FixedClock(DateTime.utc(2026)),
      ids: SequentialIdGenerator(),
    );
    final c = ProviderContainer(
      overrides: [groupsRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(c.dispose);
    final repo = c.read(groupsRepositoryProvider);
    expect(repo, same(fake));
    ok(await repo.create(name: 'A', currency: Currency.eur, createdBy: 'd'));
  });
}
