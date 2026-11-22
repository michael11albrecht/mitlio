import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/support/data/repositories/support_repository.dart';
import 'package:mitlio/features/support/data/services/tip_store_service.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [SupportRepository] for ViewModel tests. [enabled] is the remote
/// flag; [failStorage] makes the local state fail like a full disk.
class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({
    this.enabled = false,
    this.state = const SupportPromptState(),
    TipStoreService? store,
  }) : store = store ?? _NoStore();

  bool enabled;
  SupportPromptState state;
  final TipStoreService store;
  bool failStorage = false;

  @override
  Future<bool> tipsEnabled() async => enabled;

  @override
  Future<RepoResult<SupportPromptState>> promptState() async =>
      failStorage ? const Err(Storage('disk full')) : Ok(state);

  @override
  Future<RepoResult<void>> savePromptState(SupportPromptState next) async {
    if (failStorage) return const Err(Storage('disk full'));
    state = next;
    return const Ok(null);
  }

  @override
  Future<Result<List<TipProduct>, TipFailure>> tipProducts() =>
      store.products();

  @override
  Future<TipOutcome> buyTip(TipSize size) => store.buy(size);
}

class _NoStore implements TipStoreService {
  @override
  Future<Result<List<TipProduct>, TipFailure>> products() async =>
      const Err(TipFailure.storeUnavailable);

  @override
  Future<TipOutcome> buy(TipSize size) async =>
      const TipFailed(TipFailure.storeUnavailable);
}
