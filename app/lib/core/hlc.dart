import 'package:mitlio/core/clock.dart';

/// Hybrid logical clock stub for `updated_at` (plan §2.4).
///
/// Format: `<ISO8601 UTC ms>-<counter 4 digits>-<nodeId>`, e.g.
/// `2026-01-01T00:00:00.000Z-0000-local`. Strings sort lexicographically in
/// causal order within one process: the physical part never goes backwards
/// (a stalled or rewound [Clock] bumps the counter instead).
///
/// P6 replaces this with the full HLC (`Hlc.receive`, per-device node id).
abstract final class Hlc {
  static const _nodeId = 'local';
  static const _maxCounter = 9999;
  static int _lastMs = 0;
  static int _counter = 0;

  /// Next monotonic timestamp for [clock].
  static String now(Clock clock) {
    final ms = clock.now().toUtc().millisecondsSinceEpoch;
    if (ms > _lastMs) {
      _lastMs = ms;
      _counter = 0;
    } else if (_counter < _maxCounter) {
      _counter++;
    } else {
      _lastMs++;
      _counter = 0;
    }
    final iso = DateTime.fromMillisecondsSinceEpoch(
      _lastMs,
      isUtc: true,
    ).toIso8601String();
    return '$iso-${_counter.toString().padLeft(4, '0')}-$_nodeId';
  }

  /// Forgets process state. Tests only.
  static void debugReset() {
    _lastMs = 0;
    _counter = 0;
  }
}
