import 'package:mitlio_domain/mitlio_domain.dart';

/// Net balances plus both "who pays whom" views for one group.
final class BalancesResult {
  const BalancesResult({
    required this.balances,
    required this.simplified,
    required this.pairwise,
  });

  /// Member id to net cents (positive = gets money back).
  final Map<String, int> balances;

  /// At most n-1 transfers (`simplifyDebts`).
  final List<Transfer> simplified;

  /// Direct debts, see [pairwiseDebts].
  final List<Transfer> pairwise;
}

/// Computes balances and both transfer views. Throws [ArgumentError] for
/// unknown member ids or mixed currencies (from the domain).
BalancesResult computeBalancesResult({
  required List<Member> members,
  required Iterable<Expense> expenses,
  required Iterable<Settlement> settlements,
}) {
  final balances = computeBalances(
    members: members,
    expenses: expenses,
    settlements: settlements,
  );
  return BalancesResult(
    balances: balances,
    simplified: simplifyDebts(balances, members),
    pairwise: pairwiseDebts(
      members: members,
      expenses: expenses,
      settlements: settlements,
    ),
  );
}

/// The raw view: who owes whom directly, as the expenses created it.
///
/// Built on the domain only (no new domain rule): each expense is settled on
/// its own with `simplifyDebts` over `paid - share` (with one payer that is
/// every participant paying the payer their share). The per-expense debts are
/// summed per ordered pair, opposite directions are netted, and settlements
/// reduce the debt they pay. Every member's net outflow still equals
/// `-balance`, so this is the same truth as the simplified view, just
/// without routing money through third parties.
///
/// Sorted by debtor position, then creditor position; no zero transfers.
List<Transfer> pairwiseDebts({
  required List<Member> members,
  required Iterable<Expense> expenses,
  required Iterable<Settlement> settlements,
}) {
  // Signed debt per unordered pair, keyed (lo, hi) by id: positive means lo
  // owes hi, negative means hi owes lo.
  final owed = <(String, String), int>{};
  void add(String from, String to, int cents) {
    final forward = from.compareTo(to) < 0;
    owed.update(
      forward ? (from, to) : (to, from),
      (v) => v + (forward ? cents : -cents),
      ifAbsent: () => forward ? cents : -cents,
    );
  }

  for (final e in expenses) {
    final net = <String, int>{};
    e.payers.forEach((id, cents) => net[id] = (net[id] ?? 0) + cents);
    e.shares.forEach((id, cents) => net[id] = (net[id] ?? 0) - cents);
    for (final t in simplifyDebts(net, members)) {
      add(t.fromId, t.toId, t.amountCents);
    }
  }
  for (final s in settlements) {
    add(s.fromId, s.toId, -s.amountCents);
  }

  final position = {for (final m in members) m.id: m.position};
  final result =
      <Transfer>[
        for (final MapEntry(key: (lo, hi), value: cents) in owed.entries)
          if (cents > 0)
            Transfer(fromId: lo, toId: hi, amountCents: cents)
          else if (cents < 0)
            Transfer(fromId: hi, toId: lo, amountCents: -cents),
      ]..sort((a, b) {
        final byFrom = position[a.fromId]!.compareTo(position[b.fromId]!);
        return byFrom != 0
            ? byFrom
            : position[a.toId]!.compareTo(position[b.toId]!);
      });
  return result;
}
