import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/onboarding/ui/first_group_view.dart';
import 'package:mitlio/features/onboarding/ui/first_group_view_model.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';

import '../../../helpers/a11y.dart';

/// Contrast, tap targets, labels and overflow of every first-group step,
/// light and dark at text scale 1.0 and 2.0.
void main() {
  const answers = {
    FirstGroupStep.name: 'Rom',
    FirstGroupStep.people: ['Ann', 'Ben'],
    FirstGroupStep.currency: 'EUR',
  };

  Widget flowAt(int step, {bool finished = false}) {
    final store = FakeSetupStateRepository();
    store.stored[firstGroupFlow.id] = SetupProgress(
      stepIndex: step,
      answers: answers,
      finished: finished,
    ).toJson();
    return ProviderScope(
      overrides: [setupStateRepositoryProvider.overrideWithValue(store)],
      child: const FirstGroupView(),
    );
  }

  for (final (name, step, finished) in [
    ('name step', 0, false),
    ('people step', 1, false),
    ('currency step', 2, false),
    ('finish screen', 2, true),
  ]) {
    forEachMode(
      name,
      () => flowAt(step, finished: finished),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
