import 'dart:async';
import 'dart:io';

import 'package:mitlio/core/remote/remote_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns every backend failure into a [RemoteError] (ADR-27 §3). The only
/// place that looks at Supabase exceptions. Rule: `Offline` only when the
/// server never answered (plan §2.6 #9).

/// SQLSTATE the rate-limit raise uses (migration 0009).
const _rateLimitedState = 'P0429';

/// `hint` of the rate-limit raise: `retry_after_seconds=<n>`.
final _retryAfter = RegExp(r'retry_after_seconds=(\d+)');

/// Maps a PostgREST / RPC failure. Matches the SQLSTATE and the stable
/// message strings raised by migrations 0002, 0003, 0009 and 0010.
RemoteError fromPostgrest({
  String? code,
  String? message,
  String? hint,
  Object? details,
  int? httpStatus,
}) {
  final msg = (message ?? '').trim();
  if (code == _rateLimitedState || httpStatus == 429) {
    return RateLimitedRemote(_parseRetryAfter(hint));
  }
  final known = _byMessage(code, msg);
  if (known != null) return known;
  if (httpStatus != null && httpStatus >= 500) return const ServerDown();
  return Rejected(msg.isNotEmpty ? msg : (code ?? 'unknown'));
}

RemoteError? _byMessage(String? code, String msg) => switch ((code, msg)) {
  ('22023', 'invite_invalid') => const InviteInvalid(),
  ('22023', 'member_not_found') => const MemberGone(),
  ('23505', 'member_already_claimed') => const MemberAlreadyClaimed(),
  ('23514', 'membership_already_linked') => const AlreadyConnected(),
  ('23514', 'cannot remove own membership') => const CannotRemoveSelf(),
  ('42501', 'not the owner of this group') => const NotOwner(),
  ('42501', 'not a member of this group') => const NotMember(),
  _ => null,
};

Duration? _parseRetryAfter(String? hint) {
  final match = hint == null ? null : _retryAfter.firstMatch(hint);
  final seconds = match == null ? null : int.tryParse(match.group(1)!);
  return seconds == null || seconds <= 0 ? null : Duration(seconds: seconds);
}

/// Maps a GoTrue (auth) failure.
RemoteError fromAuth({int? statusCode, String? code}) {
  if (statusCode == 429 ||
      code == 'over_request_rate_limit' ||
      code == 'over_email_send_rate_limit') {
    return const RateLimitedRemote(null);
  }
  if ((statusCode != null && statusCode >= 500) ||
      code == 'anonymous_provider_disabled') {
    return const ServerDown();
  }
  return Rejected(code ?? 'auth_${statusCode ?? 'unknown'}');
}

/// Maps anything a Supabase call can throw.
RemoteError fromException(Object error) => switch (error) {
  PostgrestException() => fromPostgrest(
    code: _isHttpStatus(error.code) ? null : error.code,
    message: error.message,
    hint: error.hint,
    details: error.details,
    httpStatus: _isHttpStatus(error.code) ? int.parse(error.code!) : null,
  ),
  AuthRetryableFetchException(:final statusCode) =>
    statusCode == null
        ? const Offline()
        : fromAuth(statusCode: int.tryParse(statusCode)),
  AuthUnknownException(:final originalError) when originalError is Exception =>
    fromException(originalError),
  AuthException() => fromAuth(
    statusCode: int.tryParse(error.statusCode ?? ''),
    code: error.code,
  ),
  SocketException() ||
  HttpException() ||
  TlsException() ||
  TimeoutException() => const Offline(),
  // package:http `ClientException` (also wraps socket failures on web); it is
  // not importable without a direct dependency, so match by name.
  _ when error.runtimeType.toString() == 'ClientException' => const Offline(),
  _ => const Rejected('unexpected'),
};

/// PostgREST puts the HTTP status in `code` when the body was not JSON.
bool _isHttpStatus(String? code) =>
    code != null && RegExp(r'^\d{3}$').hasMatch(code);

/// True when a write failed only because the server already holds a newer
/// version (the `enforce_lww` trigger, migration 0001). ADR-27 §3: such an op
/// is dropped, the next pull brings the newer row; it is not an error.
bool isStaleWrite({String? code, String? message}) =>
    code == '23514' &&
    (message ?? '').startsWith('updated_at must not go backwards');

/// [isStaleWrite] for a thrown exception.
bool isStaleWriteException(Object error) =>
    error is PostgrestException &&
    isStaleWrite(code: error.code, message: error.message);
