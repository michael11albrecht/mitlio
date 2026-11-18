// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/remote/remote_error.dart';

/// What the user sees about syncing one group (P6-T10). Views turn
/// [SyncError] into words with `remoteErrorText`; nothing is only in a log.
sealed class SyncStatus {
  const SyncStatus();
}

/// Everything is uploaded (or the group is local only).
final class SyncIdle extends SyncStatus {
  const SyncIdle();

  @override
  bool operator ==(Object other) => other is SyncIdle;

  @override
  int get hashCode => (SyncIdle).hashCode;

  @override
  String toString() => 'SyncIdle()';
}

/// A push is running.
final class SyncSyncing extends SyncStatus {
  const SyncSyncing();

  @override
  bool operator ==(Object other) => other is SyncSyncing;

  @override
  int get hashCode => (SyncSyncing).hashCode;

  @override
  String toString() => 'SyncSyncing()';
}

/// [count] changes wait to be uploaded.
final class SyncPending extends SyncStatus {
  const SyncPending(this.count);

  final int count;

  @override
  bool operator ==(Object other) =>
      other is SyncPending && other.count == count;

  @override
  int get hashCode => Object.hash(SyncPending, count);

  @override
  String toString() => 'SyncPending($count)';
}

/// The last push failed or the server refused something. [title] names the
/// refused entry (an expense title) for [Rejected].
final class SyncError extends SyncStatus {
  const SyncError(this.error, {this.title});

  final RemoteError error;
  final String? title;

  @override
  bool operator ==(Object other) =>
      other is SyncError && other.error == error && other.title == title;

  @override
  int get hashCode => Object.hash(SyncError, error, title);

  @override
  String toString() => 'SyncError($error, $title)';
}
