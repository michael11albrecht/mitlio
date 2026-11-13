// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/expense/expense_error.dart';
import 'package:mitlio_domain/src/members/member.dart';
import 'package:mitlio_domain/src/money/currency.dart';
import 'package:mitlio_domain/src/split/compute_shares.dart';
import 'package:mitlio_domain/src/split/split_error.dart';
import 'package:mitlio_domain/src/split/split_spec.dart';

bool _sameMap(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length &&
    a.entries.every((e) => b.containsKey(e.key) && b[e.key] == e.value);

// Order-independent hash.
int _mapHash(Map<String, int> m) =>
    m.entries.fold<int>(0, (h, e) => h ^ Object.hash(e.key, e.value));

/// A shared expense: who paid how much and how it is split.
final class Expense {
  const Expense._({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.currency,
    required this.date,
    required this.payers,
    required this.shares,
  });

  /// Validates and creates an expense.
  ///
  /// Check order: title, then amount and split (via [computeShares]), then
  /// payers: empty, unknown ids, non-positive payments, sum mismatch. When
  /// several payers are offending, the error names the smallest id: unknown
  /// ids by `String.compareTo`, non-positive payers by [tieOrder].
  static Result<Expense, ExpenseError> create({
    required String id,
    required String title,
    required int amountCents,
    required Currency currency,
    required DateTime date,
    required Map<String, int> payers,
    required SplitSpec split,
    required List<Member> members,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return const Err(EmptyTitle());

    final Map<String, int> computed;
    switch (computeShares(
      amountCents: amountCents,
      spec: split,
      members: members,
    )) {
      case Ok<Map<String, int>, SplitError>(:final value):
        computed = value;
      case Err<Map<String, int>, SplitError>(:final error):
        return Err(InvalidSplit(error));
    }

    if (payers.isEmpty) return const Err(NoPayer());
    final memberIds = members.map((m) => m.id).toSet();
    final unknown = payers.keys.where((k) => !memberIds.contains(k)).toList()
      ..sort();
    if (unknown.isNotEmpty) return Err(PayerNotMember(unknown.first));
    for (final m in tieOrder(members)) {
      final paid = payers[m.id];
      if (paid != null && paid <= 0) return Err(NonPositivePayment(m.id));
    }
    final sum = payers.values.fold<int>(0, (a, b) => a + b);
    if (sum != amountCents) return Err(PayersMismatch(sum, amountCents));

    return Ok(
      Expense._(
        id: id,
        title: trimmed,
        amountCents: amountCents,
        currency: currency,
        date: date,
        payers: Map.unmodifiable(payers),
        shares: Map.unmodifiable(computed),
      ),
    );
  }

  final String id;
  final String title;
  final int amountCents;
  final Currency currency;
  final DateTime date;

  /// Member id to paid cents; every value > 0, sum equals [amountCents].
  final Map<String, int> payers;

  /// Member id to share cents for every member; sum equals [amountCents].
  final Map<String, int> shares;

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.title == title &&
      other.amountCents == amountCents &&
      other.currency == currency &&
      other.date == date &&
      _sameMap(other.payers, payers) &&
      _sameMap(other.shares, shares);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    amountCents,
    currency,
    date,
    _mapHash(payers),
    _mapHash(shares),
  );

  @override
  String toString() => 'Expense($id, $title, $amountCents ${currency.code})';
}
