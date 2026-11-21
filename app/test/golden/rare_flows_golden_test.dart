import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/onboarding/ui/first_group_view.dart';
import 'package:mitlio/features/onboarding/ui/first_group_view_model.dart';
import 'package:mitlio/features/rides/ui/commute_template_view.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';

import '../features/rides/ui/rides_fixtures.dart';
import 'golden_matrix.dart';

/// The rare flows moved onto the step flow (PU-T12), light/dark x 1.0/2.0:
/// the screens that are new (the month settlement ones are in
/// `rides_golden_test.dart`).
Future<void> main() async {
  Widget firstGroup(int step, {bool finished = false}) {
    final store = FakeSetupStateRepository();
    store.stored[firstGroupFlow.id] = SetupProgress(
      stepIndex: step,
      answers: const {
        FirstGroupStep.name: 'Rom',
        FirstGroupStep.people: ['Ann', 'Ben'],
        FirstGroupStep.currency: 'EUR',
      },
      finished: finished,
    ).toJson();
    return ProviderScope(
      overrides: [setupStateRepositoryProvider.overrideWithValue(store)],
      child: const FirstGroupView(),
    );
  }

  await matrixGolden(
    'first_group_name',
    () => firstGroup(0),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'first_group_people',
    () => firstGroup(1),
    width: 360,
    height: 760,
  );
  await matrixGolden(
    'first_group_finish',
    () => firstGroup(2, finished: true),
    width: 360,
    height: 640,
  );

  Widget commute({int step = 0, bool finished = false}) => scopedRides([
    ...setupStateOverride(setupData),
    ...commuteProgress(step: step, finished: finished),
  ], const CommuteTemplateView(groupId: 'g-1'));

  await matrixGolden(
    'commute_route',
    () => commute(step: 1),
    width: 360,
    height: 760,
  );
  await matrixGolden(
    'commute_people',
    () => commute(step: 3),
    width: 360,
    height: 800,
  );
  await matrixGolden(
    'commute_finish',
    () => commute(step: 4, finished: true),
    width: 360,
    height: 640,
  );
}
