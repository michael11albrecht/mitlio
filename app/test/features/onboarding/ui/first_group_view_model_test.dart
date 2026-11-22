import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/onboarding/ui/first_group_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../profile/ui/car_flow_support.dart';
import '../../repo_test_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer c;

  setUp(() {
    app = FakeApp();
    c = app.container();
    addTearDown(c.dispose);
  });

  RepositoryError errorOf(RepoResult<void> r) =>
      (r as Err<void, RepositoryError>).error;

  FirstGroupViewModel vm() => c.read(firstGroupViewModelProvider.notifier);

  group('steps', () {
    test('three steps: name, people, currency; only the name is needed', () {
      expect(
        [for (final s in firstGroupFlow.steps) s.id],
        ['name', 'people', 'currency'],
      );
      expect(
        [for (final s in firstGroupFlow.steps) s.skippable],
        [false, true, true],
      );
    });

    test('name: not blank', () async {
      await c.start(firstGroupFlow);
      for (final bad in [null, '  ', 3]) {
        expect(
          errorOf(await c.flow(firstGroupFlow).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
      await c.answer(firstGroupFlow, ' Rom ');
      expect(c.flowState(firstGroupFlow).step?.id, 'people');
    });

    test('people: a list of names; currency: a known code', () async {
      await c.start(firstGroupFlow);
      await c.answer(firstGroupFlow, 'Rom');
      for (final bad in [
        'Ann',
        3,
        <Object>[1, 2],
      ]) {
        expect(
          errorOf(await c.flow(firstGroupFlow).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
      await c.answer(firstGroupFlow, ['Ann', 'Ben']);
      expect(
        errorOf(await c.flow(firstGroupFlow).next(answer: 'XXX')),
        isA<InvalidData>(),
      );
      expect(
        errorOf(await c.flow(firstGroupFlow).next(answer: 'CHF ')),
        isA<InvalidData>(),
      );
      await c.answer(firstGroupFlow, 'CHF');
      expect(c.flowState(firstGroupFlow).finished, isTrue);
    });
  });

  group('create', () {
    test('creates the group with the people, euro by default', () async {
      await c.start(firstGroupFlow);
      await c.answer(firstGroupFlow, 'Rom');
      await c.answer(firstGroupFlow, ['Ann', ' ', 'Ben']);
      await c.skip(firstGroupFlow);
      final group = ok(await vm().create());
      expect(group.name, 'Rom');
      expect(group.currency, Currency.eur);
      final names = ok(await app.members.list(group.id)).map((m) => m.name);
      expect(names, ['Ann', 'Ben']);
    });

    test('with a profile, "Ich" is the first member', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      await c.start(firstGroupFlow);
      await c.answer(firstGroupFlow, 'Rom');
      await c.answer(firstGroupFlow, ['Ann']);
      await c.answer(firstGroupFlow, 'CHF');
      final group = ok(await vm().create());
      expect(group.currency.code, 'CHF');
      final names = ok(await app.members.list(group.id)).map((m) => m.name);
      expect(names, ['Mia', 'Ann']);
    });

    test('the people step can be skipped: just the group', () async {
      await c.start(firstGroupFlow);
      await c.answer(firstGroupFlow, 'Rom');
      await c.skip(firstGroupFlow);
      await c.skip(firstGroupFlow);
      final group = ok(await vm().create());
      expect(ok(await app.members.list(group.id)), isEmpty);
    });

    test('clears the flow so the next start is fresh', () async {
      await c.start(firstGroupFlow);
      await c.answer(firstGroupFlow, 'Rom');
      await c.skip(firstGroupFlow);
      await c.skip(firstGroupFlow);
      ok(await vm().create());
      final fresh = app.container();
      addTearDown(fresh.dispose);
      await fresh.start(firstGroupFlow);
      expect(fresh.flowState(firstGroupFlow).answers, isEmpty);
      expect(fresh.flowState(firstGroupFlow).finished, isFalse);
    });

    test('an unfinished flow is a conflict and creates nothing', () async {
      await c.start(firstGroupFlow);
      expect(errorOf(await vm().create()), isA<Conflict>());
      expect(await app.groups.watchGroups().first, isEmpty);
    });

    test('a failing store is returned, the answers stay', () async {
      await c.start(firstGroupFlow);
      await c.answer(firstGroupFlow, 'Rom');
      await c.skip(firstGroupFlow);
      await c.skip(firstGroupFlow);
      app.groups.failWith = const Storage('disk full');
      expect(errorOf(await vm().create()), const Storage('disk full'));
      expect(c.flowState(firstGroupFlow).answers['name'], 'Rom');
      app.groups.failWith = null;
      expect(ok(await vm().create()).name, 'Rom');
    });

    test('a second tap while saving creates no second group', () async {
      await c.start(firstGroupFlow);
      await c.answer(firstGroupFlow, 'Rom');
      await c.skip(firstGroupFlow);
      await c.skip(firstGroupFlow);
      final results = await Future.wait([vm().create(), vm().create()]);
      expect(results.whereType<Ok<Group, RepositoryError>>(), hasLength(1));
      expect(await app.groups.watchGroups().first, hasLength(1));
    });
  });
}
