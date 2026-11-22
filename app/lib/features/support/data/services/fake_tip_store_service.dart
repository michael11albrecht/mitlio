import 'package:mitlio/features/support/data/services/tip_store_service.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Scripted store for tests: set [catalog] and [outcome]; [bought] records the
/// sizes that were bought.
class FakeTipStoreService implements TipStoreService {
  FakeTipStoreService({Result<List<TipProduct>, TipFailure>? catalog})
    : catalog =
          catalog ??
          const Ok([
            TipProduct(size: TipSize.small, price: '0,99 €'),
            TipProduct(size: TipSize.medium, price: '2,99 €'),
            TipProduct(size: TipSize.large, price: '4,99 €'),
          ]);

  Result<List<TipProduct>, TipFailure> catalog;
  TipOutcome outcome = const TipThanks();
  final List<TipSize> bought = [];

  @override
  Future<Result<List<TipProduct>, TipFailure>> products() async => catalog;

  @override
  Future<TipOutcome> buy(TipSize size) async {
    bought.add(size);
    return outcome;
  }
}
