import 'package:mitlio_domain/src/allocation/allocate.dart';
import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/members/member.dart';
import 'package:mitlio_domain/src/split/split_error.dart';
import 'package:mitlio_domain/src/split/split_spec.dart';

/// Divides [amountCents] among [members] according to [spec].
///
/// The result has an entry for every member (0 if not participating).
/// See docs/domain-rules.md, "Split modes".
Result<Map<String, int>, SplitError> computeShares({
  required int amountCents,
  required SplitSpec spec,
  required List<Member> members,
}) {
  if (amountCents <= 0) {
    return const Err(AmountNotPositive());
  }

  // Unique ids in tie order (first occurrence wins).
  final order = <String>{for (final m in tieOrder(members)) m.id}.toList();
  final known = order.toSet();

  // Normalise every mode to id -> value (equal: 1 per participant).
  final values = switch (spec) {
    EqualSplit(:final participants) => {for (final id in participants) id: 1},
    SharesSplit(:final weights) => weights,
    PercentSplit(:final basisPoints) => basisPoints,
    ExactSplit(:final cents) => cents,
  };

  // Sorted so the reported id is deterministic regardless of map order.
  final ids = values.keys.toList()..sort();
  for (final id in ids) {
    if (!known.contains(id)) {
      return Err(UnknownMember(id));
    }
  }
  for (final id in ids) {
    if (values[id]! < 0) {
      return Err(NegativeValue(id));
    }
  }

  // BigInt: sums of user-supplied values can exceed 2^53 on the web.
  final sum = values.values.fold(BigInt.zero, (a, v) => a + BigInt.from(v));
  switch (spec) {
    case PercentSplit():
      if (sum != BigInt.from(10000)) {
        return Err(PercentNotFull(sum.toInt()));
      }
    case ExactSplit():
      if (sum != BigInt.from(amountCents)) {
        return Err(ExactMismatch(sum.toInt(), amountCents));
      }
    case EqualSplit() || SharesSplit():
      break;
  }
  if (sum == BigInt.zero) {
    return const Err(NoParticipants());
  }

  if (spec is ExactSplit) {
    return Ok({for (final id in order) id: values[id] ?? 0});
  }
  final shares = allocate(amountCents, [
    for (final id in order) values[id] ?? 0,
  ]);
  return Ok({for (var i = 0; i < order.length; i++) order[i]: shares[i]});
}
