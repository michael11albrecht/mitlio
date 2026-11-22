// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/mitlio_domain.dart';

/// What the user enters for a recurring expense: the expense itself (as the
/// add form holds it) plus when it repeats. Always in the group currency.
final class RecurringDraft {
  const RecurringDraft({
    required this.title,
    required this.amountCents,
    required this.payers,
    required this.split,
    required this.rule,
    this.category,
    this.lastGenerated,
  });

  final String title;
  final int amountCents;

  /// Member id to paid cents.
  final Map<String, int> payers;
  final SplitSpec split;
  final String? category;

  /// The date engine inputs (start, frequency, interval, end).
  final RecurrenceRule rule;

  /// The date an expense already exists for (the add form creates the first
  /// one itself), so catch-up starts after it. Null: none yet.
  final DateTime? lastGenerated;
}

/// A stored recurring rule.
final class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amountCents,
    required this.payers,
    required this.split,
    required this.rule,
    required this.paused,
    required this.createdAt,
    this.category,
    this.lastGenerated,
  });

  final String id;
  final String groupId;
  final String title;

  /// In the group currency.
  final int amountCents;
  final Map<String, int> payers;
  final SplitSpec split;
  final String? category;
  final RecurrenceRule rule;

  /// The newest date an expense was created for, midnight UTC.
  final DateTime? lastGenerated;

  /// A paused rule creates nothing; the dates that pass meanwhile are skipped
  /// when it is resumed (catch-up counts from the resume date).
  final bool paused;
  final DateTime createdAt;

  /// Dates that still need an expense on [today]; at most [maxCount], the
  /// newest ones (domain rule).
  List<DateTime> due(DateTime today, {int maxCount = 12}) =>
      rule.dueOccurrences(
        lastGenerated: lastGenerated,
        today: today,
        maxCount: maxCount,
      );

  /// The first date after [today] this rule fires, or null when it has ended.
  DateTime? nextAfter(DateTime today) {
    final day = DateTime.utc(today.year, today.month, today.day);
    final end = rule.end;
    for (var n = 0; ; n++) {
      final d = rule.occurrence(n);
      if (end != null && d.isAfter(end)) return null;
      if (d.isAfter(day)) return d;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RecurringExpense &&
      other.id == id &&
      other.groupId == groupId &&
      other.title == title &&
      other.amountCents == amountCents &&
      _sameMap(other.payers, payers) &&
      other.split == split &&
      other.category == category &&
      other.rule == rule &&
      other.lastGenerated == lastGenerated &&
      other.paused == paused &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    title,
    amountCents,
    split,
    category,
    rule,
    lastGenerated,
    paused,
    createdAt,
  );

  @override
  String toString() => 'RecurringExpense($id, $title, $rule)';
}

bool _sameMap(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

/// `YYYY-MM-DD` of the calendar day of [d] (as stored and as DebugDrive
/// speaks it).
String recurringDay(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// Why [draft] cannot be stored, or null.
String? validateRecurringDraft(RecurringDraft draft) {
  if (draft.title.trim().isEmpty) return 'title is empty';
  if (draft.amountCents <= 0) return 'amount must be positive';
  return null;
}
