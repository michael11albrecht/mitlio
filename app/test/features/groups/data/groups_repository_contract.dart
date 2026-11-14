import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';

import '../../repo_test_support.dart';

/// Behaviour every [GroupsRepository] must show; run against Drift and the
/// in-memory fake.
void runGroupsRepositoryContract(
  String name,
  Future<GroupsRepository> Function() create,
) {
  group('GroupsRepository contract ($name)', () {
    late GroupsRepository repo;
    setUp(() async => repo = await create());

    Future<Group> newGroup([String n = 'Trip']) async =>
        ok(await repo.create(name: n, currency: eur, createdBy: 'dev'));

    test('create trims the name and returns the stored group', () async {
      final g = await newGroup('  Roadtrip  ');
      expect(g.name, 'Roadtrip');
      expect(g.currency, eur);
      expect(g.createdBy, 'dev');
      expect(g.createdAt.isUtc, isTrue);
      expect(g.id, isNotEmpty);
      expect(ok(await repo.get(g.id)), g);
    });

    test('create rejects a blank name', () async {
      expect(
        err(await repo.create(name: '  ', currency: eur, createdBy: 'dev')),
        isA<InvalidData>(),
      );
    });

    test('get of an unknown id is NotFound', () async {
      expect(err(await repo.get('nope')), const NotFound('group', 'nope'));
    });

    test('rename updates the group', () async {
      final g = await newGroup();
      final renamed = ok(await repo.rename(g.id, ' Ski '));
      expect(renamed.name, 'Ski');
      expect(renamed.id, g.id);
      expect(ok(await repo.get(g.id)).name, 'Ski');
    });

    test('rename validates and reports unknown ids', () async {
      final g = await newGroup();
      expect(err(await repo.rename(g.id, '')), isA<InvalidData>());
      expect(err(await repo.rename('nope', 'x')), isA<NotFound>());
    });

    test('soft delete hides the group and undo restores it', () async {
      final g = await newGroup();
      final undo = ok(await repo.softDelete(g.id));
      expect(err(await repo.get(g.id)), isA<NotFound>());
      ok(await undo());
      expect(ok(await repo.get(g.id)), g);
    });

    test('soft delete of unknown or deleted group is NotFound', () async {
      expect(err(await repo.softDelete('nope')), isA<NotFound>());
      final g = await newGroup();
      ok(await repo.softDelete(g.id));
      expect(err(await repo.softDelete(g.id)), isA<NotFound>());
    });

    test('restore: unknown is NotFound, live is Conflict', () async {
      expect(err(await repo.restore('nope')), isA<NotFound>());
      final g = await newGroup();
      expect(err(await repo.restore(g.id)), isA<Conflict>());
    });

    test('watchGroups emits initial value and every change', () async {
      final probe = StreamProbe(repo.watchGroups());
      expect(await probe.next(), isEmpty);

      final g = await newGroup();
      expect(await probe.next(), [g]);

      final renamed = ok(await repo.rename(g.id, 'Ski'));
      expect(await probe.next(), [renamed]);

      final undo = ok(await repo.softDelete(g.id));
      expect(await probe.next(), isEmpty);

      ok(await undo());
      expect(await probe.next(), [renamed]);
    });

    test('emitted lists are immutable', () async {
      final g = await newGroup();
      final probe = StreamProbe(repo.watchGroups());
      final list = await probe.next();
      expect(() => list.add(g), throwsUnsupportedError);
    });
  });
}
