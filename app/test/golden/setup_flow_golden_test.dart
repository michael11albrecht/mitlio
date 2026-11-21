import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_progress_bar.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/core/ui/setup_flow/yes_no_step.dart';

import 'golden_matrix.dart';

/// Each step type of the setup-flow framework (PU-T05), light/dark x 1.0/2.0.
/// The finish screen shows the celebration's final frame (animations settle).
Future<void> main() async {
  await matrixGolden(
    'setup_step_input',
    () => StepScaffold(
      current: 2,
      total: 5,
      title: 'Wie hoch ist dein Verbrauch?',
      visual: const Icon(Icons.local_gas_station_outlined, size: 96),
      result: const Text('≈ 7,4 ct/km'),
      onNext: () {},
      onSkip: () {},
      onBack: () {},
      child: const TextField(
        decoration: InputDecoration(labelText: 'l/100 km'),
      ),
    ),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'setup_step_yes_no',
    () => YesNoStep(
      current: 3,
      total: 5,
      title: 'Möchtest du per PayPal Geld bekommen?',
      visual: const Icon(Icons.account_balance_wallet_outlined, size: 96),
      selected: true,
      onAnswer: (_) {},
      onSkip: () {},
      onBack: () {},
    ),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'setup_finish',
    () => FinishStep(
      title: 'Dein Profil ist fertig',
      summary: const ['Name: Anna', 'PayPal.Me: anna'],
      actionLabel: 'Zur Gruppe',
      onAction: () {},
      onBack: () {},
    ),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'setup_progress',
    () => const Padding(
      padding: EdgeInsets.all(16),
      child: SetupProgressBar(current: 3, total: 5),
    ),
    width: 360,
    height: 80,
  );
}
