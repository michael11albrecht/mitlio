// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:convert';

/// Revisions kept per expense; older ones are pruned in the write transaction.
const expenseRevisionLimit = 50;

/// The expense aggregate as it was before a change (P7-T03). Never holds
/// IBANs or any bank data: expenses do not carry them, and [toJson] only
/// emits the fields below. The JSON shape is shared with the server trigger
/// (`supabase/migrations/0007_expense_revisions.sql`).
final class ExpenseSnapshot {
  const ExpenseSnapshot({
    required this.title,
    required this.amountCents,
    required this.currency,
    required this.fxRatePpm,
    required this.groupAmountCents,
    required this.date,
    required this.type,
    required this.splitMode,
    required this.payers,
    required this.shares,
    required this.weights,
    this.category,
    this.tripMeta,
  });

  factory ExpenseSnapshot.fromJson(Map<String, Object?> json) {
    final shares = (json['shares']! as List).cast<Map<String, Object?>>();
    return ExpenseSnapshot(
      title: json['title']! as String,
      amountCents: json['amount_cents']! as int,
      currency: json['currency']! as String,
      fxRatePpm: json['fx_rate_ppm']! as int,
      groupAmountCents: json['group_amount_cents']! as int,
      date: DateTime.parse(json['date']! as String).toUtc(),
      category: json['category'] as String?,
      type: json['type']! as String,
      splitMode: json['split_mode']! as String,
      tripMeta: switch (json['trip_meta']) {
        null => null,
        final String raw => raw,
        // The server keeps trip meta as jsonb, so its snapshots nest it.
        final Object nested => jsonEncode(nested),
      },
      payers: {
        for (final p in (json['payers']! as List).cast<Map<String, Object?>>())
          p['member_id']! as String: p['paid_cents']! as int,
      },
      shares: {
        for (final s in shares)
          s['member_id']! as String: s['share_cents']! as int,
      },
      weights: {
        for (final s in shares) s['member_id']! as String: s['weight']! as int,
      },
    );
  }

  final String title;

  /// Minor units of [currency] (the amount as paid).
  final int amountCents;
  final String currency;
  final int fxRatePpm;
  final int groupAmountCents;

  /// UTC.
  final DateTime date;
  final String? category;
  final String type;
  final String splitMode;

  /// Raw JSON text of the trip inputs, as stored.
  final String? tripMeta;

  /// Member id to paid cents.
  final Map<String, int> payers;

  /// Member id to share cents (group currency).
  final Map<String, int> shares;

  /// Member id to split weight (see `splitWeightOf`).
  final Map<String, int> weights;

  /// Members with a positive weight: the ones the expense is split between.
  /// (Stored shares also hold zero rows for everybody else.)
  Set<String> get participants => {
    for (final e in weights.entries)
      if (e.value > 0) e.key,
  };

