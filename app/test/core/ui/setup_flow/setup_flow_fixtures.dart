import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/core/ui/setup_flow/yes_no_step.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';

/// A small profile-like flow: a required name, then three optional steps.
const demoFlow = SetupFlowConfig(
  id: 'demo',
  steps: [
    SetupStepSpec('name', skippable: false, validate: _nonBlank),
    SetupStepSpec('paypal'),
    SetupStepSpec('handle'),
    SetupStepSpec('iban'),
  ],
);

String? _nonBlank(Object answer) =>
    answer is String && answer.trim().isNotEmpty ? null : 'name is blank';

Override useRepo(FakeSetupStateRepository repo) =>
    setupStateRepositoryProvider.overrideWithValue(repo);

/// A container like a fresh app start on [repo] (a "kill" is a new one).
ProviderContainer containerOn(
  FakeSetupStateRepository repo, {
  List<Override> extra = const [],
}) => ProviderContainer(overrides: [useRepo(repo), ...extra]);

/// The demo flow drawn with the framework widgets: text step, yes/no step,
/// two more text steps with a live result, then the finish screen. Wrapped
/// in a `ProviderScope` on [repo].
Widget demoFlowView(FakeSetupStateRepository repo) => ProviderScope(
  overrides: [useRepo(repo)],
  child: SetupFlowView(
    config: demoFlow,
    stepBuilder: (context, s) => switch (s.step.id) {
      'paypal' => YesNoStep(
        current: s.current,
        total: s.total,
        title: 'Möchtest du per PayPal Geld bekommen?',
        visual: const Icon(Icons.account_balance_wallet_outlined, size: 96),
        selected: s.answer as bool?,
        onAnswer: s.onNext,
        onSkip: s.onSkip,
        onBack: s.onBack,
      ),
      final id => StepScaffold(
        current: s.current,
        total: s.total,
        title: 'Frage $id',
        visual: const Icon(Icons.person_outline, size: 96),
        result: Text('Ergebnis: ${s.answer ?? '-'}'),
        onNext: s.onNext,
        onSkip: s.onSkip,
        onBack: s.onBack,
        child: TextField(
          decoration: InputDecoration(labelText: 'Wert $id'),
          onChanged: s.onAnswer,
        ),
      ),
    },
    finishBuilder: (context, back) => FinishStep(
      title: 'Alles eingerichtet',
      summary: const ['Name: Anna', 'PayPal.Me: anna'],
      actionLabel: 'Fertig',
      onAction: () {},
      onBack: back,
    ),
  ),
);
