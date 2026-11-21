import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'profile_dao.g.dart';

/// The single local profile row (PII, local only until P6-T07).
@DriftAccessor(tables: [Profile])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.attachedDatabase);

  Future<void> upsert(ProfileCompanion row) =>
      into(profile).insertOnConflictUpdate(row);

  Future<ProfileRow?> find() => (select(
    profile,
  )..where((p) => p.id.equals(profileRowId))).getSingleOrNull();

  Stream<ProfileRow?> watch() => (select(
    profile,
  )..where((p) => p.id.equals(profileRowId))).watchSingleOrNull();
}
