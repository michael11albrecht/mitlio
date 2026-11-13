// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/expense/settlement_error.dart';
import 'package:mitlio_domain/src/members/member.dart';
import 'package:mitlio_domain/src/money/currency.dart';

/// A direct payment from one member to another that settles debt.
final class Settlement {
  const Settlement._({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.amountCents,
    required this.currency,
    required this.date,
  });

  /// Validates and creates a settlement.
  ///
  /// Check order: amount > 0, then `fromId != toId`, then `fromId` known,
  /// then `toId` known.
  static Result<Settlement, SettlementError> create({
    required String id,
    required String fromId,
    required String toId,
    required int amountCents,
    required Currency currency,
    required DateTime date,
    required List<Member> members,
  }) {
    if (amountCents <= 0) return const Err(SettlementNonPositiveAmount());
    if (fromId == toId) return const Err(SelfTransfer());
    final ids = members.map((m) => m.id).toSet();
    if (!ids.contains(fromId)) return Err(SettlementUnknownMember(fromId));
    if (!ids.contains(toId)) return Err(SettlementUnknownMember(toId));
    return Ok(
      Settlement._(
        id: id,
        fromId: fromId,
        toId: toId,
        amountCents: amountCents,
        currency: currency,
        date: date,
      ),
    );
  }

  final String id;
  final String fromId;
  final String toId;
  final int amountCents;
  final Currency currency;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is Settlement &&
      other.id == id &&
      other.fromId == fromId &&
      other.toId == toId &&
      other.amountCents == amountCents &&
      other.currency == currency &&
      other.date == date;

  @override
  int get hashCode =>
      Object.hash(id, fromId, toId, amountCents, currency, date);

  @override
  String toString() =>
      'Settlement($id, $fromId -> $toId, $amountCents ${currency.code})';
}
