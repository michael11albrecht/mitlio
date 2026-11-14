import 'package:mitlio/features/members/data/services/iban_cipher.dart';

/// Reversible stand-in for tests: marks values as encrypted without a key.
class FakeIbanCipher implements IbanCipher {
  const FakeIbanCipher();

  static const marker = 'fake:';

  @override
  Future<String> encrypt(String plain) async =>
      '$marker${plain.split('').reversed.join()}';

  @override
  Future<String> decrypt(String stored) async => stored.startsWith(marker)
      ? stored.substring(marker.length).split('').reversed.join()
      : stored;
}
