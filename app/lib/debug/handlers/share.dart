import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.group.share` (key without the `ext.mitlio.` prefix): the same
/// `ShareGroupRepository.makeShared` the share sheet calls.
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
};