  Map<String, Object?> toJson() => {
    'title': title,
    'amount_cents': amountCents,
    'currency': currency,
    'fx_rate_ppm': fxRatePpm,
    'group_amount_cents': groupAmountCents,
    'date': date.toUtc().toIso8601String(),
    'category': category,
    'type': type,
    'split_mode': splitMode,
    'trip_meta': tripMeta,
    'payers': [
      for (final e in payers.entries)
        {'member_id': e.key, 'paid_cents': e.value},
    ],
    'shares': [
      for (final e in shares.entries)
        {
          'member_id': e.key,
          'share_cents': e.value,
          'weight': weights[e.key] ?? 0,
        },
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is ExpenseSnapshot &&
      other.title == title &&
      other.amountCents == amountCents &&
      other.currency == currency &&
      other.fxRatePpm == fxRatePpm &&
      other.groupAmountCents == groupAmountCents &&
      other.date == date &&
      other.category == category &&
      other.type == type &&
      other.splitMode == splitMode &&
      other.tripMeta == tripMeta &&
      _sameMap(other.payers, payers) &&
      _sameMap(other.shares, shares) &&
      _sameMap(other.weights, weights);

  @override
  int get hashCode => Object.hash(
    title,
    amountCents,
    currency,
    fxRatePpm,
    groupAmountCents,
    date,
    category,
    type,
    splitMode,
    tripMeta,
    Object.hashAllUnordered(payers.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(shares.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(weights.entries.map((e) => (e.key, e.value))),
  );

  @override
  String toString() => 'ExpenseSnapshot($title, $amountCents $currency)';
}

bool _sameMap(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

/// One stored change: [snapshot] is the state *before* it. Creation writes
/// no row, so revision 1 is the first edit (or delete) of an expense.
final class ExpenseRevision {
  const ExpenseRevision({
    required this.id,
    required this.expenseId,
    required this.groupId,
    required this.revision,
    required this.changedAt,
    required this.snapshot,
    this.authorMemberId,
  });

  final String id;
  final String expenseId;
  final String groupId;
  final int revision;

  /// UTC.
  final DateTime changedAt;

  /// Null until accounts exist (nobody is signed in locally).
  final String? authorMemberId;
  final ExpenseSnapshot snapshot;

  @override
  bool operator ==(Object other) =>
      other is ExpenseRevision &&
      other.id == id &&
      other.expenseId == expenseId &&
      other.groupId == groupId &&
      other.revision == revision &&
      other.changedAt == changedAt &&
      other.authorMemberId == authorMemberId &&
      other.snapshot == snapshot;

  @override
  int get hashCode => Object.hash(
    id,
    expenseId,
    groupId,
    revision,
    changedAt,
    authorMemberId,
    snapshot,
  );

  @override
  String toString() => 'ExpenseRevision($expenseId #$revision)';
}

/// One human-visible difference between two snapshots. The View turns these
/// into localised sentences ("Betrag 42,00 € → 45,50 €").
sealed class ExpenseChange {
  const ExpenseChange();
}

final class TitleChange extends ExpenseChange {
  const TitleChange(this.from, this.to);
  final String from;
  final String to;
}

/// The paid amount (and/or its currency) changed.
final class AmountChange extends ExpenseChange {
  const AmountChange({
    required this.fromCents,
    required this.fromCurrency,
    required this.toCents,
    required this.toCurrency,
  });
  final int fromCents;
  final String fromCurrency;
  final int toCents;
  final String toCurrency;
}

/// The frozen FX rate changed (parts per million).
final class RateChange extends ExpenseChange {
  const RateChange(this.fromPpm, this.toPpm);
  final int fromPpm;
  final int toPpm;
}

final class DateChange extends ExpenseChange {
  const DateChange(this.from, this.to);
  final DateTime from;
  final DateTime to;
}

final class CategoryChange extends ExpenseChange {
  const CategoryChange(this.from, this.to);
  final String? from;
  final String? to;
}

final class SplitModeChange extends ExpenseChange {
  const SplitModeChange(this.from, this.to);
  final String from;
  final String to;
}

/// Trip inputs of a trip expense changed (details are not itemised).
final class TripDetailsChange extends ExpenseChange {
  const TripDetailsChange();
}

final class PayerAdded extends ExpenseChange {
  const PayerAdded(this.memberId);
  final String memberId;
}

final class PayerRemoved extends ExpenseChange {
  const PayerRemoved(this.memberId);
  final String memberId;
}

final class PaidChange extends ExpenseChange {
  const PaidChange(this.memberId, this.fromCents, this.toCents);
  final String memberId;
  final int fromCents;
  final int toCents;
}

final class ParticipantAdded extends ExpenseChange {
  const ParticipantAdded(this.memberId);
  final String memberId;
}

final class ParticipantRemoved extends ExpenseChange {
  const ParticipantRemoved(this.memberId);
  final String memberId;
}

/// A remaining participant's share changed while the total did not (a total
/// change rescales every share, which the amount line already says).
final class ShareChange extends ExpenseChange {
  const ShareChange(this.memberId, this.fromCents, this.toCents);
  final String memberId;
  final int fromCents;
  final int toCents;
}

/// Differences going from [from] to [to], in a stable order: title, amount,
/// rate, date, category, split mode, trip details, payers, participants,
/// shares (members sorted by id within each group).
List<ExpenseChange> diffSnapshots(ExpenseSnapshot from, ExpenseSnapshot to) {
  final changes = <ExpenseChange>[];
  if (from.title != to.title) changes.add(TitleChange(from.title, to.title));
  if (from.amountCents != to.amountCents || from.currency != to.currency) {
    changes.add(
      AmountChange(
        fromCents: from.amountCents,
        fromCurrency: from.currency,
        toCents: to.amountCents,
        toCurrency: to.currency,
      ),
    );
  }
  if (from.fxRatePpm != to.fxRatePpm) {
    changes.add(RateChange(from.fxRatePpm, to.fxRatePpm));
  }
  if (from.date != to.date) changes.add(DateChange(from.date, to.date));
  if (from.category != to.category) {
    changes.add(CategoryChange(from.category, to.category));
  }
  if (from.splitMode != to.splitMode) {
    changes.add(SplitModeChange(from.splitMode, to.splitMode));
  }
  if (from.tripMeta != to.tripMeta) changes.add(const TripDetailsChange());

  for (final id in _sortedUnion(from.payers, to.payers)) {
    final before = from.payers[id];
    final after = to.payers[id];
    if (before == null) {
      changes.add(PayerAdded(id));
    } else if (after == null) {
      changes.add(PayerRemoved(id));
    } else if (before != after) {
      changes.add(PaidChange(id, before, after));
    }
  }

  final totalSame = from.groupAmountCents == to.groupAmountCents;
  final before = from.participants;
  final after = to.participants;
  for (final id in ({...before, ...after}.toList()..sort())) {
    if (!before.contains(id)) {
      changes.add(ParticipantAdded(id));
    } else if (!after.contains(id)) {
      changes.add(ParticipantRemoved(id));
    } else if (totalSame && from.shares[id] != to.shares[id]) {
      changes.add(ShareChange(id, from.shares[id] ?? 0, to.shares[id] ?? 0));
    }
  }
  return changes;
}

List<String> _sortedUnion(Map<String, int> a, Map<String, int> b) =>
    {...a.keys, ...b.keys}.toList()..sort();
