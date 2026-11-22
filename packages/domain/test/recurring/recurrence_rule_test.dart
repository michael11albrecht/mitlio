import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

RecurrenceRule _rule(
  DateTime start,
  RecurrenceFrequency f, {
  int interval = 1,
  DateTime? end,
}) => (RecurrenceRule.create(
  start: start,
  frequency: f,
  interval: interval,
  end: end,
) as Ok<RecurrenceRule, RecurrenceError>).value;

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

void main() {
  group('create', () {
    test('rejects interval below 1', () {
      final r = RecurrenceRule.create(
        start: _d(2026, 1, 1),
        frequency: RecurrenceFrequency.daily,
        interval: 0,
      );
      expect(r, const Err<RecurrenceRule, RecurrenceError>(InvalidInterval(0)));
    });

    test('rejects end before start', () {
      final r = RecurrenceRule.create(
        start: _d(2026, 1, 2),
        frequency: RecurrenceFrequency.daily,
        end: _d(2026, 1, 1),
      );
      expect(r, const Err<RecurrenceRule, RecurrenceError>(EndBeforeStart()));
    });

    test('end on start day is allowed', () {
      final r = RecurrenceRule.create(
        start: _d(2026, 1, 2),
        frequency: RecurrenceFrequency.daily,
        end: _d(2026, 1, 2),
      );
      expect(r, isA<Ok<RecurrenceRule, RecurrenceError>>());
    });

    test('ignores time of day', () {
      final r = _rule(DateTime(2026, 1, 1, 23, 59), RecurrenceFrequency.daily);
      expect(r.occurrence(0), _d(2026, 1, 1));
    });
  });

  group('occurrence', () {
    test('daily with interval', () {
      final r = _rule(_d(2026, 1, 30), RecurrenceFrequency.daily, interval: 3);
      expect(r.occurrence(0), _d(2026, 1, 30));
      expect(r.occurrence(1), _d(2026, 2, 2));
    });

    test('weekly', () {
      final r = _rule(_d(2026, 12, 28), RecurrenceFrequency.weekly);
      expect(r.occurrence(1), _d(2027, 1, 4));
    });

    test('monthly clamps to month end and returns to anchor day', () {
      final r = _rule(_d(2026, 1, 31), RecurrenceFrequency.monthly);
      expect(r.occurrence(1), _d(2026, 2, 28));
      expect(r.occurrence(2), _d(2026, 3, 31));
      expect(r.occurrence(3), _d(2026, 4, 30));
    });

    test('monthly leap year February', () {
      final r = _rule(_d(2027, 12, 31), RecurrenceFrequency.monthly);
      expect(r.occurrence(2), _d(2028, 2, 29));
    });

    test('monthly interval crosses year', () {
      final r = _rule(
        _d(2026, 11, 15),
        RecurrenceFrequency.monthly,
        interval: 3,
      );
      expect(r.occurrence(1), _d(2027, 2, 15));
    });

    test('yearly from Feb 29 clamps in non-leap years', () {
      final r = _rule(_d(2028, 2, 29), RecurrenceFrequency.yearly);
      expect(r.occurrence(1), _d(2029, 2, 28));
      expect(r.occurrence(4), _d(2032, 2, 29));
    });

    test('negative index throws', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.daily);
      expect(() => r.occurrence(-1), throwsArgumentError);
    });
  });

  group('occurrencesBetween', () {
    test('both ends inclusive', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.weekly);
      expect(r.occurrencesBetween(_d(2026, 1, 1), _d(2026, 1, 15)), [
        _d(2026, 1, 1),
        _d(2026, 1, 8),
        _d(2026, 1, 15),
      ]);
    });

    test('from after start skips earlier occurrences', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.weekly);
      expect(r.occurrencesBetween(_d(2026, 1, 2), _d(2026, 1, 15)), [
        _d(2026, 1, 8),
        _d(2026, 1, 15),
      ]);
    });

    test('never before start', () {
      final r = _rule(_d(2026, 3, 1), RecurrenceFrequency.monthly);
      expect(r.occurrencesBetween(_d(2025, 1, 1), _d(2026, 4, 1)), [
        _d(2026, 3, 1),
        _d(2026, 4, 1),
      ]);
    });

    test('stops at end date inclusive', () {
      final r = _rule(
        _d(2026, 1, 1),
        RecurrenceFrequency.monthly,
        end: _d(2026, 3, 1),
      );
      expect(r.occurrencesBetween(_d(2026, 1, 1), _d(2027, 1, 1)), [
        _d(2026, 1, 1),
        _d(2026, 2, 1),
        _d(2026, 3, 1),
      ]);
    });

    test('empty when to is before from', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.daily);
      expect(r.occurrencesBetween(_d(2026, 1, 5), _d(2026, 1, 4)), isEmpty);
    });

    test('time of day in bounds is ignored', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.daily);
      expect(
        r.occurrencesBetween(DateTime(2026, 1, 1, 23), DateTime(2026, 1, 2, 1)),
        [_d(2026, 1, 1), _d(2026, 1, 2)],
      );
    });
  });

  group('dueOccurrences', () {
    test('first run returns everything up to today', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.monthly);
      expect(r.dueOccurrences(lastGenerated: null, today: _d(2026, 3, 15)), [
        _d(2026, 1, 1),
        _d(2026, 2, 1),
        _d(2026, 3, 1),
      ]);
    });

    test('after last generated, exclusive', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.monthly);
      expect(
        r.dueOccurrences(lastGenerated: _d(2026, 2, 1), today: _d(2026, 4, 1)),
        [_d(2026, 3, 1), _d(2026, 4, 1)],
      );
    });

    test('nothing due twice', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.monthly);
      expect(
        r.dueOccurrences(lastGenerated: _d(2026, 3, 1), today: _d(2026, 3, 31)),
        isEmpty,
      );
    });

    test('catch-up is capped to the newest maxCount', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.daily);
      expect(
        r.dueOccurrences(
          lastGenerated: null,
          today: _d(2026, 1, 10),
          maxCount: 3,
        ),
        [_d(2026, 1, 8), _d(2026, 1, 9), _d(2026, 1, 10)],
      );
    });
  });

  group('occurrence argument check', () {
    test('negative n throws ArgumentError naming n with its message', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.daily);
      expect(
        () => r.occurrence(-1),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'n')
              .having((e) => e.invalidValue, 'invalidValue', -1)
              .having((e) => e.message, 'message', 'must be >= 0'),
        ),
      );
    });

    test('n of 0 is the start date', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.daily);
      expect(r.occurrence(0), _d(2026, 1, 1));
    });
  });

  group('dueOccurrences cap boundary', () {
    test('exactly maxCount due returns all of them', () {
      final r = _rule(_d(2026, 1, 1), RecurrenceFrequency.daily);
      final due = r.dueOccurrences(
        lastGenerated: null,
        today: _d(2026, 1, 3),
        maxCount: 3,
      );
      expect(due, [_d(2026, 1, 1), _d(2026, 1, 2), _d(2026, 1, 3)]);
    });
  });

  group('equality', () {
    final base = _rule(
      _d(2026, 1, 1),
      RecurrenceFrequency.weekly,
      interval: 2,
      end: _d(2026, 12, 31),
    );

    test('identical field values are equal with equal hashCode', () {
      final same = _rule(
        _d(2026, 1, 1),
        RecurrenceFrequency.weekly,
        interval: 2,
        end: _d(2026, 12, 31),
      );
      expect(same, base);
      expect(same.hashCode, base.hashCode);
    });

    test('differs when any single field differs', () {
      expect(
        _rule(
          _d(2026, 1, 2),
          RecurrenceFrequency.weekly,
          interval: 2,
          end: _d(2026, 12, 31),
        ),
        isNot(base),
      );
      expect(
        _rule(
          _d(2026, 1, 1),
          RecurrenceFrequency.daily,
          interval: 2,
          end: _d(2026, 12, 31),
        ),
        isNot(base),
      );
      expect(
        _rule(
          _d(2026, 1, 1),
          RecurrenceFrequency.weekly,
          interval: 3,
          end: _d(2026, 12, 31),
        ),
        isNot(base),
      );
      expect(
        _rule(_d(2026, 1, 1), RecurrenceFrequency.weekly, interval: 2),
        isNot(base),
      );
    });

    test('is not equal to a different type', () {
      // ignore: unrelated_type_equality_checks, testing operator== with another type
      expect(base == 'x', isFalse);
    });

    test('hashCode is Object.hash of start, frequency, interval, end', () {
      expect(
        base.hashCode,
        Object.hash(
          base.start,
          base.frequency,
          base.interval,
          base.end,
        ),
      );
    });

    test('toString shows frequency, interval and start', () {
      expect(
        base.toString(),
        'RecurrenceRule(RecurrenceFrequency.weekly/2 from ${base.start})',
      );
    });
  });

  group('properties', () {
    Glados3(
      any.intInRange(0, 3000),
      any.intInRange(1, 6),
      any.intInRange(0, 4),
    ).test('occurrences strictly increase, first is start', (
      offset,
      interval,
      f,
    ) {
      final start = _d(2020, 1, 1).add(Duration(days: offset));
      final r = _rule(
        start,
        RecurrenceFrequency.values[f],
        interval: interval,
      );
      var prev = r.occurrence(0);
      expect(prev, start);
      for (var n = 1; n < 40; n++) {
        final cur = r.occurrence(n);
        expect(cur.isAfter(prev), isTrue);
        prev = cur;
      }
    });

    Glados2(any.intInRange(0, 3000), any.intInRange(1, 4)).test(
      'monthly keeps anchor day or clamps to month end',
      (offset, interval) {
        final start = _d(2020, 1, 1).add(Duration(days: offset));
        final r = _rule(start, RecurrenceFrequency.monthly, interval: interval);
        for (var n = 0; n < 30; n++) {
          final o = r.occurrence(n);
          final lastDay = DateTime.utc(o.year, o.month + 1, 0).day;
          expect(o.day, start.day <= lastDay ? start.day : lastDay);
        }
      },
    );

    Glados2(any.intInRange(0, 3000), any.intInRange(0, 4)).test(
      'occurrencesBetween equals filtered occurrence sequence',
      (offset, f) {
        final start = _d(2020, 1, 1).add(Duration(days: offset));
        final r = _rule(start, RecurrenceFrequency.values[f]);
        final from = start.add(const Duration(days: 10));
        final to = start.add(const Duration(days: 400));
        final expected = [
          for (var n = 0; n < 500; n++) r.occurrence(n),
        ].where((d) => !d.isBefore(from) && !d.isAfter(to)).toList();
        expect(r.occurrencesBetween(from, to), expected);
      },
    );
  });
}
