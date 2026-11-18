import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';

void main() {
  const all = <RemoteError>[
    Offline(),
    RateLimitedRemote(null),
    InviteInvalid(),
    MemberAlreadyClaimed(),
    AlreadyConnected(),
    MemberGone(),
    NotOwner(),
    NotMember(),
    CannotRemoveSelf(),
    VersionTooOld(),
    ServerDown(),
    Rejected('payers_sum_mismatch'),
    PullFailed('invalid_updated_at'),
  ];

  test('every case survives a trip through the stored code', () {
    for (final e in all) {
      expect(remoteErrorFromCaseName(e.storedCode), e);
    }
  });

  test('a rejection is stored with its server code', () {
    expect(
      const Rejected('payers_sum_mismatch').storedCode,
      'rejected:payers_sum_mismatch',
    );
    expect(const Offline().storedCode, 'offline');
  });

  test('an unknown stored name is shown as rejected, not hidden', () {
    expect(
      remoteErrorFromCaseName('from_the_future'),
      const Rejected('from_the_future'),
    );
  });
}
