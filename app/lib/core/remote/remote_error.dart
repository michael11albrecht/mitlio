// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// Why a call to the backend failed (ADR-27 §3). One case per server signal;
/// every case has a du-form message and a next step in `remote_error_text`.
/// Nothing outside `core/remote` inspects Supabase exceptions.
sealed class RemoteError {
  const RemoteError();
}

/// No connection or timeout: the server never answered.
final class Offline extends RemoteError {
  const Offline();

  @override
  bool operator ==(Object other) => other is Offline;

  @override
  int get hashCode => (Offline).hashCode;

  @override
  String toString() => 'Offline()';
}

/// Too many calls. [wait] is the server's hint, when it sent one.
final class RateLimitedRemote extends RemoteError {
  const RateLimitedRemote(this.wait);

  final Duration? wait;

  @override
  bool operator ==(Object other) =>
      other is RateLimitedRemote && other.wait == wait;

  @override
  int get hashCode => Object.hash(RateLimitedRemote, wait);

  @override
  String toString() => 'RateLimitedRemote($wait)';
}

/// The invite link is invalid, expired or revoked (deliberately one case).
final class InviteInvalid extends RemoteError {
  const InviteInvalid();

  @override
  bool operator ==(Object other) => other is InviteInvalid;

  @override
  int get hashCode => (InviteInvalid).hashCode;

  @override
  String toString() => 'InviteInvalid()';
}

/// The chosen person is already connected to another account.
final class MemberAlreadyClaimed extends RemoteError {
  const MemberAlreadyClaimed();

  @override
  bool operator ==(Object other) => other is MemberAlreadyClaimed;

  @override
  int get hashCode => (MemberAlreadyClaimed).hashCode;

  @override
  String toString() => 'MemberAlreadyClaimed()';
}

/// This account is already connected to a person in the group.
final class AlreadyConnected extends RemoteError {
  const AlreadyConnected();

  @override
  bool operator ==(Object other) => other is AlreadyConnected;

  @override
  int get hashCode => (AlreadyConnected).hashCode;

  @override
  String toString() => 'AlreadyConnected()';
}

/// The chosen person no longer exists in the group.
final class MemberGone extends RemoteError {
  const MemberGone();

  @override
  bool operator ==(Object other) => other is MemberGone;

  @override
  int get hashCode => (MemberGone).hashCode;

  @override
  String toString() => 'MemberGone()';
}

/// Only the group owner may do this.
final class NotOwner extends RemoteError {
  const NotOwner();

  @override
  bool operator ==(Object other) => other is NotOwner;

  @override
  int get hashCode => (NotOwner).hashCode;

  @override
  String toString() => 'NotOwner()';
}

/// This account is not (or no longer) a member of the group.
final class NotMember extends RemoteError {
  const NotMember();

  @override
  bool operator ==(Object other) => other is NotMember;

  @override
  int get hashCode => (NotMember).hashCode;

  @override
  String toString() => 'NotMember()';
}

/// An owner tried to remove their own membership.
final class CannotRemoveSelf extends RemoteError {
  const CannotRemoveSelf();

  @override
  bool operator ==(Object other) => other is CannotRemoveSelf;

  @override
  int get hashCode => (CannotRemoveSelf).hashCode;

  @override
  String toString() => 'CannotRemoveSelf()';
}

/// The app is older than `min_supported_version`: sharing is blocked.
final class VersionTooOld extends RemoteError {
  const VersionTooOld();

  @override
  bool operator ==(Object other) => other is VersionTooOld;

  @override
  int get hashCode => (VersionTooOld).hashCode;

  @override
  String toString() => 'VersionTooOld()';
}

/// The server answered with a 5xx (or auth is switched off server side).
final class ServerDown extends RemoteError {
  const ServerDown();

  @override
  bool operator ==(Object other) => other is ServerDown;

  @override
  int get hashCode => (ServerDown).hashCode;

  @override
  String toString() => 'ServerDown()';
}

/// The server refused the write for another reason, e.g.
/// `payers_sum_mismatch`. [code] is the stable server code.
final class Rejected extends RemoteError {
  const Rejected(this.code);

  final String code;

  @override
  bool operator ==(Object other) => other is Rejected && other.code == code;

  @override
  int get hashCode => Object.hash(Rejected, code);

  @override
  String toString() => 'Rejected($code)';
}

/// Stable, machine-readable name of the case (ADR-27 §3): what DebugDrive
/// reports and what `local_group_sync.last_error_code` stores. Never shown
/// to users; their text is `remoteErrorText`.
extension RemoteErrorName on RemoteError {
  String get caseName => switch (this) {
    Offline() => 'offline',
    RateLimitedRemote() => 'rateLimited',
    InviteInvalid() => 'inviteInvalid',
    MemberAlreadyClaimed() => 'memberAlreadyClaimed',
    AlreadyConnected() => 'alreadyConnected',
    MemberGone() => 'memberGone',
    NotOwner() => 'notOwner',
    NotMember() => 'notMember',
    CannotRemoveSelf() => 'cannotRemoveSelf',
    VersionTooOld() => 'versionTooOld',
    ServerDown() => 'serverDown',
    Rejected() => 'rejected',
  };
}

/// Inverse of [RemoteErrorName.caseName] for what `local_group_sync` stored:
/// `rejected:<code>` is a [Rejected]; a stored rate limit has lost its wait.
/// An unknown name is shown as a [Rejected] rather than hidden.
RemoteError remoteErrorFromCaseName(String name) {
  const rejectedPrefix = 'rejected:';
  if (name.startsWith(rejectedPrefix)) {
    return Rejected(name.substring(rejectedPrefix.length));
  }
  return switch (name) {
    'offline' => const Offline(),
    'rateLimited' => const RateLimitedRemote(null),
    'inviteInvalid' => const InviteInvalid(),
    'memberAlreadyClaimed' => const MemberAlreadyClaimed(),
    'alreadyConnected' => const AlreadyConnected(),
    'memberGone' => const MemberGone(),
    'notOwner' => const NotOwner(),
    'notMember' => const NotMember(),
    'cannotRemoveSelf' => const CannotRemoveSelf(),
    'versionTooOld' => const VersionTooOld(),
    'serverDown' => const ServerDown(),
    _ => Rejected(name),
  };
}

/// The stable string stored in `last_error_code` and
/// `local_outbox.last_error_code`: [RemoteErrorName.caseName], and for a
/// [Rejected] `rejected:<code>` (ADR-27 §3, P6-T10).
extension RemoteErrorStorage on RemoteError {
  String get storedCode => switch (this) {
    Rejected(:final code) => 'rejected:$code',
    _ => caseName,
  };
}
