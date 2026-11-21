import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [SetupStateRepository] for tests and DebugDrive. Stores the
/// JSON like the real one, so a "kill" is a new ViewModel on the same fake.
class FakeSetupStateRepository implements SetupStateRepository {
  final Map<String, String> stored = {};

  /// Fails `load` while set.
  RepositoryError? failLoadWith;

  /// Fails `save` while set.
  RepositoryError? failSaveWith;

  @override
  Future<RepoResult<SetupProgress?>> load(String flowId) async {
    final failure = failLoadWith;
    if (failure != null) return Err(failure);
    final raw = stored[flowId];
    if (raw == null) return const Ok(null);
    return switch (SetupProgress.fromJson(raw)) {
      Ok(:final value) => Ok(value),
      Err(:final error) => Err(error),
    };
  }

  @override
  Future<RepoResult<void>> save(String flowId, SetupProgress progress) async {
    final failure = failSaveWith;
    if (failure != null) return Err(failure);
    stored[flowId] = progress.toJson();
    return const Ok(null);
  }
}
