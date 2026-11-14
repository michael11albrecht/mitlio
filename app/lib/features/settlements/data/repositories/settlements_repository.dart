// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// How a settlement was paid (`settlements.method`).
enum SettlementMethod {
  paypal,
  sepa,
  cash,
  other;

  static SettlementMethod? tryParse(String name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return null;
  }
}

/// User input for recording a settlement.
final class SettlementDraft {
  const SettlementDraft({
    required this.fromId,
    required this.toId,
    required this.amountCents,
    required this.currency,
    required this.date,
    required this.method,
  });

  final String fromId;
  final String toId;
  final int amountCents;

  /// Must equal the group currency.
  final Currency currency;
  final DateTime date;
  final SettlementMethod method;
}

/// A stored settlement: the validated domain value plus the payment method.
final class SettlementEntry {
  const SettlementEntry({
    required this.groupId,
    required this.settlement,
    required this.method,
    required this.createdAt,
  });

  final String groupId;
  final Settlement settlement;
  final SettlementMethod method;

  /// UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is SettlementEntry &&
      other.groupId == groupId &&
      other.settlement == settlement &&
      other.method == method &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(groupId, settlement, method, createdAt);

  @override
  String toString() => 'SettlementEntry($groupId, ${settlement.id})';
}

/// Source of truth for settlements. Lists are ordered by date ascending, then
/// id.
abstract interface class SettlementsRepository {
  /// Live settlements of [groupId]; emits the current list first, then after
  /// every change. Corrupted rows surface as stream errors.
  Stream<List<SettlementEntry>> watchSettlements(String groupId);

  Future<RepoResult<SettlementEntry>> get(String id);

  /// [NotFound] if the group is missing; [InvalidData] for domain violations
  /// (non-positive amount, self transfer, unknown member, foreign currency).
  Future<RepoResult<SettlementEntry>> create(
    String groupId,
    SettlementDraft draft,
  );

  /// Only amount, method and date are editable.
  Future<RepoResult<SettlementEntry>> update(
    String id, {
    required int amountCents,
    required SettlementMethod method,
    required DateTime date,
  });

  /// Soft delete; call the returned [Undo] to bring the settlement back.
  Future<RepoResult<Undo>> softDelete(String id);

  /// [NotFound] for unknown ids, [Conflict] if the settlement is not deleted.
  Future<RepoResult<void>> restore(String id);
}

/// Validates a settlement against the domain. Shared by every implementation.
RepoResult<Settlement> buildSettlement({
  required String id,
  required String fromId,
  required String toId,
  required int amountCents,
  required Currency currency,
  required DateTime date,
  required Currency groupCurrency,
  required List<Member> members,
}) {
  if (currency != groupCurrency) {
    return Err(
      InvalidData(
        'currency ${currency.code} differs from group currency '
        '${groupCurrency.code}',
      ),
    );
  }
  return switch (Settlement.create(
    id: id,
    fromId: fromId,
    toId: toId,
    amountCents: amountCents,
    currency: currency,
    date: date.toUtc(),
    members: members,
  )) {
    Ok<Settlement, SettlementError>(:final value) => Ok(value),
    Err<Settlement, SettlementError>(:final error) => Err(
      InvalidData('$error'),
    ),
  };
}
