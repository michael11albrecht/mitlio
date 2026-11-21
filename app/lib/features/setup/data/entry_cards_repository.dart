import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Remembers which inline cards (by stable id) were dismissed. A dismissed
/// card stays dismissed for good; it is kept in the setup state, so nothing
/// syncs.
class EntryCardsRepository {
  const EntryCardsRepository(this._state);

  final SetupStateRepository _state;

  static String _key(String cardId) => 'card:$cardId';

  Future<RepoResult<bool>> isDismissed(String cardId) async =>
      switch (await _state.load(_key(cardId))) {
        Ok(:final value) => Ok(value?.finished ?? false),
        Err(:final error) => Err(error),
      };

  Future<RepoResult<void>> dismiss(String cardId) =>
      _state.save(_key(cardId), const SetupProgress(finished: true));
}
