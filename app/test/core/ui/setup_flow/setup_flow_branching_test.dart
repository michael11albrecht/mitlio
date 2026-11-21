import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'setup_flow_fixtures.dart';

/// `visibleWhen` (a step shown only after a "yes") and `commit` (an answer
/// stored elsewhere, never in the plain-text progress).
void main() {
  late FakeSetupStateRepository repo;
  var committed = <Object>[];
  RepositoryError? commitFails;

  final flow = SetupFlowConfig(
    id: 'branch',
    steps: [
      const SetupStepSpec('wanted'),
      SetupStepSpec(
        'detail',
        visibleWhen: (a) => a['wanted'] == true,
        commit: (ref, answer) async {
          if (commitFails case final e?) return Err(e);
          committed.add(answer);
          return const Ok(true);
        },
      ),
      const SetupStepSpec('last'),
    ],
  );

  Future<(ProviderContainer, SetupFlowViewModel)> launch() async {
    final c = containerOn(repo);
    addTearDown(c.dispose);
    final vm = c.read(setupFlowViewModelProvider(flow).notifier);
    await vm.restoring;
    return (c, vm);
  }

  SetupFlowState read(ProviderContainer c) =>
      c.read(setupFlowViewModelProvider(flow));

  setUp(() {
    repo = FakeSetupStateRepository();
    committed = [];
    commitFails = null;
  });

  group('visibleWhen', () {
    test('a "no" passes over the hidden step and counts it out', () async {
      final (c, vm) = await launch();
      expect(read(c).total, 2);
      await vm.next(answer: false);
      final s = read(c);
      expect((s.step?.id, s.position, s.total), ('last', 2, 2));
    });

    test('a "yes" shows the step and counts it in', () async {
      final (c, vm) = await launch();
      await vm.next(answer: true);
      final s = read(c);
      expect((s.step?.id, s.position, s.total), ('detail', 2, 3));
    });

    test('skipping the question hides the step', () async {
      final (c, vm) = await launch();
      await vm.skip();
      expect(read(c).step?.id, 'last');
    });

    test('back passes over the hidden step', () async {
      final (c, vm) = await launch();
      await vm.next(answer: false);
      expect(read(c).canGoBack, isTrue);
      await vm.back();
      expect(read(c).step?.id, 'wanted');
      expect(read(c).canGoBack, isFalse);
    });

    test('finish, then back, lands on the last visible step', () async {
      final (c, vm) = await launch();
      await vm.next(answer: false);
      await vm.next(answer: 'x');
      expect(read(c).finished, isTrue);
      await vm.back();
      expect(read(c).step?.id, 'last');
    });
  });

  group('commit', () {
    test('stores the answer elsewhere and remembers only its result', () async {
      final (c, vm) = await launch();
      await vm.next(answer: true);
      final r = await vm.next(answer: 'DE89 3704 0044 0532 0130 00');
      expect(r, isA<Ok<void, RepositoryError>>());
      expect(committed, ['DE89 3704 0044 0532 0130 00']);
      expect(read(c).answers['detail'], true);
      expect(repo.stored['branch'], isNot(contains('DE89')));
    });

    test('a failing commit stops the move and saves nothing raw', () async {
      final (c, vm) = await launch();
      await vm.next(answer: true);
      commitFails = const Storage('disk');
      final r = await vm.next(answer: 'secret');
      expect((r as Err<void, RepositoryError>).error, const Storage('disk'));
      expect(read(c).step?.id, 'detail');
      // Going back saves the progress: the raw answer must not be in it.
      await vm.back();
      expect(repo.stored['branch'], isNot(contains('secret')));
      expect(read(c).answers.containsKey('detail'), isFalse);
    });

    test('is not called on skip', () async {
      final (c, vm) = await launch();
      await vm.next(answer: true);
      await vm.skip();
      expect(committed, isEmpty);
      expect(read(c).skipped, ['detail']);
    });
  });
}
