// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/sync/data/repositories/share_error_text.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Why the share sheet has no link (plain words in [text]).
sealed class ShareFailure {
  const ShareFailure();

  /// Du-form words: what happened and what to do next (plan §2.6 #9).
  String text(AppLocalizations l10n);
}

/// Turning the local group into a shared one failed (P6-T15).
final class ShareFailureUpload extends ShareFailure {
  const ShareFailureUpload(this.error);

  final ShareError error;

  @override
  String text(AppLocalizations l10n) => shareErrorText(l10n, error);

  @override
  bool operator ==(Object other) =>
      other is ShareFailureUpload && other.error == error;

  @override
  int get hashCode => Object.hash(ShareFailureUpload, error);
}

/// The upload is still running ([uploaded] of [total]) without an error:
/// the link comes once the group is on the server.
final class ShareFailureUnfinished extends ShareFailure {
  const ShareFailureUnfinished(this.uploaded, this.total);

  final int uploaded;
  final int total;

  @override
  String text(AppLocalizations l10n) =>
      l10n.shareUploadPartial(uploaded, total);

  @override
  bool operator ==(Object other) =>
      other is ShareFailureUnfinished &&
      other.uploaded == uploaded &&
      other.total == total;

  @override
  int get hashCode => Object.hash(ShareFailureUnfinished, uploaded, total);
}

/// The group is shared, but there is no link to show.
final class ShareFailureLink extends ShareFailure {
  const ShareFailureLink(this.failure);

  final ShareLinkFailure failure;

  @override
  String text(AppLocalizations l10n) => switch (failure) {
    LinkRemoteFailure(:final error) => remoteErrorText(l10n, error),
    LinkNotKnownToMember() => l10n.inviteNoLinkMember,
    LinkRotated() => l10n.inviteLinkRotated,
    LinkStoreUnreadable() => l10n.inviteStoreUnreadable,
  };

  @override
  bool operator ==(Object other) =>
      other is ShareFailureLink && other.failure == failure;

  @override
  int get hashCode => Object.hash(ShareFailureLink, failure);
}

sealed class ShareState {
  const ShareState();
}

/// Preparing the link (sharing the group first, when it was local only).
final class ShareLoading extends ShareState {
  const ShareLoading();
}

final class ShareFailed extends ShareState {
  const ShareFailed(this.failure);

  final ShareFailure failure;
}

/// The link to show.
final class ShareReady extends ShareState {
  const ShareReady({
    required this.link,
    required this.groupName,
    required this.isOwner,
    this.confirmingRotate = false,
    this.rotating = false,
    this.rotateError,
  });

  final ShareLink link;
  final String groupName;

  /// Only the owner may make a new link.
  final bool isOwner;

  /// The inline second step ("Der alte Link funktioniert dann nicht mehr.").
  final bool confirmingRotate;
  final bool rotating;

  /// Why the last "Neuen Link erstellen" failed; the old link still works.
  final ShareFailure? rotateError;

  ShareReady copyWith({
    ShareLink? link,
    bool? confirmingRotate,
    bool? rotating,
    ShareFailure? rotateError,
    bool clearRotateError = false,
  }) => ShareReady(
    link: link ?? this.link,
    groupName: groupName,
    isOwner: isOwner,
    confirmingRotate: confirmingRotate ?? this.confirmingRotate,
    rotating: rotating ?? this.rotating,
    rotateError: clearRotateError ? null : rotateError ?? this.rotateError,
  );
}

/// "Gruppe teilen": link and QR of one group (P6-T14a, ADR-24 §3). A local
/// group is shared first ([ShareGroupRepository.makeShared]); then the stored
/// link, or a new one for the owner when there is none. Every user action is a
/// command here; DebugDrive calls the same ones.
class ShareViewModel extends Notifier<ShareState> {
  ShareViewModel(this.groupId);

  final String groupId;

  var _running = false;

  @override
  ShareState build() => const ShareLoading();

  /// Prepares the link. Safe to call again (retry); ignored while running.
  Future<void> share() async {
    if (_running) return;
    _running = true;
    try {
      state = const ShareLoading();
      state = await _prepare();
    } finally {
      _running = false;
    }
  }

  Future<ShareState> _prepare() async {
    final sync = ref.read(syncStateRepositoryProvider);
    var snap = await sync.snapshot(groupId);
    if (snap.state == SyncState.removed) {
      return const ShareFailed(ShareFailureUpload(ShareGroupRemoved()));
    }
    if (snap.state != SyncState.shared) {
      final shared = await ref
          .read(shareGroupRepositoryProvider)
          .makeShared(groupId);
      switch (shared) {
        case Err(:final error):
          return ShareFailed(ShareFailureUpload(error));
        case Ok(:final value) when value.state != SyncState.shared:
          return ShareFailed(
            ShareFailureUnfinished(value.uploaded, value.total),
          );
        case Ok():
          break;
      }
      snap = await sync.snapshot(groupId);
    }
    final isOwner = snap.role == SyncRole.owner;
    final link = await ref
        .read(shareLinkRepositoryProvider)
        .link(groupId, isOwner: isOwner);
    return switch (link) {
      Err(:final error) => ShareFailed(ShareFailureLink(error)),
      Ok(:final value) => ShareReady(
        link: value,
        groupName: await _groupName(),
        isOwner: isOwner,
      ),
    };
  }

  Future<String> _groupName() async {
    final group = await ref.read(groupsRepositoryProvider).get(groupId);
    return switch (group) {
      Ok(:final value) => value.name,
      Err() => '',
    };
  }

  /// First step of "Neuen Link erstellen": shows the inline warning.
  void askRotate() {
    final s = state;
    if (s is ShareReady && s.isOwner && !s.rotating) {
      state = s.copyWith(confirmingRotate: true, clearRotateError: true);
    }
  }

  void cancelRotate() {
    final s = state;
    if (s is ShareReady && !s.rotating) {
      state = s.copyWith(confirmingRotate: false);
    }
  }

  /// Second step: makes the new link; the old one stops working at once.
  Future<void> confirmRotate() async {
    final s = state;
    if (s is! ShareReady || !s.isOwner || s.rotating) return;
    state = s.copyWith(rotating: true, clearRotateError: true);
    final result = await ref.read(shareLinkRepositoryProvider).rotate(groupId);
    state = switch (result) {
      Ok(:final value) => s.copyWith(
        link: value,
        confirmingRotate: false,
        rotating: false,
        clearRotateError: true,
      ),
      Err(:final error) => s.copyWith(
        rotating: false,
        rotateError: ShareFailureLink(error),
      ),
    };
  }

  /// Opens the system share sheet with the invitation text. Err: it did not
  /// open (the view says so).
  Future<Result<void, Object>> shareLink(AppLocalizations l10n) async {
    final s = state;
    if (s is! ShareReady) return const Ok(null);
    try {
      await ref
          .read(shareLinkRepositoryProvider)
          .shareText(l10n.inviteShareText(s.groupName, s.link.url));
      return const Ok(null);
    } on Object catch (e) {
      return Err(e);
    }
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final shareViewModelProvider = NotifierProvider.autoDispose
    .family<ShareViewModel, ShareState, String>(ShareViewModel.new);

/// Whether the share entry is shown at all: not without a backend.
final shareAvailableProvider = Provider<bool>(
  (ref) => ref.watch(remoteBackendProvider).isAvailable,
);
