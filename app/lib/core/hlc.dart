import 'package:mitlio/core/clock.dart';
import 'package:mitlio_domain/mitlio_domain.dart' as domain;

/// Process-wide hybrid logical clock for `updated_at` (plan §2.4), backed by
/// the domain `Hlc`.
///
/// Format: `<ISO8601 UTC ms>-<counter 4 digits>-<nodeId>`, e.g.
/// `2026-01-01T00:00:00.000Z-0000-local`. Strings sort lexicographically in
/// causal order within one process: the physical part never goes backwards
/// (a stalled or rewound [Clock] bumps the counter instead).
///
/// The last timestamp lives in memory only.
// TODO(P6-T09): per-install node id (persisted) and `domain.Hlc.receive` on
// pull; needs a settings table, so not part of P6-T08 (no schema change).
abstract final class Hlc {
  static const _nodeId = 'local';
  static domain.Hlc _last = domain.Hlc(
    wallMillis: 0,
    counter: 0,
    nodeId: _nodeId,
  );

  /// Next monotonic timestamp for [clock].
  static String now(Clock clock) {
    final ms = clock.now().toUtc().millisecondsSinceEpoch;
    var next = domain.Hlc.send(_last, ms);
    if (next is domain.Err<domain.Hlc, domain.HlcError>) {
      // Counter exhausted within this millisecond: borrow the next one.
      next = domain.Hlc.send(_last, _last.wallMillis + 1);
    }
    _last = (next as domain.Ok<domain.Hlc, domain.HlcError>).value;
    return _last.toString();
  }

  /// Forgets process state. Tests only.
  static void debugReset() {
    _last = domain.Hlc(wallMillis: 0, counter: 0, nodeId: _nodeId);
  }
}
