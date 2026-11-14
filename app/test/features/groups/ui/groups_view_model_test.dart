import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;

  GroupsViewModel vm() => container.read(groupsViewModelProvider.notifier);
  GroupsState state() => container.read(groupsViewModelProvider);

  /// Reads the provider (keeping it alive) and waits for the first emission.
  Future<void> open() async {
    container.listen(groupsViewModelProvider, (_, _) {});
    await pumpEventQueue();
  }

  setUp(() {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  test('starts loading, then shows an empty list', () async {
    container.listen(groupsViewModelProvider, (_, _) {});
    expect(state(), isA<GroupsLoading>());
    await pumpEventQueue();
    expect(
      state(),
      isA<GroupsLoaded>().having((s) => s.isEmpty, 'empty', true),
    );
    expect(vm().debugSnapshot(), {'status': 'empty', 'groups': <Object?>[]});
  });

  group('create', () {
    test('adds the group; the list follows', () async {
      await open();
      final g = ok(await vm().create(name: ' Ski ', currency: Currency.chf));
      expect(g.name, 'Ski');
      expect(g.currency, Currency.chf);
      expect(g.createdBy, localOwnerId);
      expect((state() as GroupsLoaded).groups, [g]);
      expect(vm().debugSnapshot(), {
        'status': 'data',
        'groups': [
          {'id': g.id, 'name': 'Ski', 'currency': 'CHF'},
        ],
      });
    });

    test('appends members in order and skips blank names', () async {
      await open();
      final g = ok(
        await vm().create(
          name: 'Trip',
          currency: Currency.eur,
          memberNames: ['Anna', ' ', 'Ben'],
        ),
      );
      final members = ok(await app.members.list(g.id));
      expect([for (final m in members) m.name], ['Anna', 'Ben']);
      expect([for (final m in members) m.position], [0, 1]);
    });

    test('rejects a blank name without touching the repository', () async {
      await open();
      expect(
        err(await vm().create(name: '  ', currency: Currency.eur)),
        isA<InvalidData>(),
      );
      expect((state() as GroupsLoaded).isEmpty, isTrue);
    });

    test('reports a repository failure', () async {
      await open();
      app.groups.failWith = const Storage('disk full');
      expect(
        err(await vm().create(name: 'Trip', currency: Currency.eur)),
        const Storage('disk full'),
      );
      expect((state() as GroupsLoaded).isEmpty, isTrue);
    });

    test('keeps the group and reports a failing member add', () async {
      await open();
      app.members.failWith = const Storage('disk full');
      final r = await vm().create(
        name: 'Trip',
        currency: Currency.eur,
        memberNames: ['Anna'],
      );
      expect(err(r), const Storage('disk full'));
      expect((state() as GroupsLoaded).groups, hasLength(1));
    });
  });

  group('archive', () {
    test('hides the group and undo brings it back', () async {
      await open();
      final g = ok(await vm().create(name: 'Trip', currency: Currency.eur));
      final undo = ok(await vm().archive(g.id));
      await pumpEventQueue();
      expect((state() as GroupsLoaded).isEmpty, isTrue);
      ok(await undo());
      await pumpEventQueue();
      expect((state() as GroupsLoaded).groups, [g]);
    });

    test('unknown group is NotFound; repository failure is reported', () async {
      await open();
      expect(err(await vm().archive('nope')), isA<NotFound>());
      final g = ok(await vm().create(name: 'Trip', currency: Currency.eur));
      app.groups.failWith = const Storage('x');
      expect(err(await vm().archive(g.id)), isA<Storage>());
    });
  });

  group('failure', () {
    test('a failing stream shows the error; retry recovers', () async {
      app.groups.watchError = const Storage('db down');
      await open();
      expect(state(), isA<GroupsFailure>());
      expect(vm().debugSnapshot()['status'], 'error');

      app.groups.watchError = null;
      vm().retry();
      expect(state(), isA<GroupsLoading>());
      await pumpEventQueue();
      expect(state(), isA<GroupsLoaded>());
    });

    test('a non-repository stream error is wrapped as Storage', () async {
      final cause = StateError('boom');
      app.groups.watchError = cause;
      await open();
      expect((state() as GroupsFailure).error, Storage(cause));
    });
  });

  group('list', () {
    test('returns the current groups', () async {
      final g = ok(await vm().create(name: 'Trip', currency: Currency.eur));
      expect(ok(await vm().list()), [g]);
    });

    test('reports a failing stream', () async {
      app.groups.watchError = const Storage('db down');
      expect(err(await vm().list()), const Storage('db down'));
    });
  });
}
