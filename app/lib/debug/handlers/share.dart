import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/ui/share_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.group.share` (key without the `ext.mitlio.` prefix): the same
/// `ShareGroupRepository.makeShared` the share sheet calls. `group.invite` and
/// `group.rotateInvite` run the `ShareViewModel` commands of the sheet. The
/// invite token is a secret: only the shortened link is reported.
Map<String, DriveHandler> shareDriveHandlers(ProviderContainer c) => {
  'group.share': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final result = await c
        .read(shareGroupRepositoryProvider)
        .makeShared(
          groupId,
        );
    return switch (result) {
      Ok(:final value) => {
        'state': value.state.name,
        'uploaded': value.uploaded,
        'total': value.total,
      },
      Err(error: ShareGroupMissing()) => {
        'error': 'not_found',
        'message': 'group $groupId is not on this phone',
      },
      Err(error: ShareGroupRemoved()) => {
        'error': 'notMember',
        'message': 'this phone was removed from the group',
      },
      Err(:final error as ShareUploadFailed) => {
        'error': error.error.caseName,
        'message': '${error.error}',
        'uploaded': error.uploaded,
        'total': error.total,
      },
    };
  },
  'group.invite': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    return _withShare(c, groupId, (vm) => vm.share());
  },
  'group.rotateInvite': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    return _withShare(c, groupId, (vm) async {
      await vm.share();
      vm.askRotate();
      await vm.confirmRotate();
    });
  },
};

/// Runs [command] on the view model of [groupId] and reports its state. The
/// subscription keeps the auto-disposed notifier alive meanwhile.
Future<Map<String, Object?>> _withShare(
  ProviderContainer c,
  String groupId,
  Future<void> Function(ShareViewModel vm) command,
) async {
  final provider = shareViewModelProvider(groupId);
  final sub = c.listen(provider, (_, _) {});
  try {
    await command(c.read(provider.notifier));
    return switch (c.read(provider)) {
      ShareReady(:final link, :final isOwner, :final rotateError) => {
        if (rotateError != null) ..._linkError(rotateError),
        'link': link.shortUrl,
        'isOwner': isOwner,
        'saved': link.saved,
      },
      ShareFailed(:final failure) => _failure(failure),
      ShareLoading() => {'error': 'loading', 'message': 'still preparing'},
    };
  } finally {
    sub.close();
  }
}

Map<String, Object?> _failure(ShareFailure failure) => switch (failure) {
  ShareFailureUpload(error: final ShareUploadFailed e) => {
    'error': e.error.caseName,
    'message': '${e.error}',
    'uploaded': e.uploaded,
    'total': e.total,
  },
  ShareFailureUpload(error: ShareGroupMissing()) => {
    'error': 'not_found',
    'message': 'group is not on this phone',
  },
  ShareFailureUpload(error: ShareGroupRemoved()) => {
    'error': 'notMember',
    'message': 'this phone was removed from the group',
  },
  ShareFailureUnfinished(:final uploaded, :final total) => {
    'error': 'uploading',
    'uploaded': uploaded,
    'total': total,
  },
  ShareFailureLink(:final failure) => _linkError(failure),
};

Map<String, Object?> _linkError(ShareLinkFailure failure) => switch (failure) {
  LinkRemoteFailure(:final error) => {
    'error': error.caseName,
    'message': '$error',
  },
  LinkNotKnownToMember() => {
    'error': 'linkNotKnown',
    'message': 'no link saved on this phone; ask the owner',
  },
  LinkRotated() => {
    'error': 'linkRotated',
    'message': 'the owner replaced the link',
  },
  LinkStoreUnreadable() => {
    'error': 'storeUnreadable',
    'message': 'secure storage did not return the link',
  },
};
