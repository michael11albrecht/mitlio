// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio/features/settle/data/services/share_service.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Characters of the token DebugDrive and the sheet may show.
const _shownTokenChars = 4;

/// The invite link of a group. The token is a secret: [toString] and
/// [shortUrl] never contain more than a short prefix.
class ShareLink {
  const ShareLink({
    required this.token,
    required this.siteUrl,
    this.saved = true,
  });

  final String token;
  final String siteUrl;

  /// False when the link could not be kept in secure storage: it works now,
  /// but the app cannot show it again later.
  final bool saved;

  /// `https://mitlio.de/join/<token>` (ADR-17, plan P6-T14).
  String get url => '$siteUrl/join/$token';

  /// For display: without scheme, the token cut after a few characters.
  String get shortUrl {
    final host = siteUrl.replaceFirst(RegExp('^https?://'), '');
    final n = token.length < _shownTokenChars ? token.length : _shownTokenChars;
    return '$host/join/${token.substring(0, n)}…';
  }

  @override
  bool operator ==(Object other) =>
      other is ShareLink &&
      other.token == token &&
      other.siteUrl == siteUrl &&
      other.saved == saved;

  @override
  int get hashCode => Object.hash(token, siteUrl, saved);

  @override
  String toString() => 'ShareLink($shortUrl)';
}

/// Why there is no link to show (plain words in `ShareFailureLink.text`).
sealed class ShareLinkFailure {
  const ShareLinkFailure();
}

/// The server call failed.
final class LinkRemoteFailure extends ShareLinkFailure {
  const LinkRemoteFailure(this.error);

  final RemoteError error;

  @override
  bool operator ==(Object other) =>
      other is LinkRemoteFailure && other.error == error;

  @override
  int get hashCode => Object.hash(LinkRemoteFailure, error);

  @override
  String toString() => 'LinkRemoteFailure($error)';
}

/// A member (not the owner) has no stored link: only the owner can make one.
final class LinkNotKnownToMember extends ShareLinkFailure {
  const LinkNotKnownToMember();

  @override
  bool operator ==(Object other) => other is LinkNotKnownToMember;

  @override
  int get hashCode => (LinkNotKnownToMember).hashCode;

  @override
  String toString() => 'LinkNotKnownToMember()';
}

/// A member's stored link was replaced by the owner ("Neuen Link erstellen").
final class LinkRotated extends ShareLinkFailure {
  const LinkRotated();

  @override
  bool operator ==(Object other) => other is LinkRotated;

  @override
  int get hashCode => (LinkRotated).hashCode;

  @override
  String toString() => 'LinkRotated()';
}

/// The secure storage did not hand the stored link back. The owner's link is
/// not replaced on its own: that would silently kill the one already sent.
final class LinkStoreUnreadable extends ShareLinkFailure {
  const LinkStoreUnreadable();

  @override
  bool operator ==(Object other) => other is LinkStoreUnreadable;

  @override
  int get hashCode => (LinkStoreUnreadable).hashCode;

  @override
  String toString() => 'LinkStoreUnreadable()';
}

/// The invite link of a shared group (P6-T14a, ADR-24 §3).
///
/// `create_invite` always rotates and the server keeps only a hash, so the
/// app keeps the token it created or joined with, per group, in secure
/// storage and shows it again instead of calling `create_invite` on every
/// open. Only "Neuen Link erstellen" ([rotate]) makes a new one.
class ShareLinkRepository {
  ShareLinkRepository({
    required this._remote,
    required this._auth,
    required this._secrets,
    required this._logger,
    required this._share,
    required this._siteUrl,
  });

  final InviteRemote _remote;
  final AuthRepository _auth;
  final SecretStore _secrets;
  final Logger _logger;
  final ShareService _share;
  final String _siteUrl;

  /// Hands [text] (the invitation) to the system share sheet.
  Future<void> shareText(String text) => _share.shareText(text);

  static String _key(String groupId) => 'mitlio.invite.$groupId';

  /// Keeps the token a joiner arrived with, so they can pass the link on
  /// (join flow, #165). False when the secure storage refused.
  Future<bool> saveToken(String groupId, String token) async {
    try {
      await _secrets.write(_key(groupId), token);
      return true;
    } on Object catch (e, st) {
      _logger.warn('invite link not saved', e, st);
      return false;
    }
  }

  /// Forgets the stored link (the group was left or deleted). Throws when the
  /// secure storage refuses, so the caller can tell the user.
  Future<void> forget(String groupId) => _secrets.delete(_key(groupId));

  /// The link to show: the stored one, or for the owner a new one when there
  /// is none yet. A member's stored link is checked against the server first
  /// ([LinkRotated]).
  Future<Result<ShareLink, ShareLinkFailure>> link(
    String groupId, {
    required bool isOwner,
  }) async {
    final String? stored;
    try {
      stored = await _secrets.read(_key(groupId));
    } on Object catch (e, st) {
      _logger.warn('invite link not readable', e, st);
      return const Err(LinkStoreUnreadable());
    }
    if (stored == null) {
      return isOwner ? _create(groupId) : const Err(LinkNotKnownToMember());
    }
    if (!isOwner) {
      final current = await _remote.isCurrentLink(groupId, stored);
      switch (current) {
        case Err(:final error):
          return Err(LinkRemoteFailure(error));
        case Ok(value: false):
          await _forgetQuietly(groupId);
          return const Err(LinkRotated());
        case Ok():
          break;
      }
    }
    return Ok(ShareLink(token: stored, siteUrl: _siteUrl));
  }

  /// Owner: a new link; the old one stops working at once.
  Future<Result<ShareLink, ShareLinkFailure>> rotate(String groupId) =>
      _create(groupId);

  Future<Result<ShareLink, ShareLinkFailure>> _create(String groupId) async {
    final signedIn = await _auth.ensureSignedIn();
    if (signedIn case Err(:final error)) return Err(LinkRemoteFailure(error));
    final created = await _remote.createInvite(groupId);
    switch (created) {
      case Err(:final error):
        return Err(LinkRemoteFailure(error));
      case Ok(:final value):
        final saved = await saveToken(groupId, value);
        return Ok(ShareLink(token: value, siteUrl: _siteUrl, saved: saved));
    }
  }

  Future<void> _forgetQuietly(String groupId) async {
    try {
      await _secrets.delete(_key(groupId));
    } on Object catch (e, st) {
      // The stale link is re-checked (and refused) on the next open.
      _logger.warn('stale invite link not deleted', e, st);
    }
  }
}
