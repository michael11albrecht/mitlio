// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/sync/hlc.dart';

/// The version of one aggregate root as seen by sync: its last-write HLC and
/// whether that write was a delete (tombstone).
///
/// A tombstone is a version like any other (ADR-07): pure last-write-wins on
/// [updatedAt], so a newer restore beats an older delete and vice versa.
final class SyncVersion {
  /// Creates a version. [deletedAt] is non-null for a tombstone.
  const SyncVersion({required this.updatedAt, this.deletedAt});

  final Hlc updatedAt;
  final DateTime? deletedAt;

  /// Whether this version is a delete.
  bool get isTombstone => deletedAt != null;

  @override
  bool operator ==(Object other) =>
      other is SyncVersion &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(updatedAt, deletedAt);

  @override
  String toString() => 'SyncVersion($updatedAt, deletedAt: $deletedAt)';
}

/// What pull does with one remote aggregate.
enum MergeDecision {
  /// Replace the local aggregate (root and children as a unit) by the remote.
  applyRemote,

  /// Local is newer, or an unpushed local op is newer: keep local.
  keepLocal,

  /// Identical version (replay): nothing to do.
  same,

  /// Apply the remote and delete the pending outbox op (it lost).
  applyRemoteDropPending,
}

/// Decides which version of an aggregate wins.
///
/// - [pendingLocal] (an unpushed outbox op) strictly newer than the remote:
///   [MergeDecision.keepLocal], the push will win. Otherwise the remote wins
///   and the pending op is dropped: [MergeDecision.applyRemoteDropPending].
/// - Without pending: no [local] row or a higher remote HLC is
///   [MergeDecision.applyRemote]; a lower one [MergeDecision.keepLocal]; an
///   equal HLC [MergeDecision.same].
MergeDecision decide({
  required SyncVersion remote,
  SyncVersion? local,
  Hlc? pendingLocal,
}) {
  if (pendingLocal != null) {
    return pendingLocal.compareTo(remote.updatedAt) > 0
        ? MergeDecision.keepLocal
        : MergeDecision.applyRemoteDropPending;
  }
  if (local == null) return MergeDecision.applyRemote;
  final c = remote.updatedAt.compareTo(local.updatedAt);
  if (c > 0) return MergeDecision.applyRemote;
  if (c < 0) return MergeDecision.keepLocal;
  return MergeDecision.same;
}

/// Result of [mergeAggregate].
final class MergeResult<T> {
  /// Creates a result.
  const MergeResult(this.decision, this.winner);

  final MergeDecision decision;

  /// The aggregate to hold after the merge (root with its children).
  final T winner;
}

/// [decide] on whole aggregates: children follow the root decision and are
/// replaced as a unit, so [MergeResult.winner] is either [remote] or [local]
/// untouched, never a mix.
MergeResult<T> mergeAggregate<T>({
  required T remote,
  required SyncVersion Function(T) versionOf,
  T? local,
  Hlc? pendingLocal,
}) {
  final d = decide(
    local: local == null ? null : versionOf(local),
    remote: versionOf(remote),
    pendingLocal: pendingLocal,
  );
  final keep = d == MergeDecision.keepLocal || d == MergeDecision.same;
  // A pending op without a local row cannot exist in practice; if it does,
  // the remote is the only aggregate we hold.
  return MergeResult(d, keep ? (local ?? remote) : remote);
}
