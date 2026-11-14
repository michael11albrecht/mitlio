import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'local_member_bank_dao.g.dart';

/// Local-only IBAN storage (PII). Deliberately exposes nothing that joins
/// with synced tables.
@DriftAccessor(tables: [LocalMemberBank])
class LocalMemberBankDao extends DatabaseAccessor<AppDatabase>
    with _$LocalMemberBankDaoMixin {
  LocalMemberBankDao(super.attachedDatabase);

  Future<void> upsert(LocalMemberBankCompanion row) =>
      into(localMemberBank).insertOnConflictUpdate(row);

  Future<LocalMemberBankRow?> findByMember(String memberId) => (select(
    localMemberBank,
  )..where((b) => b.memberId.equals(memberId))).getSingleOrNull();

  Future<void> deleteByMember(String memberId) => (delete(
    localMemberBank,
  )..where((b) => b.memberId.equals(memberId))).go();
}
