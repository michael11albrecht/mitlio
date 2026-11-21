import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/themed_app.dart';
import 'profile_flow_rig.dart';

/// Contrast, tap targets, labels and overflow of every profile step, light
/// and dark at text scale 1.0 and 2.0.
void main() {
  const answers = {
    profileStepName: 'Anna Beispiel',
    profileStepPaypalWanted: true,
    profileStepPaypalMe: 'annab',
    profileStepBankWanted: true,
    profileStepIban: profileIbanStored,
  };

  /// A profile flow resumed at [step], with a saved profile and IBAN.
  Future<Widget> flowAt(int step, {bool finished = false}) async {
    final rig = ProfileFlowRig();
    rig.setup.stored[profileFlowId] = SetupProgress(
      stepIndex: step,
      answers: answers,
      finished: finished,
    ).toJson();
    await rig.profile.save(displayName: 'Anna Beispiel', avatarEmoji: '🚗');
    await rig.bank.save(
      iban: 'DE89370400440532013000',
      accountName: 'Anna Beispiel',
    );
    return ProviderScope(
      overrides: rig.overrides,
      child: const ProfileSetupView(),
    );
  }

  final screens = {
    'name step': (0, false),
    'avatar step': (1, false),
    'PayPal yes/no step': (2, false),
    'PayPal.Me step': (3, false),
    'bank yes/no step': (4, false),
    'IBAN step': (5, false),
    'finish screen': (5, true),
  };
  for (final MapEntry(key: name, value: (step, finished)) in screens.entries) {
    for (final brightness in Brightness.values) {
      for (final scale in const [1.0, 2.0]) {
        testWidgets('the $name is accessible (${brightness.name}, x$scale)', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            themedApp(
              await flowAt(step, finished: finished),
              brightness: brightness,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();
          await expectAccessible(tester);
          semantics.dispose();
        });
      }
    }
  }
}
