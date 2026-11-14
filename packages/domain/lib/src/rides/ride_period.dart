// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// A span of calendar days that rides are aggregated over.
///
/// Only the year, month and day of a [DateTime] are used.
sealed class RidePeriod {
  const RidePeriod();

  /// Whether [date] (time ignored) falls inside this period.
  bool contains(DateTime date);
}

/// A single day.
final class Day extends RidePeriod {
  /// Creates the period for [date].
  const Day(this.date);

  final DateTime date;

  @override
  bool contains(DateTime date) => dayNumber(date) == dayNumber(this.date);

  @override
  bool operator ==(Object other) =>
      other is Day && dayNumber(other.date) == dayNumber(date);

  @override
  int get hashCode => Object.hash(Day, dayNumber(date));

  @override
  String toString() => 'Day(${dayNumber(date)})';
}

/// An ISO-8601 week (Monday start; week 1 contains the year's first Thursday).
final class Week extends RidePeriod {
  /// Creates the period for [isoWeek] of [isoYear].
  const Week(this.isoYear, this.isoWeek);

  final int isoYear;
  final int isoWeek;

  @override
  bool contains(DateTime date) {
    // ISO-8601: a week belongs to the year of its Thursday.
    final day = DateTime.utc(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final ordinal = thursday.difference(DateTime.utc(thursday.year)).inDays;
    return thursday.year == isoYear && ordinal ~/ 7 + 1 == isoWeek;
  }

  @override
  bool operator ==(Object other) =>
      other is Week && other.isoYear == isoYear && other.isoWeek == isoWeek;

  @override
  int get hashCode => Object.hash(Week, isoYear, isoWeek);

  @override
  String toString() => 'Week($isoYear-W$isoWeek)';
}

/// A calendar month.
final class Month extends RidePeriod {
  /// Creates the period for [month] (1-12) of [year].
  const Month(this.year, this.month);

  final int year;
  final int month;

  @override
  bool contains(DateTime date) => date.year == year && date.month == month;

  @override
  bool operator ==(Object other) =>
      other is Month && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(Month, year, month);

  @override
  String toString() => 'Month($year-$month)';
}

/// An arbitrary range, inclusive on both ends.
final class Custom extends RidePeriod {
  /// Creates the period from [from] to [to], both inclusive.
  const Custom(this.from, this.to);

  final DateTime from;
  final DateTime to;

  @override
  bool contains(DateTime date) {
    final n = dayNumber(date);
    return n >= dayNumber(from) && n <= dayNumber(to);
  }

  @override
  bool operator ==(Object other) =>
      other is Custom &&
      dayNumber(other.from) == dayNumber(from) &&
      dayNumber(other.to) == dayNumber(to);

  @override
  int get hashCode => Object.hash(Custom, dayNumber(from), dayNumber(to));

  @override
  String toString() => 'Custom(${dayNumber(from)}..${dayNumber(to)})';
}

/// Days since the Unix epoch of the calendar date of [d] (time ignored).
int dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;
