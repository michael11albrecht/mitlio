import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/expenses/data/repositories/drift_expenses_repository.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/data/repositories/fake_expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/drift_groups_repository.dart';
import 'package:mitlio/features/groups/data/repositories/fake_groups_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/drift_members_repository.dart';
import 'package:mitlio/features/members/data/repositories/fake_members_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/drift_ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/drift_rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/drift_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/drift_settlements_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/fake_settlements_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// All repositories wired to one store (Drift or in-memory).
class Repos {
  Repos({
    required this.groups,
    required this.members,
    required this.expenses,
    required this.settlements,
    required this.vehicles,
    required this.rideTemplates,
    required this.rides,
    required this.clock,
    this.db,
  });

  final GroupsRepository groups;
  final MembersRepository members;
  final ExpensesRepository expenses;
  final SettlementsRepository settlements;
  final VehiclesRepository vehicles;
  final RideTemplatesRepository rideTemplates;
  final RidesRepository rides;
  final FixedClock clock;

  /// Only set for the Drift variant.
  final AppDatabase? db;
}

FixedClock _clock() => FixedClock(DateTime.utc(2026, 3, 1, 12));

Future<Repos> driftRepos() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final clock = _clock();
  final ids = SequentialIdGenerator();
  return Repos(
    groups: DriftGroupsRepository(db: db, clock: clock, ids: ids),
    members: DriftMembersRepository(db: db, clock: clock, ids: ids),
    expenses: DriftExpensesRepository(db: db, clock: clock, ids: ids),
    settlements: DriftSettlementsRepository(db: db, clock: clock, ids: ids),
    vehicles: DriftVehiclesRepository(db: db, clock: clock, ids: ids),
    rideTemplates: DriftRideTemplatesRepository(
      db: db,
      clock: clock,
      ids: ids,
    ),
    rides: DriftRidesRepository(db: db, clock: clock),
    clock: clock,
    db: db,
  );
}

Future<Repos> fakeRepos() async {
  final clock = _clock();
  final ids = SequentialIdGenerator();
  final groups = FakeGroupsRepository(clock: clock, ids: ids);
  final members = FakeMembersRepository(groups: groups, ids: ids);
  final expenses = FakeExpensesRepository(
    groups: groups,
    members: members,
    clock: clock,
    ids: ids,
  );
  final vehicles = FakeVehiclesRepository(groups: groups, ids: ids);
  return Repos(
    groups: groups,
    members: members,
    expenses: expenses,
    settlements: FakeSettlementsRepository(
      groups: groups,
      members: members,
      clock: clock,
      ids: ids,
    ),
    vehicles: vehicles,
    rideTemplates: FakeRideTemplatesRepository(
      groups: groups,
      members: members,
      vehicles: vehicles,
      ids: ids,
    ),
    rides: FakeRidesRepository(
      groups: groups,
      members: members,
      vehicles: vehicles,
      expenses: expenses,
      clock: clock,
    ),
    clock: clock,
  );
}

/// Unwraps an `Ok` or fails the test.
T ok<T>(RepoResult<T> r) => switch (r) {
  Ok<T, RepositoryError>(:final value) => value,
  Err<T, RepositoryError>(:final error) => fail('expected Ok, got $error'),
};

/// Unwraps an `Err` or fails the test.
RepositoryError err<T>(RepoResult<T> r) => switch (r) {
  Ok<T, RepositoryError>(:final value) => fail('expected Err, got Ok($value)'),
  Err<T, RepositoryError>(:final error) => error,
};

/// Collects stream events so tests can await them one by one, identically for
/// synchronous (fake) and asynchronous (Drift) sources.
class StreamProbe<T> {
  StreamProbe(Stream<T> stream) {
    final sub = stream.listen(_events.add, onError: _errors.add);
    addTearDown(sub.cancel);
  }

  final _events = <T>[];
  final _errors = <Object>[];
  var _taken = 0;
  var _takenErrors = 0;

  Future<T> next() async {
    for (var i = 0; i < 500 && _taken >= _events.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    if (_taken >= _events.length) fail('no further stream event');
    return _events[_taken++];
  }

  Future<Object> nextError() async {
    for (var i = 0; i < 500 && _takenErrors >= _errors.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    if (_takenErrors >= _errors.length) fail('no stream error');
    return _errors[_takenErrors++];
  }
}

const Currency eur = Currency.eur;

/// Creates group `g` (EUR) with members Ann, Ben, Cy; returns them.
Future<({String groupId, List<GroupMember> members})> seedGroup(
  Repos r,
) async {
  final g = ok(
    await r.groups.create(name: 'Trip', currency: eur, createdBy: 'dev'),
  );
  final members = [
    for (final n in ['Ann', 'Ben', 'Cy'])
      ok(await r.members.add(g.id, name: n)),
  ];
  return (groupId: g.id, members: members);
}
