import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'local_profile_bank_dao.g.dart';

/// Local-only IBAN storage of the profile (PII). Exposes nothing that joins
/// with synced tables; sync code must not import it.
@DriftAccessor(tables: [LocalProfileBank])
class LocalProfileBankDao extends DatabaseAccessor<AppDatabase>
    with _$LocalProfileBankDaoMixin {
  LocalProfileBankDao(super.attachedDatabase);

  Future<void> upsert(LocalProfileBankCompanion row) =>
      into(localProfileBank).insertOnConflictUpdate(row);

  Future<LocalProfileBankRow?> find() => (select(
    localProfileBank,
  )..where((b) => b.profileId.equals(profileRowId))).getSingleOrNull();

  Future<void> deleteAll() => delete(localProfileBank).go();
}
