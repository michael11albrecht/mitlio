// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// One step of a guided setup flow (ADR-25 §4). The visuals live in the
/// flow's step builder; this is only what the ViewModel needs to know.
final class SetupStepSpec {
  const SetupStepSpec(this.id, {this.skippable = true, this.validate});

  /// Stable id: the key of the stored answer. Never rename after release.
  final String id;

  /// Optional steps offer "Überspringen". Only steps the feature cannot work
  /// without (a car needs consumption) are not skippable.
  final bool skippable;

  /// Developer-facing reason when the answer cannot be accepted, else null.
  /// Called with a non-null answer only.
  final String? Function(Object answer)? validate;
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
