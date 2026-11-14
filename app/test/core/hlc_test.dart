import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';

void main() {
  setUp(Hlc.debugReset);

  test('format: ISO8601 UTC ms, 4 digit counter, node id', () {
    final clock = FixedClock(DateTime.utc(2026, 1, 2, 3, 4, 5, 6));
    expect(Hlc.now(clock), '2026-01-02T03:04:05.006Z-0000-local');
  });

  test('same millisecond bumps the counter; time advance resets it', () {
    final clock = FixedClock(DateTime.utc(2026));
    expect(Hlc.now(clock), '2026-01-01T00:00:00.000Z-0000-local');
    expect(Hlc.now(clock), '2026-01-01T00:00:00.000Z-0001-local');
    clock.advance(const Duration(milliseconds: 1));
    expect(Hlc.now(clock), '2026-01-01T00:00:00.001Z-0000-local');
  });

  test('a clock that goes backwards never produces a smaller value', () {
    final clock = FixedClock(DateTime.utc(2026, 1, 1, 12));
    final a = Hlc.now(clock);
    clock.value = DateTime.utc(2026);
    final b = Hlc.now(clock);
    expect(b.compareTo(a), greaterThan(0));
  });

  test('counter overflow moves the millisecond forward', () {
    final clock = FixedClock(DateTime.utc(2026));
    var last = Hlc.now(clock);
    for (var i = 0; i < 10001; i++) {
      final next = Hlc.now(clock);
      expect(next.compareTo(last), greaterThan(0));
      last = next;
    }
    expect(last, '2026-01-01T00:00:00.001Z-0001-local');
  });

  test('strings sort in generation order', () {
    final clock = FixedClock(DateTime.utc(2026));
    final all = <String>[];
    for (var i = 0; i < 50; i++) {
      all.add(Hlc.now(clock));
      if (i.isEven) clock.advance(const Duration(milliseconds: 3));
    }
    expect([...all]..sort(), all);
  });
}
