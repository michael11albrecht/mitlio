import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';

import '../../repo_test_support.dart';

/// Behaviour every `MembersRepository` must show.
void runMembersRepositoryContract(
  String name,
  Future<Repos> Function() create,
) {
  group('MembersRepository contract ($name)', () {
    late Repos r;
    late String groupId;
    setUp(() async {
      r = await create();
      groupId = ok(
        await r.groups.create(name: 'Trip', currency: eur, createdBy: 'dev'),
      ).id;
    });

    test('add appends members at increasing positions', () async {
      final a = ok(await r.members.add(groupId, name: ' Ann '));
      final b = ok(
        await r.members.add(
          groupId,
          name: 'Ben',
          paypalMe: 'ben',
          ibanHint: 'DE..99',
        ),
      );
      expect(a.name, 'Ann');
      expect(a.position, 0);
      expect(a.groupId, groupId);
      expect(a.toDomain().position, 0);
      expect(b.position, 1);
      expect(b.paypalMe, 'ben');
      expect(b.ibanHint, 'DE..99');
      expect(ok(await r.members.list(groupId)), [a, b]);
    });

    test('add validates name and group', () async {
      expect(err(await r.members.add(groupId, name: ' ')), isA<InvalidData>());
      expect(
        err(await r.members.add('nope', name: 'Ann')),
        const NotFound('group', 'nope'),
      );
    });

    test('add to a soft-deleted group is NotFound', () async {
      ok(await r.groups.softDelete(groupId));
      expect(err(await r.members.add(groupId, name: 'Ann')), isA<NotFound>());
    });

    test('update replaces name and hints, keeps position', () async {
      final a = ok(
        await r.members.add(groupId, name: 'Ann', paypalMe: 'ann'),
      );
      final u = ok(await r.members.update(a.id, name: ' Anna '));
      expect(u.name, 'Anna');
      expect(u.paypalMe, isNull);
      expect(u.position, a.position);
      expect(ok(await r.members.list(groupId)), [u]);
    });

    test('update validates and reports unknown ids', () async {
      final a = ok(await r.members.add(groupId, name: 'Ann'));
      expect(err(await r.members.update(a.id, name: '')), isA<InvalidData>());
      expect(err(await r.members.update('nope', name: 'x')), isA<NotFound>());
    });

    test(
      'soft delete hides, undo restores; positions are not reused',
      () async {
        final a = ok(await r.members.add(groupId, name: 'Ann'));
        final b = ok(await r.members.add(groupId, name: 'Ben'));
        final undo = ok(await r.members.softDelete(b.id));
        expect(ok(await r.members.list(groupId)), [a]);
        expect(ok(await r.members.list(groupId, includeDeleted: true)), [a, b]);

        final c = ok(await r.members.add(groupId, name: 'Cy'));
        expect(c.position, 2);

        ok(await undo());
        expect(ok(await r.members.list(groupId)), [a, b, c]);
      },
    );

    test('soft delete and restore error cases', () async {
      expect(err(await r.members.softDelete('nope')), isA<NotFound>());
      expect(err(await r.members.restore('nope')), isA<NotFound>());
      final a = ok(await r.members.add(groupId, name: 'Ann'));
      expect(err(await r.members.restore(a.id)), isA<Conflict>());
      ok(await r.members.softDelete(a.id));
      expect(err(await r.members.softDelete(a.id)), isA<NotFound>());
    });

    test('list of an unknown group is empty', () async {
      expect(ok(await r.members.list('nope')), isEmpty);
    });

    test('watchMembers emits initial value and every change', () async {
      final probe = StreamProbe(r.members.watchMembers(groupId));
      expect(await probe.next(), isEmpty);

      final a = ok(await r.members.add(groupId, name: 'Ann'));
      expect(await probe.next(), [a]);

      final u = ok(await r.members.update(a.id, name: 'Anna'));
      expect(await probe.next(), [u]);

      final undo = ok(await r.members.softDelete(a.id));
      expect(await probe.next(), isEmpty);
      ok(await undo());
      expect(await probe.next(), [u]);
    });
  });
}
