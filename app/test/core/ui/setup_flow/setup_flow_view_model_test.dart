import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'setup_flow_fixtures.dart';

void main() {
  late FakeSetupStateRepository repo;

  /// Starts the flow like a fresh app launch and waits for the restore.
  Future<(ProviderContainer, SetupFlowViewModel)> launch() async {
    final c = containerOn(repo);
    addTearDown(c.dispose);
    final vm = c.read(setupFlowViewModelProvider(demoFlow).notifier);
    await vm.restoring;
    return (c, vm);
  }

  SetupFlowState read(ProviderContainer c) =>
      c.read(setupFlowViewModelProvider(demoFlow));

  RepositoryError errorOf(RepoResult<void> r) =>
      (r as Err<void, RepositoryError>).error;

  setUp(() => repo = FakeSetupStateRepository());

  group('start', () {
    test('is loading, then on the first step', () async {
      final c = containerOn(repo);
      addTearDown(c.dispose);
      expect(read(c).status, SetupFlowStatus.loading);
      await c.read(setupFlowViewModelProvider(demoFlow).notifier).restoring;
      final s = read(c);
      expect(s.status, SetupFlowStatus.ready);
      expect(s.step?.id, 'name');
      expect((s.stepIndex, s.total), (0, 4));
      expect(s.canGoBack, isFalse);
      expect(s.canSkip, isFalse);
      expect(s.finished, isFalse);
    });

    test('a failing read is reported and retry recovers', () async {
      repo.failLoadWith = const Storage('disk');
      final (c, vm) = await launch();
      expect(read(c).status, SetupFlowStatus.failed);
      expect(read(c).error, const Storage('disk'));
      repo.failLoadWith = null;
      await vm.retry();
      expect(read(c).status, SetupFlowStatus.ready);
    });

    test('unreadable saved data starts from the first step', () async {
      repo.stored['demo'] = '{not json';
      final (c, _) = await launch();
      expect(read(c).status, SetupFlowStatus.ready);
      expect(read(c).stepIndex, 0);
    });
  });

  group('next', () {
    test('needs an answer on a required step and moves nothing', () async {
      final (c, vm) = await launch();
      expect(errorOf(await vm.next()), isA<InvalidData>());
      expect(read(c).stepIndex, 0);
      expect(repo.stored, isEmpty);
    });

    test('rejects an answer the step does not accept', () async {
      final (c, vm) = await launch();
      expect(errorOf(await vm.next(answer: '  ')), isA<InvalidData>());
      expect(read(c).stepIndex, 0);
    });

    test('saves the answer and moves on', () async {
      final (c, vm) = await launch();
      expect(await vm.next(answer: 'Anna'), isA<Ok<void, RepositoryError>>());
      expect(read(c).stepIndex, 1);
      expect(read(c).answerOf('name'), 'Anna');
      expect(repo.stored['demo'], contains('Anna'));
    });

    test('an answer set earlier with answer() counts', () async {
      final (c, vm) = await launch();
      vm
        ..answer('Anna')
        ..answer('Anne');
      await vm.next();
      expect(read(c).answerOf('name'), 'Anne');
    });

    test('an optional step continues without an answer', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      expect(await vm.next(), isA<Ok<void, RepositoryError>>());
      expect(read(c).stepIndex, 2);
      expect(read(c).skipped, isEmpty);
    });

    test('after the last step the flow is finished and saved', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      await vm.next(answer: true);
      await vm.next(answer: 'anna');
      await vm.next(answer: 'DE89');
      final s = read(c);
      expect(s.finished, isTrue);
      expect(s.step, isNull);
      expect(s.canGoBack, isTrue);
      expect(repo.stored['demo'], contains('"finished":true'));
      expect(errorOf(await vm.next()), isA<Conflict>());
    });

    test('a failing save moves nothing and loses nothing', () async {
      final (c, vm) = await launch();
      repo.failSaveWith = const Storage('full');
      expect(errorOf(await vm.next(answer: 'Anna')), const Storage('full'));
      expect(read(c).stepIndex, 0);
      expect(read(c).answerOf('name'), 'Anna');
      repo.failSaveWith = null;
      expect(await vm.next(), isA<Ok<void, RepositoryError>>());
      expect(read(c).stepIndex, 1);
    });
  });

  group('skip', () {
    test('a required step cannot be skipped', () async {
      final (c, vm) = await launch();
      expect(errorOf(await vm.skip()), isA<InvalidData>());
      expect(read(c).stepIndex, 0);
    });

    test('moves on, forgets the answer and remembers the skip', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      vm.answer(true);
      expect(read(c).canSkip, isTrue);
      await vm.skip();
      expect(read(c).stepIndex, 2);
      expect(read(c).answerOf('paypal'), isNull);
      expect(read(c).skipped, ['paypal']);
      expect(repo.stored['demo'], contains('"skipped":["paypal"]'));
    });

    test('skipping the last step finishes the flow', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.skip();
      await vm.skip();
      expect(read(c).finished, isTrue);
    });

    test('answering a skipped step again clears the skip', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.back();
      vm.answer(false);
      expect(read(c).skipped, isEmpty);
    });

    test('a failing save moves nothing', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      repo.failSaveWith = const Storage('full');
      expect(errorOf(await vm.skip()), const Storage('full'));
      expect(read(c).stepIndex, 1);
      expect(read(c).skipped, isEmpty);
    });
  });

  group('back', () {
    test('is not possible on the first step', () async {
      final (_, vm) = await launch();
      expect(errorOf(await vm.back()), isA<Conflict>());
    });

    test('goes one step back and keeps the answers', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      await vm.next(answer: true);
      await vm.back();
      expect(read(c).stepIndex, 1);
      expect(read(c).answerOf('paypal'), isTrue);
      expect(read(c).answerOf('name'), 'Anna');
      expect(repo.stored['demo'], contains('"stepIndex":1'));
    });

    test('from the finish screen to the last step', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.skip();
      await vm.skip();
      await vm.back();
      expect(read(c).finished, isFalse);
      expect(read(c).step?.id, 'iban');
    });

    test('a failing save stays on the step', () async {
      final (c, vm) = await launch();
      await vm.next(answer: 'Anna');
      repo.failSaveWith = const Storage('full');
      expect(errorOf(await vm.back()), const Storage('full'));
      expect(read(c).stepIndex, 1);
    });
  });

  group('resume after kill', () {
    test('comes back on the same step with the same answers', () async {
      final (_, vm) = await launch();
      await vm.next(answer: 'Anna');
      await vm.next(answer: true);
      await vm.skip();
      // Process killed: a new container on the same storage.
      final (c2, _) = await launch();
      final s = read(c2);
      expect(s.step?.id, 'iban');
      expect(s.answerOf('name'), 'Anna');
      expect(s.answerOf('paypal'), isTrue);
      expect(s.skipped, ['handle']);
    });

    test('a finished flow stays finished', () async {
      final (_, vm) = await launch();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.skip();
      await vm.skip();
      final (c2, _) = await launch();
      expect(read(c2).finished, isTrue);
    });

    test('ignores steps that no longer exist', () async {
      repo.stored['demo'] =
          '{"stepIndex":99,"answers":{"name":"A","gone":1},'
          '"skipped":["gone"],"finished":false}';
      final (c, _) = await launch();
      expect(read(c).stepIndex, 3);
      expect(read(c).answers, {'name': 'A'});
      expect(read(c).skipped, isEmpty);
    });
  });

  test('a second command while one is saving is refused', () async {
    final (c, vm) = await launch();
    vm.answer('Anna');
    final first = vm.next();
    final second = await vm.next();
    expect(errorOf(second), isA<Conflict>());
    await first;
    expect(read(c).stepIndex, 1);
  });

  test('commands off a step do nothing', () async {
    final (c, vm) = await launch();
    await vm.next(answer: 'Anna');
    await vm.skip();
    await vm.skip();
    await vm.skip();
    vm.answer('late');
    expect(read(c).answers.containsValue('late'), isFalse);
    expect(errorOf(await vm.skip()), isA<Conflict>());
  });
}
