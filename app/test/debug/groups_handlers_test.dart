import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/groups.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';

import '../features/repo_test_support.dart' show ok;
import '../helpers/fake_app.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;

  setUp(() {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
    h = groupsDriveHandlers(container);
  });

  test('groups.create makes a group with members, defaulting to EUR', () async {
    final r = await h['groups.create']!({
      'name': 'Trip',
      'members': '["Anna","Ben"]',
    });
    expect(r, {'id': 'id-1', 'name': 'Trip', 'currency': 'EUR'});
    final members = ok(await app.members.list('id-1'));
    expect([for (final m in members) m.name], ['Anna', 'Ben']);
  });

  test('groups.create takes a currency and no members', () async {
    final r = await h['groups.create']!({'name': 'Ski', 'currency': 'CHF'});
    expect(r['currency'], 'CHF');
  });

  test('groups.create validates params', () async {
    for (final bad in [
      <String, String>{},
      {'name': 'x', 'currency': 'XXX'},
      {'name': 'x', 'members': 'not json'},
      {'name': 'x', 'members': '[1]'},
      {'name': 'x', 'members': '{"a":1}'},
    ]) {
      expect((await h['groups.create']!(bad))['error'], 'invalid_params');
    }
  });

  test('groups.create reports a blank name as invalid_params', () async {
    final r = await h['groups.create']!({'name': ' '});
    expect(r['error'], 'invalid_params');
  });

  test('groups.list returns every group', () async {
    expect(await h['groups.list']!({}), {'groups': <Object?>[]});
    await h['groups.create']!({'name': 'Trip'});
    expect(await h['groups.list']!({}), {
      'groups': [
        {'id': 'id-1', 'name': 'Trip', 'currency': 'EUR'},
      ],
    });
  });

  test('groups.list reports a failing store as internal', () async {
    app.groups.watchError = StateError('down');
    expect((await h['groups.list']!({}))['error'], 'internal');
  });

  test('members.add appends and the group state shows it', () async {
    await h['groups.create']!({'name': 'Trip'});
    final r = await h['members.add']!({'groupId': 'id-1', 'name': 'Anna'});
    expect(r, {'id': 'id-2', 'name': 'Anna', 'position': 0});
    final detail = container.listen(
      groupDetailViewModelProvider('id-1'),
      (_, _) {},
    );
    addTearDown(detail.close);
    await pumpEventQueue();
    final snapshot = container
        .read(groupDetailViewModelProvider('id-1').notifier)
        .debugSnapshot();
    expect(snapshot['members'], [
      {'id': 'id-2', 'name': 'Anna', 'position': 0, 'inUse': false},
    ]);
  });

  test('members.add validates params and maps repository errors', () async {
    expect((await h['members.add']!({'name': 'x'}))['error'], 'invalid_params');
    expect(
      (await h['members.add']!({'groupId': 'g'}))['error'],
      'invalid_params',
    );
    await h['groups.create']!({'name': 'Trip'});
    expect(
      (await h['members.add']!({'groupId': 'id-1', 'name': ' '}))['error'],
      'invalid_params',
    );
    expect(
      (await h['members.add']!({'groupId': 'nope', 'name': 'A'}))['error'],
      'not_found',
    );
  });

  test('errors map to the documented codes', () async {
    await h['groups.create']!({'name': 'Trip'});
    app.members.failWith = const Conflict('c');
    expect(
      (await h['members.add']!({'groupId': 'id-1', 'name': 'A'}))['error'],
      'conflict',
    );
    app.members.failWith = const Storage('s');
    expect(
      (await h['members.add']!({'groupId': 'id-1', 'name': 'A'}))['error'],
      'internal',
    );
  });
}
