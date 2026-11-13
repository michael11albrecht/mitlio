// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// Why a split could not be computed.
sealed class SplitError {
  const SplitError();
}

/// The amount is zero or negative.
final class AmountNotPositive extends SplitError {
  /// Creates the error.
  const AmountNotPositive();

  @override
  bool operator ==(Object other) => other is AmountNotPositive;

  @override
  int get hashCode => (AmountNotPositive).hashCode;

  @override
  String toString() => 'AmountNotPositive()';
}

/// Nobody takes part in the split.
final class NoParticipants extends SplitError {
  /// Creates the error.
  const NoParticipants();

  @override
  bool operator ==(Object other) => other is NoParticipants;

  @override
  int get hashCode => (NoParticipants).hashCode;

  @override
  String toString() => 'NoParticipants()';
}

/// The spec mentions an id that is not in the member list.
final class UnknownMember extends SplitError {
  /// Creates the error.
  const UnknownMember(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is UnknownMember && other.id == id;

  @override
  int get hashCode => Object.hash(UnknownMember, id);

  @override
  String toString() => 'UnknownMember($id)';
}

/// A weight, basis-point or cents value is negative.
final class NegativeValue extends SplitError {
  /// Creates the error.
  const NegativeValue(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is NegativeValue && other.id == id;

  @override
  int get hashCode => Object.hash(NegativeValue, id);

  @override
  String toString() => 'NegativeValue($id)';
}

/// Basis points do not sum to 10000.
final class PercentNotFull extends SplitError {
  /// Creates the error.
  const PercentNotFull(this.sum);

  final int sum;

  @override
  bool operator ==(Object other) => other is PercentNotFull && other.sum == sum;

  @override
  int get hashCode => Object.hash(PercentNotFull, sum);

  @override
  String toString() => 'PercentNotFull($sum)';
}

/// Exact amounts do not sum to the expense amount.
final class ExactMismatch extends SplitError {
  /// Creates the error.
  const ExactMismatch(this.sum, this.expected);

  final int sum;
  final int expected;

  @override
  bool operator ==(Object other) =>
      other is ExactMismatch && other.sum == sum && other.expected == expected;

  @override
  int get hashCode => Object.hash(ExactMismatch, sum, expected);

  @override
  String toString() => 'ExactMismatch($sum, $expected)';
}
