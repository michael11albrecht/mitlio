import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mitlio/core/logging.dart';

/// Encrypts the IBAN at rest. Stored values are opaque strings; a value
/// without the `enc1:` prefix is plaintext (written while no key was
/// available).
abstract interface class IbanCipher {
  Future<String> encrypt(String plain);

  /// Throws if [stored] is encrypted and the key is gone.
  Future<String> decrypt(String stored);

  /// Removes the key, so stored values can never be read again ("delete my
  /// data"). An unavailable store holds no key, so that is not a failure.
  Future<void> deleteKey();
}

const _prefix = 'enc1:';

/// No encryption.
class PlaintextIbanCipher implements IbanCipher {
  const PlaintextIbanCipher();

  @override
  Future<String> encrypt(String plain) async => plain;

  @override
  Future<String> decrypt(String stored) async => stored;

  @override
  Future<void> deleteKey() async {}
}

/// AES-256-GCM with a random key kept in `flutter_secure_storage` (Keychain,
/// Keystore). If the key store is unavailable (e.g. the headless Linux test
/// harness), falls back to plaintext and logs that once, without any value.
class SecureStorageIbanCipher implements IbanCipher {
  SecureStorageIbanCipher({
    required this._logger,
    this._storage = const FlutterSecureStorage(),
  });

  static const _keyName = 'mitlio.iban.key';

  final Logger _logger;
  final FlutterSecureStorage _storage;
  final _algorithm = AesGcm.with256bits();
  SecretKey? _key;
  var _warned = false;

  void _warnOnce() {
    if (_warned) return;
    _warned = true;
    _logger.warn('Key store unavailable: IBANs are stored unencrypted');
  }

  /// The existing key, or a new one if [create]; null if the store fails.
  Future<SecretKey?> _loadKey({required bool create}) async {
    final cached = _key;
    if (cached != null) return cached;
    try {
      final stored = await _storage.read(key: _keyName);
      if (stored != null) return _key = SecretKey(base64Decode(stored));
      if (!create) return null;
      final fresh = await _algorithm.newSecretKey();
      await _storage.write(
        key: _keyName,
        value: base64Encode(await fresh.extractBytes()),
      );
      return _key = fresh;
    } on Object {
      return null;
    }
  }

  @override
  Future<String> encrypt(String plain) async {
    final key = await _loadKey(create: true);
    if (key == null) {
      _warnOnce();
      return plain;
    }
    final box = await _algorithm.encrypt(utf8.encode(plain), secretKey: key);
    return '$_prefix${base64Encode(box.concatenation())}';
  }

  @override
  Future<String> decrypt(String stored) async {
    if (!stored.startsWith(_prefix)) return stored;
    final key = await _loadKey(create: false);
    if (key == null) throw StateError('IBAN key unavailable');
    final box = SecretBox.fromConcatenation(
      base64Decode(stored.substring(_prefix.length)),
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return utf8.decode(await _algorithm.decrypt(box, secretKey: key));
  }

  @override
  Future<void> deleteKey() async {
    _key = null;
    try {
      await _storage.delete(key: _keyName);
    } on Object {
      // No key store, no key.
    }
  }
}
