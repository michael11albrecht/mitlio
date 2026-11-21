import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Which group members are "Ich", the device owner (ADR-25 §5). Local only:
/// it is kept in the setup state, so no schema change and nothing syncs.
class OwnMemberRepository {
  const OwnMemberRepository(this._state);

  final SetupStateRepository _state;

  static String _key(String memberId) => 'own_member:$memberId';

  Future<RepoResult<void>> mark(String memberId) =>
      _state.save(_key(memberId), const SetupProgress(finished: true));

  Future<RepoResult<bool>> isOwn(String memberId) async =>
      switch (await _state.load(_key(memberId))) {
        Ok(:final value) => Ok(value?.finished ?? false),
        Err(:final error) => Err(error),
      };
}
