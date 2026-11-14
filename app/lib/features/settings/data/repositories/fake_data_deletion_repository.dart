import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settings/data/repositories/data_deletion_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Counts calls; can be made to fail.
class FakeDataDeletionRepository implements DataDeletionRepository {
  /// Returned by [deleteEverything] while set.
  RepositoryError? failWith;

  int calls = 0;

  @override
  Future<RepoResult<void>> deleteEverything() async {
    calls++;
    final error = failWith;
    return error == null ? const Ok(null) : Err(error);
  }
}
