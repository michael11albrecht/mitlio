import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Plain, du-form words for a failed share: what happened, the numbers, that
/// this phone is unchanged, and the reason with its next step (plan §2.6 #9).
String shareErrorText(AppLocalizations l10n, ShareError error) =>
    switch (error) {
      ShareGroupMissing() => l10n.shareGroupMissing,
      ShareGroupRemoved() => l10n.remoteErrorNotMember,
      ShareUploadFailed(
        :final uploaded,
        :final total,
        :final error,
        :final title,
      ) =>
        '${l10n.shareUploadPartial(uploaded, total)} '
            '${remoteErrorText(l10n, error, title: title)}',
    };
