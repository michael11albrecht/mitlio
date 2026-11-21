// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/recurring/recurrence_error.dart';

/// Unit of a recurrence step.
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// A rule that produces calendar dates: every [interval] [frequency] units
/// from [start], up to and including [end] when set.
///
/// Only the calendar date is used; all dates are returned as UTC midnight.
/// Monthly and yearly steps keep the day of [start] and clamp to the month
/// end (31 Jan, 28 Feb, 31 Mar). Each date is computed from [start], never
/// chained, so clamping does not drift.
final class RecurrenceRule {
  const RecurrenceRule._({
    required this.start,
    required this.frequency,
    required this.interval,
    required this.end,
  });

  /// Validates and creates a rule. [interval] must be at least 1 and [end],
  /// if given, must not be before [start].
  static Result<RecurrenceRule, RecurrenceError> create({
    required DateTime start,
    required RecurrenceFrequency frequency,
    int interval = 1,
    DateTime? end,
  }) {
    if (interval < 1) return Err(InvalidInterval(interval));
    final s = _date(start);
    final e = end == null ? null : _date(end);
    if (e != null && e.isBefore(s)) return const Err(EndBeforeStart());
    return Ok(
      RecurrenceRule._(
        start: s,
        frequency: frequency,
        interval: interval,
        end: e,
      ),
    );
  }

  final DateTime start;
  final RecurrenceFrequency frequency;
  final int interval;
  final DateTime? end;

  /// The [n]-th date (0 is [start]); ignores [end]. [n] must be >= 0.
  DateTime occurrence(int n) {
    if (n < 0) throw ArgumentError.value(n, 'n', 'must be >= 0');
    final steps = n * interval;
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime.utc(start.year, start.month, start.day + steps);
      case RecurrenceFrequency.weekly:
        return DateTime.utc(start.year, start.month, start.day + 7 * steps);
      case RecurrenceFrequency.monthly:
        return _clamped(start.year, start.month + steps);
      case RecurrenceFrequency.yearly:
        return _clamped(start.year + steps, start.month);
    }
  }

  /// All dates in [from]..[to], both inclusive, not before [start] and not
  /// after [end]. Times of day in the bounds are ignored.
  List<DateTime> occurrencesBetween(DateTime from, DateTime to) {
    final lo = _date(from);
    final hi = _date(to);
    final last = end;
    final result = <DateTime>[];
    for (var n = 0; ; n++) {
      final d = occurrence(n);
      if (d.isAfter(hi) || (last != null && d.isAfter(last))) break;
      if (!d.isBefore(lo)) result.add(d);
    }
    return result;
  }

  /// Dates that still need an expense: after [lastGenerated] (exclusive,
  /// `null` means none yet) up to [today] (inclusive). When more than
  /// [maxCount] are due, only the newest [maxCount] are returned, so a long
  /// offline period cannot flood a group.
  List<DateTime> dueOccurrences({
    required DateTime? lastGenerated,
    required DateTime today,
    int maxCount = 12,
  }) {
    final from = lastGenerated == null
        ? start
        : _date(lastGenerated).add(const Duration(days: 1));
    final all = occurrencesBetween(from, today);
    return all.length <= maxCount ? all : all.sublist(all.length - maxCount);
  }

  DateTime _clamped(int year, int month) {
    // Day 0 of the following month is the last day of [month].
    final last = DateTime.utc(year, month + 1, 0).day;
    return DateTime.utc(year, month, start.day < last ? start.day : last);
  }

  static DateTime _date(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.start == start &&
      other.frequency == frequency &&
      other.interval == interval &&
      other.end == end;

  @override
  int get hashCode => Object.hash(start, frequency, interval, end);

  @override
  String toString() => 'RecurrenceRule($frequency/$interval from $start)';
}
