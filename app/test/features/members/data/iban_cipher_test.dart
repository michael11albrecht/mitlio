import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/members/data/repositories/drift_payment_details_repository.dart';
import 'package:mitlio/features/members/data/services/fake_iban_cipher.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';

import '../../../support/capturing_logger.dart';
import '../../repo_test_support.dart';
import 'payment_details_repository_contract.dart';

/// A key store that is not there, like the headless Linux harness.
class _BrokenStorage extends Fake implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw StateError('no keyring');
  }
}

void main() {
  late CapturingLogger log;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    log = CapturingLogger();
  });

  group('SecureStorageIbanCipher', () {
    test('encrypts with a stored key and reads it back', () async {
      final cipher = SecureStorageIbanCipher(logger: log);
      final stored = await cipher.encrypt(testIban);
      expect(stored, startsWith('enc1:'));
      expect(stored, isNot(contains(testIban)));
      expect(await cipher.decrypt(stored), testIban);
      expect(log.lines, isEmpty);
    });

    test('a new instance finds the same key', () async {
      final stored = await SecureStorageIbanCipher(
        logger: log,
      ).encrypt(testIban);
      expect(
        await SecureStorageIbanCipher(logger: log).decrypt(stored),
        testIban,
      );
    });

    test(
      'encrypting twice gives different ciphertexts (random nonce)',
      () async {
        final cipher = SecureStorageIbanCipher(logger: log);
        expect(
          await cipher.encrypt(testIban),
          isNot(await cipher.encrypt(testIban)),
        );
      },
    );

    test('without a key store it stores plaintext and logs once', () async {
      final cipher = SecureStorageIbanCipher(
        logger: log,
        storage: _BrokenStorage(),
      );
      expect(await cipher.encrypt(testIban), testIban);
      expect(
        await cipher.encrypt('GB82WEST12345698765432'),
        'GB82WEST12345698765432',
      );
      expect(await cipher.decrypt(testIban), testIban);
      expect(log.lines, hasLength(1));
      expect(log.output, isNot(contains('DE89')));
    });

    test('an encrypted value without the key cannot be read', () async {
      final stored = await SecureStorageIbanCipher(
        logger: log,
      ).encrypt(testIban);
      FlutterSecureStorage.setMockInitialValues({});
      await expectLater(
        SecureStorageIbanCipher(logger: log).decrypt(stored),
        throwsStateError,
      );
    });

    test(
      'deleteKey makes stored values unreadable and a new key is used',
      () async {
        final cipher = SecureStorageIbanCipher(logger: log);
        final stored = await cipher.encrypt(testIban);
        await cipher.deleteKey();
        await expectLater(cipher.decrypt(stored), throwsStateError);
        final fresh = await cipher.encrypt(testIban);
        expect(await cipher.decrypt(fresh), testIban);
        expect(
          await SecureStorageIbanCipher(logger: log).decrypt(fresh),
          testIban,
          reason: 'the new key was persisted, not only cached',
        );
      },
    );

    test('deleteKey without a key store does not throw', () async {
      await SecureStorageIbanCipher(
        logger: log,
        storage: _BrokenStorage(),
      ).deleteKey();
    });

    test('a tampered value fails to decrypt', () async {
      final cipher = SecureStorageIbanCipher(logger: log);
      final stored = await cipher.encrypt(testIban);
      final tampered = '${stored.substring(0, stored.length - 4)}AAAA';
      await expectLater(cipher.decrypt(tampered), throwsA(anything));
    });
  });

  group('FakeIbanCipher', () {
    test('round-trips and passes plaintext through', () async {
      const cipher = FakeIbanCipher();
      final stored = await cipher.encrypt(testIban);
      expect(stored, isNot(testIban));
      expect(await cipher.decrypt(stored), testIban);
      expect(await cipher.decrypt(testIban), testIban);
    });
  });

  group('PlaintextIbanCipher', () {
    test('is the identity', () async {
      const cipher = PlaintextIbanCipher();
      expect(await cipher.encrypt(testIban), testIban);
      expect(await cipher.decrypt(testIban), testIban);
    });
  });

  test(
    'the IBAN appears in no log output across save, get and failure',
    () async {
      final base = await driftRepos();
      final repo = DriftPaymentDetailsRepository(
        db: base.db!,
        clock: base.clock,
        cipher: SecureStorageIbanCipher(
          logger: log,
          storage: _BrokenStorage(),
        ),
      );
      final id = (await seedGroup(base)).members.first.id;
      ok(await repo.save(id, iban: testIban, accountName: 'Ann'));
      ok(await repo.get(id));
      err(await repo.save(id, iban: 'DE89370400440532013001'));
      expect(log.lines, isNotEmpty);
      expect(log.output, isNot(contains('DE89')));
      expect(log.output, isNot(contains('0440532013')));
    },
  );
}
