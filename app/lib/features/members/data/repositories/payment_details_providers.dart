import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/members/data/repositories/drift_payment_details_repository.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';

/// Keychain/Keystore-backed by default; override with `FakeIbanCipher` or
/// `PlaintextIbanCipher` in tests.
final ibanCipherProvider = Provider<IbanCipher>(
  (ref) => SecureStorageIbanCipher(logger: ref.watch(loggerProvider)),
);

/// Drift by default; override with `FakePaymentDetailsRepository` in tests.
final paymentDetailsRepositoryProvider = Provider<PaymentDetailsRepository>(
  (ref) => DriftPaymentDetailsRepository(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    cipher: ref.watch(ibanCipherProvider),
  ),
);
