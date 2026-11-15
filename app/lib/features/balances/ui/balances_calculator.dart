import 'package:mitlio/features/rides/ui/ride_settlement.dart';
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

/// What the not yet settled rides add to the balances.
final class OpenRides {
  const OpenRides({
    required this.expenses,
    required this.rideCount,
    required this.totalCents,
  });

  const OpenRides.none() : expenses = const [], rideCount = 0, totalCents = 0;

  /// One expense per driver and month, exactly the ones "Abrechnen" would
  /// create, so live balances equal the balances after closing the month.
  final List<Expense> expenses;
  final int rideCount;
  final int totalCents;
}

/// Internal name of the throwaway expenses; never shown.
const _draftTitle = 'open-rides';

/// The [unsettled] rides as the expenses their month's settlement
/// would create (`planSettlement` -> `rideAggregateToExpense`; no money math
/// here). Settled rides are already expenses and stay out. A month whose
/// rides the domain rejects or whose vehicle is unknown is skipped, as
/// settling it is impossible too.
OpenRides openRideExpenses({
  required Iterable<Ride> unsettled,
  required Map<String, Vehicle> vehicles,
  required Currency currency,
  required List<Member> members,
}) {
  final months = {for (final r in unsettled) Month(r.date.year, r.date.month)};
  final expenses = <Expense>[];
  var rideCount = 0;
  var totalCents = 0;
  for (final month in months) {
    final plan = planSettlement(
      unsettled: unsettled,
      month: month,
      vehicles: vehicles,
      currency: currency,
      members: members,
    );
    if (plan == null) continue;
    final monthExpenses = <Expense>[];
    for (final driver in plan.drivers) {
      final expense = rideAggregateToExpense(
        id: 'open-rides-${month.year}-${month.month}-${driver.driverId}',
        title: _draftTitle,
        date: DateTime.utc(month.year, month.month),
        aggregate: driver.aggregate,
        currency: currency,
        members: members,
      );
      if (expense is! Ok<Expense, ExpenseError>) {
        monthExpenses.clear();
        break;
      }
      monthExpenses.add(expense.value);
    }
    if (monthExpenses.isEmpty) continue;
    expenses.addAll(monthExpenses);
    rideCount += plan.rideCount;
    totalCents += plan.totalCents;
  }
  return OpenRides(
    expenses: expenses,
    rideCount: rideCount,
    totalCents: totalCents,
  );
}
