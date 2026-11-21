import 'package:drift/drift.dart' show Value;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// [ProfileBankRepository] backed by Drift: the encrypted IBAN in
/// `local_profile_bank`. Never touches the outbox.
class DriftProfileBankRepository implements ProfileBankRepository {
  DriftProfileBankRepository({
    required this._db,
    required this._clock,
    required this._cipher,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IbanCipher _cipher;

  @override
  Future<RepoResult<ProfileBank?>> get() => guardStorage(() async {
    final row = await _db.localProfileBankDao.find();
    if (row == null) return const Ok(null);
    return Ok(
      ProfileBank(
        iban: await _cipher.decrypt(row.iban),
        bic: row.bic,
        accountName: row.accountName,
      ),
    );
  });

  @override
  Future<RepoResult<ProfileBank>> save({
    required String iban,
    String? bic,
    String? accountName,
  }) => guardStorage(() async {
    final built = buildProfileBank(
      iban: iban,
      bic: bic,
      accountName: accountName,
    );
    if (built case Err<ProfileBank, RepositoryError>(:final error)) {
      return Err(error);
    }
    final bank = built.orThrow();
    if (await _db.profileDao.find() == null) {
      return const Err(NotFound('profile', profileRowId));
    }
    await _db.localProfileBankDao.upsert(
      LocalProfileBankCompanion(
        profileId: const Value(profileRowId),
        iban: Value(await _cipher.encrypt(bank.iban)),
        bic: Value(bank.bic),
        accountName: Value(bank.accountName),
        updatedAt: Value(Hlc.now(_clock)),
      ),
    );
    return Ok(bank);
  });

  @override
  Future<RepoResult<void>> clear() => guardStorage(() async {
    await _db.localProfileBankDao.deleteAll();
    return const Ok(null);
  });
}
