// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/split/split_error.dart';

/// Why an expense could not be created.
sealed class ExpenseError {
  const ExpenseError();
}

/// The title is empty after trimming.
final class EmptyTitle extends ExpenseError {
  /// Creates the error.
  const EmptyTitle();

  @override
  bool operator ==(Object other) => other is EmptyTitle;

  @override
  int get hashCode => (EmptyTitle).hashCode;

  @override
  String toString() => 'EmptyTitle()';
}

/// The amount or split spec is invalid.
final class InvalidSplit extends ExpenseError {
  /// Wraps the underlying [error].
  const InvalidSplit(this.error);

  final SplitError error;

  @override
  bool operator ==(Object other) =>
      other is InvalidSplit && other.error == error;

  @override
  int get hashCode => Object.hash(InvalidSplit, error);

  @override
  String toString() => 'InvalidSplit($error)';
}

/// There is no payer.
final class NoPayer extends ExpenseError {
  /// Creates the error.
  const NoPayer();

  @override
  bool operator ==(Object other) => other is NoPayer;

  @override
  int get hashCode => (NoPayer).hashCode;

  @override
  String toString() => 'NoPayer()';
}

/// A payer id is not in the member list.
final class PayerNotMember extends ExpenseError {
  /// Creates the error.
  const PayerNotMember(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is PayerNotMember && other.id == id;

  @override
  int get hashCode => Object.hash(PayerNotMember, id);

  @override
  String toString() => 'PayerNotMember($id)';
}

/// A payer paid zero or a negative amount.
final class NonPositivePayment extends ExpenseError {
  /// Creates the error.
  const NonPositivePayment(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      other is NonPositivePayment && other.id == id;

  @override
  int get hashCode => Object.hash(NonPositivePayment, id);

  @override
  String toString() => 'NonPositivePayment($id)';
}

/// Payments do not sum to the expense amount.
final class PayersMismatch extends ExpenseError {
  /// Creates the error.
  const PayersMismatch(this.sum, this.expected);

  final int sum;
  final int expected;

  @override
  bool operator ==(Object other) =>
      other is PayersMismatch && other.sum == sum && other.expected == expected;

  @override
  int get hashCode => Object.hash(PayersMismatch, sum, expected);

  @override
  String toString() => 'PayersMismatch($sum, $expected)';
}
