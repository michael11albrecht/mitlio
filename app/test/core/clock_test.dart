import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';

void main() {
  test('SystemClock returns roughly the current time', () {
    final before = DateTime.now();
    final now = const SystemClock().now();
    final after = DateTime.now();
    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });

  test('FixedClock returns the initial value until changed', () {
    final t = DateTime.utc(2026, 11, 14, 12);
    final clock = FixedClock(t);
    expect(clock.now(), t);
    expect(clock.now(), t);
  });

  test('FixedClock can be set and advanced', () {
    final clock = FixedClock(DateTime.utc(2026))
      ..value = DateTime.utc(2027)
      ..advance(const Duration(minutes: 5));
    expect(clock.now(), DateTime.utc(2027, 1, 1, 0, 5));
  });
}
