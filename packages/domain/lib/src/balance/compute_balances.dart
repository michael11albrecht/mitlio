import 'package:mitlio_domain/src/expense/expense.dart';
import 'package:mitlio_domain/src/expense/settlement.dart';
import 'package:mitlio_domain/src/members/member.dart';
import 'package:mitlio_domain/src/money/currency.dart';
import 'package:mitlio_domain/src/money/money.dart';

/// Net balance per member: `paid - share + sent - received`.
///
/// Positive means the member gets money back. Every member is a key (0 if
/// untouched) and the values sum to zero. The result is unmodifiable.
///
/// Throws [ArgumentError] if an id is not in [members] or more than one
/// currency appears across [expenses] and [settlements], and [MoneyOverflow]
/// if a balance exceeds [Money.maxAbsCents].
Map<String, int> computeBalances({
  required List<Member> members,
  required Iterable<Expense> expenses,
  required Iterable<Settlement> settlements,
}) {
  final net = <String, BigInt>{for (final m in members) m.id: BigInt.zero};
  final currencies = <Currency>{};

  void add(String id, int cents) {
    final current = net[id];
    if (current == null) {
      throw ArgumentError.value(id, 'id', 'unknown member');
    }
    net[id] = current + BigInt.from(cents);
  }

  for (final e in expenses) {
    currencies.add(e.currency);
    e.payers.forEach(add);
    e.shares.forEach((id, cents) => add(id, -cents));
  }
  for (final s in settlements) {
    currencies.add(s.currency);
    add(s.fromId, s.amountCents);
    add(s.toId, -s.amountCents);
  }
  if (currencies.length > 1) {
    throw ArgumentError.value(
      currencies.map((c) => c.code).toList()..sort(),
      'currency',
      'mixed currencies',
    );
  }

  final limit = BigInt.from(Money.maxAbsCents);
  return Map.unmodifiable({
    for (final entry in net.entries)
      entry.key: entry.value.abs() > limit
          ? throw MoneyOverflow(entry.value.toInt())
          : entry.value.toInt(),
  });
}
