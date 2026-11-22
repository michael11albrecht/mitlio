import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/support/data/repositories/fake_support_repository.dart';
import 'package:mitlio/features/support/data/services/fake_tip_store_service.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio/features/support/data/support_providers.dart';
import 'package:mitlio/features/support/ui/tip_jar_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

({ProviderContainer c, FakeTipStoreService store}) _setup({
  Result<List<TipProduct>, TipFailure>? catalog,
}) {
  final store = FakeTipStoreService(catalog: catalog);
  final c = ProviderContainer(
    overrides: [
      supportRepositoryProvider.overrideWithValue(
        FakeSupportRepository(store: store),
      ),
    ],
  );
  addTearDown(c.dispose);
  return (c: c, store: store);
}

TipJarViewModel _vm(ProviderContainer c) {
  c.listen(tipJarViewModelProvider, (_, _) {});
  return c.read(tipJarViewModelProvider.notifier);
}

TipJarState _state(ProviderContainer c) => c.read(tipJarViewModelProvider);

void main() {
  test('loads the three sizes with the store prices', () async {
    final s = _setup();
    await _vm(s.c).load();
    final state = _state(s.c);
    expect(state, isA<TipJarReady>());
    expect((state as TipJarReady).products.map((p) => p.size), TipSize.values);
    expect(state.products.first.price, '0,99 €');
    expect(state.error, isNull);
  });

  for (final failure in [
    TipFailure.storeUnavailable,
    TipFailure.productsUnavailable,
  ]) {
    test('store answer $failure is shown, not swallowed', () async {
      final s = _setup(catalog: Err(failure));
      await _vm(s.c).load();
      expect(_state(s.c), TipJarUnavailable(failure));
    });
  }

  test('retry after an unavailable store loads again', () async {
    final s = _setup(catalog: const Err(TipFailure.storeUnavailable));
    final vm = _vm(s.c);
    await vm.load();
    s.store.catalog = const Ok([
      TipProduct(size: TipSize.small, price: '1 €'),
    ]);
    await vm.load();
    expect(_state(s.c), isA<TipJarReady>());
  });

  group('purchase', () {
    test('success shows the thank-you state', () async {
      final s = _setup();
      final vm = _vm(s.c);
      await vm.load();
      await vm.tip(TipSize.medium);
      expect(_state(s.c), isA<TipJarThanks>());
      expect(s.store.bought, [TipSize.medium]);
    });

    test('cancel is no error: back to the sizes, no message', () async {
      final s = _setup();
      s.store.outcome = const TipCancelled();
      final vm = _vm(s.c);
      await vm.load();
      await vm.tip(TipSize.small);
      final state = _state(s.c) as TipJarReady;
      expect(state.error, isNull);
      expect(state.buying, isNull);
    });

    test('failure keeps the sizes and says what happened', () async {
      final s = _setup();
      s.store.outcome = const TipFailed(TipFailure.purchaseFailed);
      final vm = _vm(s.c);
      await vm.load();
      await vm.tip(TipSize.large);
      final state = _state(s.c) as TipJarReady;
      expect(state.error, TipFailure.purchaseFailed);
      expect(state.buying, isNull);
    });

    test('trying again after a failure clears the message', () async {
      final s = _setup();
      s.store.outcome = const TipFailed(TipFailure.purchaseFailed);
      final vm = _vm(s.c);
      await vm.load();
      await vm.tip(TipSize.large);
      s.store.outcome = const TipThanks();
      await vm.tip(TipSize.large);
      expect(_state(s.c), isA<TipJarThanks>());
    });

    test('a second tap while buying is ignored', () async {
      final s = _setup();
      final vm = _vm(s.c);
      await vm.load();
      final first = vm.tip(TipSize.small);
      expect((_state(s.c) as TipJarReady).buying, TipSize.small);
      await vm.tip(TipSize.large);
      await first;
      expect(s.store.bought, [TipSize.small]);
    });

    test('tipping before the sizes loaded does nothing', () async {
      final s = _setup();
      await _vm(s.c).tip(TipSize.small);
      expect(s.store.bought, isEmpty);
    });
  });
}
