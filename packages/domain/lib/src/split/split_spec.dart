// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// How an expense amount is divided among members.
sealed class SplitSpec {
  const SplitSpec();
}

bool _sameMap(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length &&
    a.entries.every((e) => b.containsKey(e.key) && b[e.key] == e.value);

// Order-independent hash.
int _mapHash(Map<String, int> m) =>
    m.entries.fold<int>(0, (h, e) => h ^ Object.hash(e.key, e.value));

/// Equal split among [participants].
final class EqualSplit extends SplitSpec {
  /// Creates an equal split.
  const EqualSplit(this.participants);

  final Set<String> participants;

  @override
  bool operator ==(Object other) =>
      other is EqualSplit &&
      other.participants.length == participants.length &&
      other.participants.containsAll(participants);

  @override
  int get hashCode => Object.hash(
    EqualSplit,
    participants.fold<int>(0, (h, s) => h ^ s.hashCode),
  );

  @override
  String toString() => 'EqualSplit($participants)';
}

/// Weighted split; weight 0 means excluded.
final class SharesSplit extends SplitSpec {
  /// Creates a shares split.
  const SharesSplit(this.weights);

  final Map<String, int> weights;

  @override
  bool operator ==(Object other) =>
      other is SharesSplit && _sameMap(other.weights, weights);

  @override
  int get hashCode => Object.hash(SharesSplit, _mapHash(weights));

  @override
  String toString() => 'SharesSplit($weights)';
}

/// Split by basis points; must sum to 10000.
final class PercentSplit extends SplitSpec {
  /// Creates a percent split.
  const PercentSplit(this.basisPoints);

  final Map<String, int> basisPoints;

  @override
  bool operator ==(Object other) =>
      other is PercentSplit && _sameMap(other.basisPoints, basisPoints);

  @override
  int get hashCode => Object.hash(PercentSplit, _mapHash(basisPoints));

  @override
  String toString() => 'PercentSplit($basisPoints)';
}

/// Explicit amounts per member; must sum to the expense amount.
final class ExactSplit extends SplitSpec {
  /// Creates an exact split.
  const ExactSplit(this.cents);

  final Map<String, int> cents;

  @override
  bool operator ==(Object other) =>
      other is ExactSplit && _sameMap(other.cents, cents);

  @override
  int get hashCode => Object.hash(ExactSplit, _mapHash(cents));

  @override
  String toString() => 'ExactSplit($cents)';
}
