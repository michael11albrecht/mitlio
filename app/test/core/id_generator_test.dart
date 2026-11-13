import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';

final _v7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  group('UuidV7Generator', () {
    late FixedClock clock;
    setUp(() => clock = FixedClock(DateTime.utc(2026, 11, 14, 12)));

    test('has v7 format, version nibble 7 and RFC variant bits', () {
      final gen = UuidV7Generator(clock: clock, random: Random(1));
      for (var i = 0; i < 200; i++) {
        final id = gen.newId();
        expect(id, matches(_v7));
        expect(id[14], '7');
        expect('89ab'.contains(id[19]), isTrue);
      }
    });

    test('encodes the clock time in the first 48 bits', () {
      final id = UuidV7Generator(clock: clock, random: Random(1)).newId();
      final ms = int.parse(id.replaceAll('-', '').substring(0, 12), radix: 16);
      expect(ms, clock.now().millisecondsSinceEpoch);
    });

    test('sorts lexicographically by increasing time', () {
      final gen = UuidV7Generator(clock: clock, random: Random(2));
      final ids = <String>[];
      for (var i = 0; i < 50; i++) {
        ids.add(gen.newId());
        clock.advance(const Duration(milliseconds: 1));
      }
      expect(ids, [...ids]..sort());
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('is deterministic with fixed clock and seeded random', () {
      final a = UuidV7Generator(clock: clock, random: Random(7));
      final b = UuidV7Generator(clock: clock, random: Random(7));
      expect([a.newId(), a.newId()], [b.newId(), b.newId()]);
    });

    test('defaults to a secure random and still yields distinct ids', () {
      final gen = UuidV7Generator(clock: clock);
      expect(gen.newId(), isNot(gen.newId()));
    });
  });

  test('SequentialIdGenerator counts up with prefix', () {
    final gen = SequentialIdGenerator(prefix: 'm');
    expect([gen.newId(), gen.newId(), gen.newId()], ['m-1', 'm-2', 'm-3']);
    expect(SequentialIdGenerator().newId(), 'id-1');
  });
}
