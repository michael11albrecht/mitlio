import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/features/sync/data/repositories/share_error_text.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/ui/share_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Plain, du-form words for a missing link: what happened and what to do next
/// (plan §2.6 #9, ADR-27 §3).
String shareFailureText(AppLocalizations l10n, ShareFailure failure) =>
    switch (failure) {
      ShareFailureUpload(:final error) => shareErrorText(l10n, error),
      ShareFailureUnfinished(:final uploaded, :final total) =>
        l10n.shareUploadPartial(uploaded, total),
      ShareFailureLink(:final failure) => shareLinkFailureText(l10n, failure),
    };

String shareLinkFailureText(AppLocalizations l10n, ShareLinkFailure failure) =>
    switch (failure) {
      LinkRemoteFailure(:final error) => remoteErrorText(l10n, error),
      LinkNotKnownToMember() => l10n.inviteNoLinkMember,
      LinkRotated() => l10n.inviteLinkRotated,
      LinkStoreUnreadable() => l10n.inviteStoreUnreadable,
    };
