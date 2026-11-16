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
/// The last timestamp lives in memory only. The node id is per install: `main`
/// reads (or creates) it from `local_settings` and passes it to [init] before
/// anything writes; nothing here does I/O. Without [init] (tests) the node id
/// is [defaultNodeId].
abstract final class Hlc {
  /// Node id used until [init] runs. Tests only: a shipped build always calls
  /// [init], otherwise every install would share one node id.
  static const defaultNodeId = 'local';

  static domain.Hlc _last = domain.Hlc(
    wallMillis: 0,
    counter: 0,
    nodeId: defaultNodeId,
  );

  /// Sets this install's [nodeId] and restarts the clock from zero. Call once
  /// at startup, before the first write.
  static void init(String nodeId) {
    _last = domain.Hlc(wallMillis: 0, counter: 0, nodeId: nodeId);
  }

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

  /// Merges a [remote] timestamp seen on pull into the local clock, so the
  /// next [now] is later than it. Returns the new local timestamp.
  ///
  /// Errors are returned, never swallowed, and leave the local clock
  /// untouched:
  /// - `HlcInvalidFormat`: [remote] is not a timestamp.
  /// - `ClockDrift`: the remote wall is more than a minute ahead of [clock].
  ///   Adopting it would push every later local write that far into the
  ///   future, so the clock stays as it is. The caller still applies the row
  ///   by last-write-wins and reports the drift.
  static domain.Result<String, domain.HlcError> receive(
    String remote,
    Clock clock,
  ) {
    final parsed = domain.Hlc.parse(remote);
    if (parsed is domain.Err<domain.Hlc, domain.HlcError>) {
      return domain.Err(parsed.error);
    }
    final remoteHlc = (parsed as domain.Ok<domain.Hlc, domain.HlcError>).value;
    final ms = clock.now().toUtc().millisecondsSinceEpoch;
    var next = domain.Hlc.receive(_last, remoteHlc, ms);
    if (next is domain.Err<domain.Hlc, domain.HlcError> &&
        next.error is domain.CounterOverflow) {
      // Counter exhausted within this millisecond: borrow the next one.
      final wall = _last.wallMillis > remoteHlc.wallMillis
          ? _last.wallMillis
          : remoteHlc.wallMillis;
      next = domain.Hlc.receive(_last, remoteHlc, (wall > ms ? wall : ms) + 1);
    }
    if (next is domain.Ok<domain.Hlc, domain.HlcError>) {
      _last = next.value;
      return domain.Ok(_last.toString());
    }
    return domain.Err((next as domain.Err<domain.Hlc, domain.HlcError>).error);
  }

  /// Forgets process state. Tests only.
  static void debugReset() {
    _last = domain.Hlc(wallMillis: 0, counter: 0, nodeId: defaultNodeId);
  }
}
