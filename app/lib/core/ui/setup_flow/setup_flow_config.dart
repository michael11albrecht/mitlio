// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// One step of a guided setup flow (ADR-25 §4). The visuals live in the
/// flow's step builder; this is only what the ViewModel needs to know.
final class SetupStepSpec {
  const SetupStepSpec(
    this.id, {
    this.skippable = true,
    this.validate,
    this.visibleWhen,
    this.commit,
  });

  /// Stable id: the key of the stored answer. Never rename after release.
  final String id;

  /// Optional steps offer "Überspringen". Only steps the feature cannot work
  /// without (a car needs consumption) are not skippable.
  final bool skippable;

  /// Developer-facing reason when the answer cannot be accepted, else null.
  /// Called with a non-null answer only.
  final String? Function(Object answer)? validate;

  /// Shown only when this returns true for the answers so far; null = always.
  /// A hidden step is passed over going forward and back, and is not counted
  /// in "Schritt 2 von 5". Called with the answers of the steps before it.
  final bool Function(Map<String, Object?> answers)? visibleWhen;

  /// Called with the checked, non-null answer on "Weiter" before anything is
  /// saved: stores it where it belongs (a repository) and returns what the
  /// flow remembers as the answer. For answers that must not land in the
  /// plain-text progress (an IBAN returns `true`). An [Err] stops the move;
  /// the raw answer stays in memory only and is never saved with the
  /// progress. Not called on skip.
  final Future<RepoResult<Object>> Function(Ref ref, Object answer)? commit;
}

/// A guided setup flow: an id (the storage key) and its steps in order. The
/// finish screen is not a step. Equal by id, so it works as a provider
/// family key.
final class SetupFlowConfig {
  const SetupFlowConfig({required this.id, required this.steps});

  final String id;
  final List<SetupStepSpec> steps;

  @override
  bool operator ==(Object other) => other is SetupFlowConfig && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
