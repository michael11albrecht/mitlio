/// Invite links opened from outside the app (P6-T14c). The token is a secret:
/// nothing here logs it.
library;

final _tokenShape = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// Whether [token] has the shape the server hands out (32 random bytes,
/// base64url, 43 characters). Anything else cannot be a live invite, so the
/// app says so without asking the server.
bool isInviteToken(String token) => _tokenShape.hasMatch(token);

/// The route for a `mitlio://join/<token>` link, or null for any other link
/// (the https app link `https://<domain>/join/<token>` already matches the
/// `/join/:token` route). A link of the wrong shape still goes to the join
/// screen, with a token that is refused there.
String? inviteLocationFor(Uri uri) {
  if (uri.scheme != 'mitlio' || uri.host != 'join') return null;
  final segments = uri.pathSegments;
  final token = segments.length == 1 && segments.single.isNotEmpty
      ? segments.single
      : 'invalid';
  return '/join/${Uri.encodeComponent(token)}';
}
