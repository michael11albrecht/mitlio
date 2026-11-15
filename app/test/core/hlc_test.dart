import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio_domain/mitlio_domain.dart' as domain;

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

  group('node id', () {
    test('init sets the node id and restarts the clock', () {
      final clock = FixedClock(DateTime.utc(2026));
      Hlc.now(clock);
      Hlc.init('node-a');
      expect(Hlc.now(clock), '2026-01-01T00:00:00.000Z-0000-node-a');
    });

    test('two installs never produce equal timestamps', () {
      final clock = FixedClock(DateTime.utc(2026));
      Hlc.init('a');
      final a = Hlc.now(clock);
      Hlc.init('b');
      final b = Hlc.now(clock);
      expect(a, isNot(b));
    });

    test('a node id with dashes (UUID) still parses back', () {
      final clock = FixedClock(DateTime.utc(2026));
      Hlc.init('0190a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b');
      final parsed = domain.Hlc.parse(Hlc.now(clock));
      expect(
        (parsed as domain.Ok<domain.Hlc, domain.HlcError>).value.nodeId,
        '0190a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b',
      );
    });
  });

  group('receive', () {
    String ok(domain.Result<String, domain.HlcError> r) =>
        (r as domain.Ok<String, domain.HlcError>).value;

    test('result is greater than local and remote, keeps our node id', () {
      Hlc.init('me');
      final clock = FixedClock(DateTime.utc(2026));
      final local = Hlc.now(clock);
      const remote = '2026-01-01T00:00:00.005Z-0007-peer';
      final merged = ok(Hlc.receive(remote, clock));
      expect(merged.compareTo(local), greaterThan(0));
      expect(merged.compareTo(remote), greaterThan(0));
      expect(merged, '2026-01-01T00:00:00.005Z-0008-me');
    });

    test('the next now() is after the received timestamp', () {
      Hlc.init('me');
      final clock = FixedClock(DateTime.utc(2026));
      const remote = '2026-01-01T00:00:30.000Z-0002-peer';
      ok(Hlc.receive(remote, clock));
      expect(Hlc.now(clock).compareTo(remote), greaterThan(0));
    });

    test('a remote from the past still moves the clock forward', () {
      Hlc.init('me');
      final clock = FixedClock(DateTime.utc(2026, 1, 1, 12));
      final local = Hlc.now(clock);
      final merged = ok(
        Hlc.receive('2025-01-01T00:00:00.000Z-0000-peer', clock),
      );
      expect(merged.compareTo(local), greaterThan(0));
    });

    test('drift: more than a minute ahead is returned and not adopted', () {
      Hlc.init('me');
      final clock = FixedClock(DateTime.utc(2026));
      final before = Hlc.now(clock);
      final r = Hlc.receive('2026-01-01T00:01:00.001Z-0000-peer', clock);
      expect(r, isA<domain.Err<String, domain.HlcError>>());
      expect(
        (r as domain.Err<String, domain.HlcError>).error,
        isA<domain.ClockDrift>(),
      );
      // The local clock is untouched: the next value follows `before` only.
      expect(Hlc.now(clock), '2026-01-01T00:00:00.000Z-0001-me');
      expect(before, '2026-01-01T00:00:00.000Z-0000-me');
    });

    test('exactly one minute ahead is accepted', () {
      Hlc.init('me');
      final clock = FixedClock(DateTime.utc(2026));
      expect(
        Hlc.receive('2026-01-01T00:01:00.000Z-0000-peer', clock),
        isA<domain.Ok<String, domain.HlcError>>(),
      );
    });

    test('a malformed remote is an error, not a crash', () {
      final clock = FixedClock(DateTime.utc(2026));
      final r = Hlc.receive('garbage', clock);
      expect(
        (r as domain.Err<String, domain.HlcError>).error,
        isA<domain.HlcInvalidFormat>(),
      );
    });

    test('counter overflow borrows the next millisecond', () {
      Hlc.init('me');
      final clock = FixedClock(DateTime.utc(2026));
      const remote = '2026-01-01T00:00:00.000Z-9999-peer';
      final merged = ok(Hlc.receive(remote, clock));
      expect(merged, '2026-01-01T00:00:00.001Z-0000-me');
    });
  });
}
