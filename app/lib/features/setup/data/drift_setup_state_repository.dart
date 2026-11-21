import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `local_settings` key prefix of a flow's progress. Own keys, no schema
/// change: the profile's `setup_state` column (PU-T04) can take over later.
const setupFlowKeyPrefix = 'setup_flow.';

/// [SetupStateRepository] in the key/value `local_settings` table.
class DriftSetupStateRepository implements SetupStateRepository {
  DriftSetupStateRepository(AppDatabase db) : _dao = db.syncStateDao;

  final SyncStateDao _dao;

  @override
  Future<RepoResult<SetupProgress?>> load(String flowId) =>
      guardStorage(() async {
        final raw = await _dao.setting('$setupFlowKeyPrefix$flowId');
        if (raw == null) return const Ok(null);
        return switch (SetupProgress.fromJson(raw)) {
          Ok(:final value) => Ok(value),
          Err(:final error) => Err(error),
        };
      });

  @override
  Future<RepoResult<void>> save(String flowId, SetupProgress progress) =>
      guardStorage(() async {
        await _dao.putSetting('$setupFlowKeyPrefix$flowId', progress.toJson());
        return const Ok(null);
      });
}
