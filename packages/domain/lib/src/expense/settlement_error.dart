// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// Why a settlement could not be created.
sealed class SettlementError {
  const SettlementError();
}

/// The amount is zero or negative.
final class NonPositiveAmount extends SettlementError {
  /// Creates the error.
  const NonPositiveAmount();

  @override
  bool operator ==(Object other) => other is NonPositiveAmount;

  @override
  int get hashCode => (NonPositiveAmount).hashCode;

  @override
  String toString() => 'NonPositiveAmount()';
}

/// Payer and recipient are the same member.
final class SelfTransfer extends SettlementError {
  /// Creates the error.
  const SelfTransfer();

  @override
  bool operator ==(Object other) => other is SelfTransfer;

  @override
  int get hashCode => (SelfTransfer).hashCode;

  @override
  String toString() => 'SelfTransfer()';
}

/// A party is not in the member list.
///
/// Named differently from the split error `UnknownMember` because both are
/// exported from the same library.
final class SettlementUnknownMember extends SettlementError {
  /// Creates the error.
  const SettlementUnknownMember(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      other is SettlementUnknownMember && other.id == id;

  @override
  int get hashCode => Object.hash(SettlementUnknownMember, id);

  @override
  String toString() => 'SettlementUnknownMember($id)';
}
