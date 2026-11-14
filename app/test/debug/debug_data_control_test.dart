import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_data_control.dart';

import '../features/repo_test_support.dart';

void main() {
  late Repos r;
  late DriftDebugDataControl control;

  setUp(() async {
    r = await driftRepos();
    control = DriftDebugDataControl(
      db: r.db!,
      groups: r.groups,
      members: r.members,
    );
  });

  test('seed groups creates a group with four members', () async {
    final result = await control.seed('groups');
    final ids = result['ids']! as List<Object?>;
    expect(ids, hasLength(5));
    expect(ok(await r.groups.get(ids.first! as String)).name, 'Wochenende');
    final members = ok(await r.members.list(ids.first! as String));
    expect(
      [for (final m in members) m.name],
      [
        'Anna',
        'Ben',
        'Chiara',
        'Dino',
      ],
    );
  });

  test('seed rejects an unknown scenario as invalid_params', () async {
    final result = await control.seed('nope');
    expect(result['error'], 'invalid_params');
    expect(result['message'], contains('groups'));
  });

  test('wipe removes everything, including entries and soft deletes', () async {
    final seeded = await seedGroup(r);
    ok(await r.members.softDelete(seeded.members.first.id));
    ok(await r.groups.create(name: 'Other', currency: eur, createdBy: 'x'));
    await control.wipe();
    expect(await r.groups.watchGroups().first, isEmpty);
    expect(
      ok(await r.members.list(seeded.groupId, includeDeleted: true)),
      isEmpty,
    );
  });

  test('wipe leaves the database usable', () async {
    await control.seed('groups');
    await control.wipe();
    final again = await control.seed('groups');
    expect(again['ids'], hasLength(5));
  });
}
