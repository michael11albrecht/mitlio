// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/sync/hlc_error.dart';

/// Hybrid logical clock timestamp (Kulkarni et al.).
///
/// Serialized as `<ISO8601 UTC ms>-<counter 4 digits>-<nodeId>`, e.g.
/// `2026-01-01T00:00:00.000Z-0000-phone`. Because the wall part is fixed
/// width (years 0000..9999) and the counter is zero padded, string order
/// equals [compareTo] order.
final class Hlc implements Comparable<Hlc> {
  /// Creates a timestamp. [wallMillis] must be within [minWallMillis]..
  /// [maxWallMillis], [counter] within 0..[maxCounter], [nodeId] non-empty;
  /// otherwise [ArgumentError].
  Hlc({
    required this.wallMillis,
    required this.counter,
    required this.nodeId,
  }) {
    if (wallMillis < minWallMillis || wallMillis > maxWallMillis) {
      throw ArgumentError.value(wallMillis, 'wallMillis', 'out of range');
    }
    if (counter < 0 || counter > maxCounter) {
      throw ArgumentError.value(counter, 'counter', 'out of range');
    }
    if (nodeId.isEmpty) {
      throw ArgumentError.value(nodeId, 'nodeId', 'must not be empty');
    }
  }

  /// 0000-01-01T00:00:00.000Z.
  static const minWallMillis = -62167219200000;

  /// 9999-12-31T23:59:59.999Z.
  static const maxWallMillis = 253402300799999;

  /// Highest logical counter (four digits).
  static const maxCounter = 9999;

  /// Default tolerated remote clock lead.
  static const defaultMaxDriftMillis = 60000;

  static final _format = RegExp(
    r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z)-(\d{4})-(.+)$',
  );

  final int wallMillis;
  final int counter;
  final String nodeId;

  /// Parses the [toString] format.
  static Result<Hlc, HlcError> parse(String input) {
    final m = _format.firstMatch(input);
    final wall = m == null ? null : DateTime.tryParse(m.group(1)!);
    // Re-formatting rejects dates that DateTime.parse silently rolls over.
    if (m == null || wall == null || wall.toIso8601String() != m.group(1)) {
      return Err(HlcInvalidFormat(input));
    }
    return Ok(
      Hlc(
        wallMillis: wall.millisecondsSinceEpoch,
        counter: int.parse(m.group(2)!),
        nodeId: m.group(3)!,
      ),
    );
  }

  /// Next local timestamp after [last] at physical time [nowMillis].
  ///
  /// [CounterOverflow] if more than [maxCounter] events share one wall
  /// millisecond.
  static Result<Hlc, HlcError> send(Hlc last, int nowMillis) =>
      _next(last, last.wallMillis, last.counter, nowMillis);

  /// Merges [remote] into [local] at physical time [nowMillis].
  ///
  /// [ClockDrift] if the remote wall is more than [maxDriftMillis] ahead of
  /// [nowMillis]; nothing is adopted then. [CounterOverflow] as for [send].
  /// The result keeps [local]'s node id.
  static Result<Hlc, HlcError> receive(
    Hlc local,
    Hlc remote,
    int nowMillis, {
    int maxDriftMillis = defaultMaxDriftMillis,
  }) {
    if (remote.wallMillis - nowMillis > maxDriftMillis) {
      return Err(
        ClockDrift(remoteWallMillis: remote.wallMillis, nowMillis: nowMillis),
      );
    }
    final wall = _max(local.wallMillis, remote.wallMillis);
    final base = wall == local.wallMillis && wall == remote.wallMillis
        ? _max(local.counter, remote.counter)
        : wall == local.wallMillis
        ? local.counter
        : remote.counter;
    return _next(local, wall, base, nowMillis);
  }

  /// Shared tail of send/receive: the wall becomes `max(wall, now)`; the
  /// counter resets when now is ahead, else continues from [counter] + 1.
  static Result<Hlc, HlcError> _next(
    Hlc node,
    int wall,
    int counter,
    int nowMillis,
  ) {
    if (nowMillis > wall) {
      return Ok(Hlc(wallMillis: nowMillis, counter: 0, nodeId: node.nodeId));
    }
    if (counter >= maxCounter) return const Err(CounterOverflow());
    return Ok(Hlc(wallMillis: wall, counter: counter + 1, nodeId: node.nodeId));
  }

  static int _max(int a, int b) => a > b ? a : b;

  /// Wall, then counter, then node id.
  @override
  int compareTo(Hlc other) {
    final w = wallMillis.compareTo(other.wallMillis);
    if (w != 0) return w;
    final c = counter.compareTo(other.counter);
    if (c != 0) return c;
    return nodeId.compareTo(other.nodeId);
  }

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      other.wallMillis == wallMillis &&
      other.counter == counter &&
      other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash(wallMillis, counter, nodeId);

  @override
  String toString() {
    final iso = DateTime.fromMillisecondsSinceEpoch(
      wallMillis,
      isUtc: true,
    ).toIso8601String();
    return '$iso-${counter.toString().padLeft(4, '0')}-$nodeId';
  }
}
