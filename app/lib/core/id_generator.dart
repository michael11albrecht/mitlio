import 'dart:math';

import 'package:mitlio/core/clock.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

/// Creates unique ids. Inject instead of creating UUIDs directly.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class IdGenerator {
  String newId();
}

/// UUIDv7 ids: time-ordered (millisecond precision), 74 random bits.
/// Time comes from [Clock] and randomness from [Random], so output is
/// deterministic given a fixed clock and a seeded random.
class UuidV7Generator implements IdGenerator {
  UuidV7Generator({required this.clock, Random? random})
    : random = random ?? Random.secure();

  final Clock clock;
  final Random random;
  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v7(
    config: V7Options(
      clock.now().millisecondsSinceEpoch,
      List<int>.generate(10, (_) => random.nextInt(256)),
    ),
  );
}

/// Test ids: `<prefix>-1`, `<prefix>-2`, ...
class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator({this.prefix = 'id'});

  final String prefix;
  int _next = 1;

  @override
  String newId() => '$prefix-${_next++}';
}
