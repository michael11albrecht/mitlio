// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/members/member.dart';

/// A payment of [amountCents] (> 0) from [fromId] to [toId].
final class Transfer {
  /// Creates a transfer; [amountCents] must be positive.
  Transfer({
    required this.fromId,
    required this.toId,
    required this.amountCents,
  }) {
    if (amountCents <= 0) {
      throw ArgumentError.value(amountCents, 'amountCents', 'must be > 0');
    }
  }

  final String fromId;
  final String toId;
  final int amountCents;

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.fromId == fromId &&
      other.toId == toId &&
      other.amountCents == amountCents;

  @override
  int get hashCode => Object.hash(fromId, toId, amountCents);

  @override
  String toString() => 'Transfer($fromId -> $toId, $amountCents)';
}

/// Settles [balances] (positive = is owed, negative = owes) with at most
/// n-1 transfers using the greedy rule from docs/domain-rules.md.
///
/// Throws [ArgumentError] if the balances do not sum to zero or contain a key
/// that is not in [members]. Members missing from [balances] count as 0.
List<Transfer> simplifyDebts(Map<String, int> balances, List<Member> members) {
  final order = tieOrder(members).map((m) => m.id).toList();
  final known = order.toSet();
  for (final id in balances.keys) {
    if (!known.contains(id)) {
      throw ArgumentError.value(id, 'balances', 'unknown member');
    }
  }
  final sum = balances.values.fold(BigInt.zero, (s, v) => s + BigInt.from(v));
  if (sum != BigInt.zero) {
    throw ArgumentError.value(balances, 'balances', 'must sum to zero');
  }

  final open = <String, int>{
    for (final id in order)
      if ((balances[id] ?? 0) != 0) id: balances[id]!,
  };
  final transfers = <Transfer>[];
  while (open.isNotEmpty) {
    String? debtor;
    String? creditor;
    // `open` iterates in tieOrder, so strict comparison keeps the earlier one.
    for (final e in open.entries) {
      if (e.value < 0 && (debtor == null || e.value < open[debtor]!)) {
        debtor = e.key;
      }
      if (e.value > 0 && (creditor == null || e.value > open[creditor]!)) {
        creditor = e.key;
      }
    }
    final debt = -open[debtor!]!;
    final credit = open[creditor!]!;
    final amount = debt < credit ? debt : credit;
    transfers.add(
      Transfer(fromId: debtor, toId: creditor, amountCents: amount),
    );
    if (debt == amount) {
      open.remove(debtor);
    } else {
      open[debtor] = -(debt - amount);
    }
    if (credit == amount) {
      open.remove(creditor);
    } else {
      open[creditor] = credit - amount;
    }
  }
  return transfers;
}
