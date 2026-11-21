import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/my_qr.dart';
import 'package:mitlio/features/profile/data/repositories/qr_share_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart' show ok;
import '../helpers/fake_app.dart';

const _iban = 'DE89370400440532013000';

class _FakeQrShare implements QrShareRepository {
  final shared = <String>[];
  RepositoryError? failWith;

  @override
  Future<RepoResult<void>> sharePng(String payload) async {
    if (failWith != null) return Err(failWith!);
    shared.add(payload);
    return const Ok(null);
  }
}

/// "Mein QR-Code teilen" through `ext.mitlio.profile.qr` and
/// `profile.shareQr` (PU-T16): the commands the screen uses.
void main() {
  late FakeApp app;
  late _FakeQrShare share;
  late ProviderContainer c;
  late Map<String, DriveHandler> h;

  setUp(() {
    app = FakeApp();
    share = _FakeQrShare();
    c = ProviderContainer(
      overrides: [
        ...app.overrides,
        qrShareRepositoryProvider.overrideWithValue(share),
      ],
    );
    addTearDown(c.dispose);
    h = myQrDriveHandlers(c);
  });

  test('profile.qr says noIban until an IBAN is saved', () async {
    expect(await h['profile.qr']!({}), {'state': 'noIban'});
    ok(await app.profile.save(displayName: 'Mia'));
    ok(await app.profileBank.save(iban: _iban));
    final r = await h['profile.qr']!({});
    expect(r['state'], 'loaded');
    expect(r['name'], 'Mia');
    final payload = r['payload']! as String;
    expect(payload.split('\n')[6], _iban);
    expect(payload.split('\n')[7], isEmpty, reason: 'no amount');
  });

  test('profile.shareQr hands the code to the share sheet', () async {
    ok(await app.profile.save(displayName: 'Mia'));
    ok(await app.profileBank.save(iban: _iban));
    expect(await h['profile.shareQr']!({}), {'shared': true});
    expect(share.shared, hasLength(1));
  });

  test('profile.shareQr without IBAN is not_found', () async {
    expect(await h['profile.shareQr']!({}), containsPair('error', 'not_found'));
    expect(share.shared, isEmpty);
  });

  test('profile.shareQr reports a failing share sheet', () async {
    ok(await app.profile.save(displayName: 'Mia'));
    ok(await app.profileBank.save(iban: _iban));
    share.failWith = const Storage('share');
    expect(await h['profile.shareQr']!({}), containsPair('error', 'internal'));
  });
}
