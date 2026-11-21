import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/qr_share_repository.dart';
import 'package:mitlio/features/profile/ui/my_qr_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';
import 'profile_flow_rig.dart';

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

/// Returns details that bypass the save validation.
class _RawBank extends FakeProfileBankRepository {
  _RawBank(this.bank, {required super.profile});

  final ProfileBank bank;

  @override
  Future<RepoResult<ProfileBank?>> get() async => Ok(bank);
}

void main() {
  late FakeApp app;
  late FlakyBank bank;
  late _FakeQrShare qrShare;
  late ProviderContainer c;

  setUp(() {
    app = FakeApp();
    bank = FlakyBank(profile: app.profile);
    app.profileBank = bank;
    qrShare = _FakeQrShare();
    c = ProviderContainer(
      overrides: [
        ...app.overrides,
        qrShareRepositoryProvider.overrideWithValue(qrShare),
      ],
    );
    addTearDown(c.dispose);
  });

  Future<MyQrState> load() async {
    c.listen(myQrViewModelProvider, (_, _) {});
    await c.read(myQrViewModelProvider.notifier).load();
    return c.read(myQrViewModelProvider);
  }

  group('MyQrViewModel', () {
    test('no profile or no IBAN: nothing to share yet', () async {
      expect(await load(), isA<MyQrNoIban>());
      ok(await app.profile.save(displayName: 'Mia'));
      expect(await load(), isA<MyQrNoIban>());
    });

    test('builds the EPC payload without amount from the saved IBAN', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      ok(await bank.save(iban: _iban));
      final state = await load() as MyQrLoaded;
      expect(
        state.payload,
        (buildEpcQrPayload(
          name: 'Mia',
          iban: _iban,
          amount: null,
        ) as Ok<String, EpcError>).value,
      );
      expect(state.payload.split('\n')[7], isEmpty);
    });

    test('the account holder name wins over the display name', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      ok(await bank.save(iban: _iban, accountName: 'Mia Muster'));
      final state = await load() as MyQrLoaded;
      expect(state.name, 'Mia Muster');
      expect(state.payload.split('\n')[5], 'Mia Muster');
    });

    test('a failing read is a failure, not "no IBAN"', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      bank.failGetWith = const Storage('disk');
      expect(await load(), isA<MyQrFailure>());
    });

    test('stored details the QR cannot hold are a failure', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      app.profileBank = _RawBank(
        const ProfileBank(iban: 'DE00'),
        profile: app.profile,
      );
      final other = ProviderContainer(overrides: app.overrides);
      addTearDown(other.dispose);
      other.listen(myQrViewModelProvider, (_, _) {});
      await other.read(myQrViewModelProvider.notifier).load();
      expect(other.read(myQrViewModelProvider), isA<MyQrFailure>());
    });

    test('share hands the payload to the QR share repository', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      ok(await bank.save(iban: _iban));
      final state = await load() as MyQrLoaded;
      ok(await c.read(myQrViewModelProvider.notifier).share());
      expect(qrShare.shared, [state.payload]);
    });

    test('share without an IBAN fails with NotFound', () async {
      await load();
      final r = await c.read(myQrViewModelProvider.notifier).share();
      expect(r, isA<Err<void, RepositoryError>>());
      expect(qrShare.shared, isEmpty);
    });

    test('a failing share sheet is an error, not silence', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      ok(await bank.save(iban: _iban));
      await load();
      qrShare.failWith = const Storage('share');
      final r = await c.read(myQrViewModelProvider.notifier).share();
      expect((r as Err<void, RepositoryError>).error, const Storage('share'));
    });
  });
}
