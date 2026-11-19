// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';

/// The one thing the status line offers next to an error (P6-T12). At most
/// one per state; `offline` and `notMember` offer none.
enum SyncLineAction {
  /// "Nochmal versuchen": sync again now.
  retry,

  /// "Ansehen": a change the server refused; opens the sheet that explains it.
  showRejected,

  /// "Aktualisieren": the app is too old to sync; opens the store page.
  update,
}

/// What the line says, in order of the words.
enum SyncLineKind { upToDate, sending, pending, uploading, error }

sealed class SyncLineState {
  const SyncLineState();
}

/// Local-only group (or still loading): no line at all.
final class SyncLineHidden extends SyncLineState {
  const SyncLineHidden();
}

/// A shared group says honestly how it stands.
final class SyncLineShown extends SyncLineState {
  const SyncLineShown(this.status);

  final SyncStatus status;

  /// For the view, which must not know the data layer.
  SyncLineKind get kind => switch (status) {
    SyncIdle() => SyncLineKind.upToDate,
    SyncSyncing() => SyncLineKind.sending,
    SyncPending() => SyncLineKind.pending,
    SyncUploading() => SyncLineKind.uploading,
    SyncError() => SyncLineKind.error,
  };

  /// Changes waiting ([SyncLineKind.pending]).
  int get pendingCount => switch (status) {
    SyncPending(:final count) => count,
    _ => 0,
  };

  /// Entries still to upload ([SyncLineKind.uploading]); null: unknown.
  int? get remaining => switch (status) {
    SyncUploading(:final remaining) => remaining,
    _ => null,
  };

  /// The failure ([SyncLineKind.error]).
  RemoteError? get error => switch (status) {
    SyncError(:final error) => error,
    _ => null,
  };

  /// The refused entry's title, for a [Rejected] error.
  String? get title => switch (status) {
    SyncError(:final title) => title,
    _ => null,
  };

  /// The action next to the text, if any.
  SyncLineAction? get action => switch (status) {
    SyncError(:final error) => switch (error) {
      ServerDown() ||
      RateLimitedRemote() ||
      PullFailed() => SyncLineAction.retry,
      Rejected() => SyncLineAction.showRejected,
      VersionTooOld() => SyncLineAction.update,
      _ => null,
    },
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is SyncLineShown && other.status == status;

  @override
  int get hashCode => Object.hash(SyncLineShown, status);
}

/// Sync status line of one group. Commands: [retry] and [acknowledge]
/// (clears a refused change after the user has seen it).
class SyncStatusViewModel extends Notifier<SyncLineState> {
  SyncStatusViewModel(this.groupId);

  final String groupId;

  @override
  SyncLineState build() {
    final sub = ref.watch(syncCoordinatorProvider).watchLine(groupId).listen(
      (status) {
        if (!ref.mounted) return;
        state = status == null ? const SyncLineHidden() : SyncLineShown(status);
      },
      // The status itself could not be read (local database failure):
      // reported to the error sink, the last known line stays.
      onError: (Object e, StackTrace s) =>
          ref.read(errorSinkProvider).record(e, s, source: 'sync-status'),
    );
    ref.onDispose(() => unawaited(sub.cancel()));
    return const SyncLineHidden();
  }

  /// "Nochmal versuchen": push and pull now, ignoring a waiting backoff.
  Future<void> retry() =>
      ref.read(syncCoordinatorProvider).syncNow(groupId, force: true);

  /// "Aktualisieren": opens the store page. False when nothing could open it;
  /// the view then says so.
  Future<bool> openStore() => ref.read(versionGateProvider).openStore();

  /// "OK" in the sheet of a refused change.
  Future<void> acknowledge() =>
      ref.read(syncCoordinatorProvider).acknowledge(groupId);

  JsonMap debugSnapshot() => switch (state) {
    SyncLineHidden() => {'groupId': groupId, 'status': 'hidden'},
    SyncLineShown(:final status, :final action) => {
      'groupId': groupId,
      ...syncStatusJson(status),
      'action': action?.name,
    },
  };
}

/// Machine-readable form of a status (DebugDrive): `status` is the case,
/// `error` the stable `RemoteError` case name.
JsonMap syncStatusJson(SyncStatus status) => switch (status) {
  SyncIdle() => {'status': 'idle'},
  SyncSyncing() => {'status': 'syncing'},
  SyncPending(:final count) => {'status': 'pending', 'pending': count},
  SyncUploading(:final remaining) => {
    'status': 'uploading',
    'remaining': remaining,
  },
  SyncError(:final error, :final title) => {
    'status': 'error',
    'error': error.storedCode,
    'title': title,
  },
};

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final syncStatusViewModelProvider =
    NotifierProvider.family<SyncStatusViewModel, SyncLineState, String>(
      SyncStatusViewModel.new,
    );
