import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/debug/seed/scenario_seeder.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Wipes and seeds local data for DebugDrive (`reset` / `seed`).
abstract interface class DebugDataControl {
  Future<void> wipe();

  /// Returns the ids of the created entities, or an `invalid_params` error
  /// for an unknown scenario.
  Future<DriveResult> seed(String scenario);
}

/// Scenario files (`tool/fixtures/scenarios/<name>.json`, bundled as assets).
const fileScenarios = [
  'empty',
  'trip_4p',
  'household_2p',
  'rounding_edge',
  'commute_3p',
  'large_200_expenses',
];

/// Scenarios `seed` understands.
const List<String> seedScenarios = ['groups', ...fileScenarios];

/// [DebugDataControl] on the real database and repositories.
class DriftDebugDataControl implements DebugDataControl {
  DriftDebugDataControl({
    required this._db,
    required this._groups,
    required this._members,
    this._seeder,
  });

  final AppDatabase _db;
  final GroupsRepository _groups;
  final MembersRepository _members;
  final ScenarioSeeder? _seeder;

  /// Deletes every row. Tables are declared parents first, so deleting in
  /// reverse order never violates a foreign key.
  @override
  Future<void> wipe() => _db.transaction(() async {
    for (final table in _db.allTables.toList().reversed) {
      await _db.delete(table).go();
    }
  });

  @override
  Future<DriveResult> seed(String scenario) async {
    if (!seedScenarios.contains(scenario)) {
      return {
        'error': 'invalid_params',
        'message':
            'unknown scenario: $scenario (known: ${seedScenarios.join(', ')})',
      };
    }
    final seeder = _seeder;
    if (seeder != null && fileScenarios.contains(scenario)) {
      return seeder.load(scenario);
    }
    final group = (await _groups.create(
      name: 'Wochenende',
      currency: Currency.eur,
      createdBy: 'debug',
    )).orThrow();
    final ids = [group.id];
    for (final name in const ['Anna', 'Ben', 'Chiara', 'Dino']) {
      ids.add((await _members.add(group.id, name: name)).orThrow().id);
    }
    return {'ids': ids};
  }
}

final debugDataControlProvider = Provider<DebugDataControl>(
  (ref) => DriftDebugDataControl(
    db: ref.watch(appDatabaseProvider),
    groups: ref.watch(groupsRepositoryProvider),
    members: ref.watch(membersRepositoryProvider),
    seeder: ScenarioSeeder(
      source: (name) => rootBundle.loadString('assets/scenarios/$name.json'),
      groups: ref.watch(groupsRepositoryProvider),
      members: ref.watch(membersRepositoryProvider),
      expenses: ref.watch(expensesRepositoryProvider),
      vehicles: ref.watch(vehiclesRepositoryProvider),
      templates: ref.watch(rideTemplatesRepositoryProvider),
      rides: ref.watch(ridesRepositoryProvider),
      ids: ref.watch(idGeneratorProvider),
    ),
  ),
);
