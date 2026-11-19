import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';

/// `ext.mitlio.group.removeConnection {groupId, memberId}` (key without the
/// `ext.mitlio.` prefix): the owner's "Verbindung trennen" without the undo
/// window, the same `GroupDetailViewModel` command the snack bar commits.
/// `group.connectMe {groupId, memberId}` is "Das bin ich". Both answer
/// `{ok: true}` or `{error, message}` (the case name and the German words the
/// app shows).
Map<String, DriveHandler> connectionsDriveHandlers(ProviderContainer c) => {
  'group.removeConnection': (p) async {
    final (groupId, memberId) = (p['groupId'], p['memberId']);
    if (groupId == null || memberId == null) {
      return invalidParams('need groupId, memberId');
    }
    final vm = c.read(groupDetailViewModelProvider(groupId).notifier);
    final problem = await vm.disconnectNow(memberId);
    return problem == null
        ? {'ok': true}
        : {
            'error': problem.error.caseName,
            'message': problem.text(AppLocalizationsDe()),
          };
  },
  'group.connectMe': (p) async {
    final (groupId, memberId) = (p['groupId'], p['memberId']);
    if (groupId == null || memberId == null) {
      return invalidParams('need groupId, memberId');
    }
    // The people must be loaded for the command to know who is who.
    final sub = c.listen(groupDetailViewModelProvider(groupId), (_, _) {});
    try {
      await Future<void>.delayed(Duration.zero);
      final vm = c.read(groupDetailViewModelProvider(groupId).notifier);
      final problem = await vm.connectMe(memberId);
      return problem == null
          ? {'ok': true}
          : {
              'error': problem.error.caseName,
              'message': problem.text(AppLocalizationsDe()),
            };
    } finally {
      sub.close();
    }
  },
};
