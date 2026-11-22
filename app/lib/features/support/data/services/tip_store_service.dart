import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The store side of the tip jar (ADR-28): StoreKit on iOS, Play Billing on
/// Android, through `in_app_purchase`. Tips are consumables, so a user can tip
/// again. Nothing here is synced or analysed. Never throws.
abstract interface class TipStoreService {
  /// The tip sizes the store lists, smallest first.
  Future<Result<List<TipProduct>, TipFailure>> products();

  /// Buys one [size] and completes with the way it ended.
  Future<TipOutcome> buy(TipSize size);
}

/// [TipStoreService] on the `in_app_purchase` plugin.
class InAppPurchaseTipStore implements TipStoreService {
  InAppPurchaseTipStore(this._iap);

  final InAppPurchase _iap;
  final Map<TipSize, ProductDetails> _details = {};

  @override
  Future<Result<List<TipProduct>, TipFailure>> products() async {
    try {
      if (!await _iap.isAvailable()) {
        return const Err(TipFailure.storeUnavailable);
      }
      final response = await _iap.queryProductDetails({
        for (final s in TipSize.values) s.productId,
      });
      if (response.error != null) {
        return const Err(TipFailure.storeUnavailable);
      }
      _details.clear();
      for (final size in TipSize.values) {
        for (final d in response.productDetails) {
          if (d.id == size.productId) _details[size] = d;
        }
      }
      if (_details.isEmpty) return const Err(TipFailure.productsUnavailable);
      return Ok([
        for (final size in TipSize.values)
          if (_details[size] case final d?)
            TipProduct(size: size, price: d.price),
      ]);
    } on Object {
      // The plugin throws when no store is registered (Linux harness) or the
      // platform channel fails: either way the store cannot be used.
      return const Err(TipFailure.storeUnavailable);
    }
  }

  @override
  Future<TipOutcome> buy(TipSize size) async {
    final details = _details[size];
    if (details == null) return const TipFailed(TipFailure.productsUnavailable);
    final done = Completer<TipOutcome>();
    void finish(TipOutcome outcome) {
      if (!done.isCompleted) done.complete(outcome);
    }

    final sub = _iap.purchaseStream.listen(
      (purchases) {
        for (final p in purchases) {
          if (p.productID != size.productId) continue;
          switch (p.status) {
            case PurchaseStatus.pending:
              // Ask to buy or a slow payment: keep waiting for the store.
              break;
            case PurchaseStatus.canceled:
              finish(const TipCancelled());
            case PurchaseStatus.error:
              finish(const TipFailed(TipFailure.purchaseFailed));
            case PurchaseStatus.purchased || PurchaseStatus.restored:
              unawaited(_complete(p, finish));
          }
        }
      },
      onError: (Object _) => finish(const TipFailed(TipFailure.purchaseFailed)),
    );
    try {
      final started = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!started) finish(const TipFailed(TipFailure.purchaseFailed));
      return await done.future;
    } on Object {
      return const TipFailed(TipFailure.purchaseFailed);
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _complete(
    PurchaseDetails p,
    void Function(TipOutcome) finish,
  ) async {
    try {
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      finish(const TipThanks());
    } on Object {
      finish(const TipFailed(TipFailure.purchaseFailed));
    }
  }
}
