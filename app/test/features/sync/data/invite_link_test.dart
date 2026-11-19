import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/sync/data/invite_link.dart';

void main() {
  // 43 characters, base64url: the shape the server hands out.
  final token = '${'A' * 20}-_${'z' * 21}';

  group('isInviteToken', () {
    test('accepts 43 base64url characters', () {
      expect(token.length, 43);
      expect(isInviteToken(token), isTrue);
    });

    test('rejects other lengths, characters and empty', () {
      expect(isInviteToken(''), isFalse);
      expect(isInviteToken('abc'), isFalse);
      expect(isInviteToken('${token}A'), isFalse);
      expect(isInviteToken(token.substring(1)), isFalse);
      expect(isInviteToken('${token.substring(1)}='), isFalse);
      expect(isInviteToken('${token.substring(1)}/'), isFalse);
      expect(isInviteToken('${token.substring(1)} '), isFalse);
    });
  });

  group('inviteLocationFor', () {
    test('custom scheme mitlio://join/<token>', () {
      expect(
        inviteLocationFor(Uri.parse('mitlio://join/$token')),
        '/join/$token',
      );
    });

    test('https app link is left to the normal route', () {
      expect(
        inviteLocationFor(Uri.parse('https://mitlio.de/join/$token')),
        isNull,
      );
    });

    test('other custom scheme links are left alone', () {
      expect(inviteLocationFor(Uri.parse('mitlio://ride?km=10')), isNull);
      expect(inviteLocationFor(Uri.parse('mitlio://settings/$token')), isNull);
    });

    test('a custom scheme link with the wrong shape opens the join screen '
        'with a token that is rejected there', () {
      expect(inviteLocationFor(Uri.parse('mitlio://join/abc')), '/join/abc');
      expect(inviteLocationFor(Uri.parse('mitlio://join/')), '/join/invalid');
      expect(inviteLocationFor(Uri.parse('mitlio://join')), '/join/invalid');
      expect(
        inviteLocationFor(Uri.parse('mitlio://join/$token/extra')),
        '/join/invalid',
      );
    });
  });
}
