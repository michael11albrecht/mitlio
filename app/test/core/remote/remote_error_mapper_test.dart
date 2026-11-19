import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeClientException implements Exception {}

// Same runtimeType name as package:http's ClientException.
class ClientException implements Exception {}

void main() {
  group(
    'fromPostgrest: one row per server string (migrations 0002/3/9/10)',
    () {
      // (SQLSTATE, message, expected). Literals copied from the migrations.
      final rows = <(String, String, RemoteError)>[
        ('P0429', 'rate_limited', const RateLimitedRemote(null)),
        ('22023', 'invite_invalid', const InviteInvalid()),
        ('22023', 'member_not_found', const MemberGone()),
        ('23505', 'member_already_claimed', const MemberAlreadyClaimed()),
        ('23514', 'membership_already_linked', const AlreadyConnected()),
        ('42501', 'not the owner of this group', const NotOwner()),
        ('42501', 'not a member of this group', const NotMember()),
        ('23514', 'cannot remove own membership', const CannotRemoveSelf()),
        // upsert_expense (0002): rejected with the stable code.
        ('23514', 'invalid_payload', const Rejected('invalid_payload')),
        ('23514', 'amount_not_positive', const Rejected('amount_not_positive')),
        ('23514', 'duplicate_member', const Rejected('duplicate_member')),
        ('23514', 'payers_sum_mismatch', const Rejected('payers_sum_mismatch')),
        ('23514', 'shares_sum_mismatch', const Rejected('shares_sum_mismatch')),
        ('23514', 'member_not_in_group', const Rejected('member_not_in_group')),
        ('23514', 'group_mismatch', const Rejected('group_mismatch')),
        ('42501', 'not authenticated', const Rejected('not authenticated')),
        // A refused PostgREST write: every policy is "member of the group".
        (
          '42501',
          'new row violates row-level security policy for table "members"',
          const NotMember(),
        ),
      ];
      for (final (state, message, expected) in rows) {
        test('$state "$message" -> $expected', () {
          expect(fromPostgrest(code: state, message: message), expected);
        });
      }

      test('a known message with HTTP 400 still maps by message', () {
        expect(
          fromPostgrest(
            code: '22023',
            message: 'invite_invalid',
            httpStatus: 400,
          ),
          const InviteInvalid(),
        );
      });

      test('HTTP 429 without a code is rate limited', () {
        expect(
          fromPostgrest(message: 'slow down', httpStatus: 429),
          const RateLimitedRemote(null),
        );
      });

      test('unknown 4xx is rejected with the message, never offline', () {
        final e = fromPostgrest(
          code: 'XX999',
          message: 'something new',
          httpStatus: 409,
        );
        expect(e, const Rejected('something new'));
      });

      test('unknown 4xx without message falls back to the code', () {
        expect(
          fromPostgrest(code: 'PGRST301', httpStatus: 401),
          const Rejected('PGRST301'),
        );
        expect(fromPostgrest(httpStatus: 400), const Rejected('unknown'));
      });

      test('unknown 5xx is serverDown', () {
        expect(
          fromPostgrest(message: 'boom', httpStatus: 503),
          const ServerDown(),
        );
      });

      test('every HTTP 4xx status is never offline', () {
        for (var status = 400; status < 500; status++) {
          expect(
            fromPostgrest(message: 'x', httpStatus: status),
            isNot(isA<Offline>()),
          );
        }
      });
    },
  );

  group('retry_after_seconds hint', () {
    RemoteError limited(String? hint) =>
        fromPostgrest(code: 'P0429', message: 'rate_limited', hint: hint);

    test('present', () {
      expect(
        limited('retry_after_seconds=360'),
        const RateLimitedRemote(Duration(minutes: 6)),
      );
    });
    test('absent', () {
      expect(limited(null), const RateLimitedRemote(null));
    });
    test('garbage', () {
      expect(limited('try later'), const RateLimitedRemote(null));
      expect(limited('retry_after_seconds=abc'), const RateLimitedRemote(null));
      expect(limited('retry_after_seconds=0'), const RateLimitedRemote(null));
    });
    test('embedded in a longer hint', () {
      expect(
        limited('foo; retry_after_seconds=90'),
        const RateLimitedRemote(Duration(seconds: 90)),
      );
    });
  });

  group('fromAuth', () {
    test('429 is rateLimited', () {
      expect(fromAuth(statusCode: 429), const RateLimitedRemote(null));
    });
    test('rate-limit codes are rateLimited', () {
      expect(
        fromAuth(code: 'over_request_rate_limit'),
        const RateLimitedRemote(null),
      );
      expect(
        fromAuth(code: 'over_email_send_rate_limit'),
        const RateLimitedRemote(null),
      );
    });
    test('5xx is serverDown', () {
      expect(fromAuth(statusCode: 500), const ServerDown());
      expect(fromAuth(statusCode: 503), const ServerDown());
    });
    test('anonymous_provider_disabled is serverDown', () {
      expect(
        fromAuth(statusCode: 422, code: 'anonymous_provider_disabled'),
        const ServerDown(),
      );
    });
    test('other 4xx is rejected, never offline', () {
      expect(
        fromAuth(statusCode: 400, code: 'bad_jwt'),
        const Rejected('bad_jwt'),
      );
      expect(fromAuth(statusCode: 401), const Rejected('auth_401'));
      expect(fromAuth(), const Rejected('auth_unknown'));
    });
  });

  group('fromException', () {
    test('network failures are offline', () {
      expect(fromException(const SocketException('x')), const Offline());
      expect(fromException(const HttpException('x')), const Offline());
      expect(fromException(const HandshakeException('x')), const Offline());
      expect(fromException(TimeoutException('x')), const Offline());
      expect(fromException(ClientException()), const Offline());
    });

    test('auth: fetch failure without a response is offline', () {
      expect(fromException(AuthRetryableFetchException()), const Offline());
    });

    test('auth: retryable with a status is mapped by status', () {
      expect(
        fromException(AuthRetryableFetchException(statusCode: '503')),
        const ServerDown(),
      );
    });

    test('auth: unknown wrapping a socket error is offline', () {
      expect(
        fromException(
          AuthUnknownException(
            message: 'x',
            originalError: const SocketException('x'),
          ),
        ),
        const Offline(),
      );
    });

    test('auth: api exception maps status and code', () {
      expect(
        fromException(const AuthApiException('x', statusCode: '429')),
        const RateLimitedRemote(null),
      );
      expect(
        fromException(
          const AuthApiException(
            'x',
            statusCode: '422',
            code: 'anonymous_provider_disabled',
          ),
        ),
        const ServerDown(),
      );
      expect(
        fromException(const AuthApiException('x', statusCode: '400')),
        isNot(isA<Offline>()),
      );
    });

    test('postgrest exception maps like fromPostgrest', () {
      expect(
        fromException(
          const PostgrestException(
            message: 'rate_limited',
            code: 'P0429',
            hint: 'retry_after_seconds=120',
          ),
        ),
        const RateLimitedRemote(Duration(minutes: 2)),
      );
      expect(
        fromException(
          const PostgrestException(
            message: 'not a member of this group',
            code: '42501',
          ),
        ),
        const NotMember(),
      );
    });

    test('postgrest exception with an HTTP status as code', () {
      expect(
        fromException(const PostgrestException(message: 'down', code: '502')),
        const ServerDown(),
      );
      expect(
        fromException(const PostgrestException(message: 'nope', code: '404')),
        const Rejected('nope'),
      );
    });

    test('an unknown error never claims offline', () {
      expect(
        fromException(_FakeClientException()),
        const Rejected('unexpected'),
      );
      expect(fromException(StateError('x')), const Rejected('unexpected'));
    });
  });

  group('isStaleWrite (ADR-27 §3: dropped, not an error)', () {
    test('LWW trigger violation', () {
      const msg = 'updated_at must not go backwards (2026-01-01 < 2026-01-02)';
      expect(isStaleWrite(code: '23514', message: msg), isTrue);
      expect(
        isStaleWriteException(
          const PostgrestException(message: msg, code: '23514'),
        ),
        isTrue,
      );
    });
    test('other check violations and errors are not stale', () {
      expect(
        isStaleWrite(code: '23514', message: 'payers_sum_mismatch'),
        isFalse,
      );
      expect(
        isStaleWrite(
          code: '42501',
          message: 'updated_at must not go backwards',
        ),
        isFalse,
      );
      expect(isStaleWrite(), isFalse);
      expect(isStaleWriteException(StateError('x')), isFalse);
    });
  });

  group('RemoteError value semantics', () {
    test('equality, hashCode and toString', () {
      const all = <RemoteError>[
        Offline(),
        RateLimitedRemote(Duration(seconds: 5)),
        InviteInvalid(),
        MemberAlreadyClaimed(),
        AlreadyConnected(),
        MemberGone(),
        NotOwner(),
        NotMember(),
        CannotRemoveSelf(),
        VersionTooOld(),
        ServerDown(),
        Rejected('x'),
      ];
      for (final (i, a) in all.indexed) {
        for (final (j, b) in all.indexed) {
          expect(a == b, i == j);
        }
        expect(a.hashCode, a.hashCode);
        expect(a.toString(), isNotEmpty);
      }
      expect(const Rejected('a'), isNot(const Rejected('b')));
      expect(
        const RateLimitedRemote(Duration(seconds: 1)),
        isNot(const RateLimitedRemote(null)),
      );
      expect(const Rejected('a').hashCode, const Rejected('a').hashCode);
      expect(
        const RateLimitedRemote(null).hashCode,
        const RateLimitedRemote(null).hashCode,
      );
    });
  });
}
