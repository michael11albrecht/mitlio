import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';

import '../features/profile/ui/profile_flow_rig.dart';
import 'golden_matrix.dart';

/// The profile flow (PU-T07), light/dark x 1.0/2.0: the screens that differ
/// from the framework's own (avatar, PayPal.Me with help, IBAN with the QR
/// preview, finish with the profile card). The illustrations are placeholder
/// slots until PU-T06 lands.
Future<void> main() async {
  const iban = 'DE89370400440532013000';

  /// A rig as if the user had got to [step] with [answers] saved.
  Future<ProfileFlowRig> rigAt(
    int step, {
    Map<String, Object?> answers = const {},
    bool finished = false,
    bool bank = false,
  }) async {
    final rig = ProfileFlowRig();
    rig.setup.stored[profileFlowId] = SetupProgress(
      stepIndex: step,
      answers: answers,
      finished: finished,
    ).toJson();
    await rig.profile.save(
      displayName: 'Anna Beispiel',
      avatarEmoji: '🚗',
      paypalMe: 'annab',
    );
    if (bank) {
      await rig.bank.save(iban: iban, accountName: 'Anna Beispiel');
    }
    return rig;
  }

  Future<void> golden(String name, ProfileFlowRig rig) => matrixGolden(
    name,
    () => ProviderScope(
      overrides: rig.overrides,
      child: const ProfileSetupView(),
    ),
    width: 360,
    height: 760,
  );

  await golden('profile_name', await rigAt(0));
  await golden(
    'profile_avatar',
    await rigAt(1, answers: {profileStepName: 'Anna Beispiel'}),
  );
  await golden(
    'profile_paypal_me',
    await rigAt(
      3,
      answers: {
        profileStepName: 'Anna Beispiel',
        profileStepPaypalWanted: true,
        profileStepPaypalMe: 'annab',
      },
    ),
  );
  await golden(
    'profile_iban',
    await rigAt(
      5,
      answers: {
        profileStepName: 'Anna Beispiel',
        profileStepBankWanted: true,
        profileStepIban: profileIbanStored,
      },
      bank: true,
    ),
  );
  await golden(
    'profile_finish',
    await rigAt(
      5,
      answers: {
        profileStepName: 'Anna Beispiel',
        profileStepPaypalWanted: true,
        profileStepPaypalMe: 'annab',
        profileStepBankWanted: true,
        profileStepIban: profileIbanStored,
      },
      finished: true,
      bank: true,
    ),
  );
}
