import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Plain, du-form words for a failed backend call: what happened and what to
/// do next (ADR-27 §3, "No silent errors"). [personName] fills the person
/// cases, [title] the rejected entry (e.g. the expense title).
String remoteErrorText(
  AppLocalizations l10n,
  RemoteError error, {
  String? personName,
  String? title,
}) => switch (error) {
  Offline() => l10n.remoteErrorOffline,
  RateLimitedRemote(:final wait) =>
    wait == null
        ? l10n.remoteErrorRateLimited
        : l10n.remoteErrorRateLimitedIn(_minutes(wait)),
  InviteInvalid() => l10n.remoteErrorInviteInvalid,
  MemberAlreadyClaimed() =>
    personName == null
        ? l10n.remoteErrorMemberAlreadyClaimedNoName
        : l10n.remoteErrorMemberAlreadyClaimed(personName),
  AlreadyConnected() =>
    personName == null
        ? l10n.remoteErrorAlreadyConnectedNoName
        : l10n.remoteErrorAlreadyConnected(personName),
  MemberGone() => l10n.remoteErrorMemberGone,
  NotOwner() => l10n.remoteErrorNotOwner,
  NotMember() => l10n.remoteErrorNotMember,
  CannotRemoveSelf() => l10n.remoteErrorCannotRemoveSelf,
  VersionTooOld() => l10n.remoteErrorVersionTooOld,
  ServerDown() => l10n.remoteErrorServerDown,
  PullFailed() => l10n.remoteErrorPullFailed,
  Rejected() =>
    title == null
        ? l10n.remoteErrorRejectedNoTitle
        : l10n.remoteErrorRejected(title),
};

/// Rounds up so "in 0 Min." is never shown.
int _minutes(Duration d) => d.inMinutes < 1 ? 1 : d.inMinutes;
