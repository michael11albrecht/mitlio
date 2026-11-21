import 'package:drift/drift.dart' show Value;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// [ProfileRepository] backed by Drift (local only, no outbox).
class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository({required this._db, required this._clock});

  final AppDatabase _db;
  final Clock _clock;

  static UserProfile _map(ProfileRow r) => UserProfile(
    displayName: r.displayName,
    avatarColor: r.avatarColor,
    avatarEmoji: r.avatarEmoji,
    paypalMe: r.paypalMe,
  );

  @override
  Stream<UserProfile?> watchProfile() =>
      _db.profileDao.watch().map((r) => r == null ? null : _map(r));

  @override
  Future<RepoResult<UserProfile?>> get() => guardStorage(() async {
    final row = await _db.profileDao.find();
    return Ok(row == null ? null : _map(row));
  });

  @override
  Future<RepoResult<UserProfile>> save({
    required String displayName,
    int? avatarColor,
    String? avatarEmoji,
    String? paypalMe,
  }) => guardStorage(() async {
    final built = buildUserProfile(
      displayName: displayName,
      avatarColor: avatarColor,
      avatarEmoji: avatarEmoji,
      paypalMe: paypalMe,
    );
    if (built case Err<UserProfile, RepositoryError>(:final error)) {
      return Err(error);
    }
    final p = built.orThrow();
    await _db.profileDao.upsert(
      ProfileCompanion(
        id: const Value(profileRowId),
        displayName: Value(p.displayName),
        avatarColor: Value(p.avatarColor),
        avatarEmoji: Value(p.avatarEmoji),
        paypalMe: Value(p.paypalMe),
        updatedAt: Value(Hlc.now(_clock)),
      ),
    );
    return Ok(p);
  });
}
