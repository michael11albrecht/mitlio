import 'dart:async';

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [ProfileRepository] with the same behaviour as the Drift one.
class FakeProfileRepository implements ProfileRepository {
  UserProfile? _profile;
  final _changes = StreamController<void>.broadcast(sync: true);

  /// Whether a profile exists (used by the fake bank repository).
  bool get exists => _profile != null;

  @override
  Stream<UserProfile?> watchProfile() => watchSnapshots(_changes.stream, () {
    final p = _profile;
    return [?p];
  }).map((l) => l.isEmpty ? null : l.single);

  @override
  Future<RepoResult<UserProfile?>> get() async => Ok(_profile);

  @override
  Future<RepoResult<UserProfile>> save({
    required String displayName,
    int? avatarColor,
    String? avatarEmoji,
    String? paypalMe,
  }) async {
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
    _profile = p;
    _changes.add(null);
    return Ok(p);
  }
}
