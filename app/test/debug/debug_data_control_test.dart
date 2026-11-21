import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/debug/debug_data_control.dart';
import 'package:mitlio/features/setup/data/drift_setup_state_repository.dart';

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

  test('wipe clears sync state but keeps the install node id', () async {
    final seeded = await seedGroup(r);
    final dao = r.db!.syncStateDao;
    await dao.setState(seeded.groupId, SyncState.shared);
    await dao.setCursor(seeded.groupId, 'expenses', 2);
    final nodeId = await dao.hlcNodeId(SequentialIdGenerator());
    await control.wipe();
    expect(await dao.groupSync(seeded.groupId), isNull);
    expect(await dao.cursorsOf(seeded.groupId), isEmpty);
    expect(await dao.setting(hlcNodeIdKey), nodeId);
  });

  test(
    'wipe starts the guided setup flows over, keeps other settings',
    () async {
      final dao = r.db!.syncStateDao;
      await dao.putSetting('${setupFlowKeyPrefix}profile', '{}');
      await dao.putSetting('other', 'kept');
      await control.wipe();
      expect(await dao.setting('${setupFlowKeyPrefix}profile'), isNull);
      expect(await dao.setting('other'), 'kept');
    },
  );
}
