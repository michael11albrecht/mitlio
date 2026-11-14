import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mitlio/core/logging.dart';

/// Encrypts the IBAN at rest. Stored values are opaque strings; a value
/// without the `enc1:` prefix is plaintext (written while no key was
/// available).
abstract interface class IbanCipher {
  Future<String> encrypt(String plain);

  /// Throws if [stored] is encrypted and the key is gone.
  Future<String> decrypt(String stored);
}

const _prefix = 'enc1:';

/// No encryption.
class PlaintextIbanCipher implements IbanCipher {
  const PlaintextIbanCipher();

  @override
  Future<String> encrypt(String plain) async => plain;

  @override
  Future<String> decrypt(String stored) async => stored;
}

class SecureStorageIbanCipher extends PlaintextIbanCipher {
  // ignore: avoid_unused_constructor_parameters, bisect only
  const SecureStorageIbanCipher({required Object logger, Object? storage});
}
