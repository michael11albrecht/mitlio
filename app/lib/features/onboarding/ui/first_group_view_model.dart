import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Step ids of the first-group flow (PU-T12). Never rename after release.
abstract final class FirstGroupStep {
  static const name = 'name';
  static const people = 'people';
  static const currency = 'currency';
}

String? _validName(Object answer) =>
    answer is String && answer.trim().isNotEmpty ? null : 'name is blank';

String? _validPeople(Object answer) =>
    answer is List && answer.every((n) => n is String)
    ? null
    : 'people must be a list of names';

String? _validCurrency(Object answer) =>
    answer is String && Currency.all.any((c) => c.code == answer)
    ? null
    : 'unknown currency';

/// The first group with people (ADR-25 §4, at most three steps): what it is
/// called, who is in it, the currency (euro unless said otherwise). Only the
/// name is needed.
const firstGroupFlow = SetupFlowConfig(
  id: 'first_group',
  steps: [
    SetupStepSpec(FirstGroupStep.name, skippable: false, validate: _validName),
    SetupStepSpec(FirstGroupStep.people, validate: _validPeople),
    SetupStepSpec(FirstGroupStep.currency, validate: _validCurrency),
  ],
);

/// What the first-group flow has so far, as the finish screen shows it.
typedef FirstGroupAnswers = ({
  String name,
  List<String> people,
  Currency currency,
});

/// The answers of the flow, or null until the name is given.
FirstGroupAnswers? firstGroupAnswers(Map<String, Object?> answers) {
  final name = answers[FirstGroupStep.name];
  if (name is! String || name.trim().isEmpty) return null;
  final people = answers[FirstGroupStep.people];
  final code = answers[FirstGroupStep.currency];
  return (
    name: name.trim(),
    people: [
      if (people is List)
        for (final n in people)
          if (n is String && n.trim().isNotEmpty) n.trim(),
    ],
    currency:
        Currency.all.where((c) => c.code == code).firstOrNull ?? Currency.eur,
  );
}

/// What the finish screen of the flow shows.
final firstGroupAnswersProvider = Provider<FirstGroupAnswers?>(
  (ref) => firstGroupAnswers(
    ref.watch(setupFlowViewModelProvider(firstGroupFlow)).answers,
  ),
);

/// Creates the group of the finished flow: the one command behind the finish
/// screen's "Los geht's" and `ext.mitlio.onboarding.createGroup`.
class FirstGroupViewModel extends Notifier<bool> {
  /// True while [create] runs, so a double tap cannot create two groups.
  @override
  bool build() => false;

  /// Creates the group with the people ("Ich" from the profile first, if
  /// there is one), then clears the flow. [Conflict] while the name is
  /// missing. On a failure the answers stay, so "Nochmal versuchen" works.
  Future<RepoResult<Group>> create() async {
    final answers = ref.read(firstGroupAnswersProvider);
    if (answers == null) {
      return const Err(Conflict('first group is incomplete'));
    }
    if (state) return const Err(Conflict('already creating the group'));
    state = true;
    try {
      final created = await ref
          .read(groupsViewModelProvider.notifier)
          .create(
            name: answers.name,
            currency: answers.currency,
            memberNames: answers.people,
            withProfile: true,
          );
      if (created is Ok) {
        // Documented reason for ignoring a failure: the group exists already;
        // old progress only means the next "Gruppe anlegen" shows the finish
        // screen again, and an error would suggest the group was lost.
        await ref
            .read(setupStateRepositoryProvider)
            .save(firstGroupFlow.id, const SetupProgress());
        ref.invalidate(setupFlowViewModelProvider(firstGroupFlow));
      }
      return created;
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final firstGroupViewModelProvider = NotifierProvider<FirstGroupViewModel, bool>(
  FirstGroupViewModel.new,
);
