import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mitlio/features/support/data/services/tip_store_service.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The plugin's entry point with scripted answers; only what the tip store
/// uses is implemented.
class _FakeIap implements InAppPurchase {
  bool available = true;
  Exception? throwOnQuery;
  Exception? throwOnBuy;
  bool buyStarts = true;
  IAPError? queryError;
  List<String> listed = [for (final s in TipSize.values) s.productId];
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  Exception? throwOnComplete;

  /// What the store "sends" once a purchase was started.
  void Function()? onBuy;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => stream.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    final e = throwOnQuery;
    if (e != null) throw e;
    return ProductDetailsResponse(
      productDetails: [
        for (final id in listed.where(ids.contains))
          ProductDetails(
            id: id,
            title: id,
            description: '',
            price: '1,00 €',
            rawPrice: 1,
            currencyCode: 'EUR',
          ),
      ],
      notFoundIDs: const [],
      error: queryError,
    );
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    final e = throwOnBuy;
    if (e != null) throw e;
    if (buyStarts) scheduleMicrotask(() => onBuy?.call());
    return buyStarts;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    final e = throwOnComplete;
    if (e != null) throw e;
    completed.add(purchase);
  }

  void send(
    PurchaseStatus status, {
    String productId = 'tip_small',
    bool pendingComplete = false,
  }) => stream.add([
    PurchaseDetails(
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: status,
    )..pendingCompletePurchase = pendingComplete,
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeIap iap;
  late InAppPurchaseTipStore store;

  setUp(() {
    iap = _FakeIap();
    store = InAppPurchaseTipStore(iap);
  });

  group('products', () {
    test('lists the three sizes smallest first with the store price', () async {
      final r = await store.products();
      expect(r, isA<Ok<List<TipProduct>, TipFailure>>());
      final list = (r as Ok<List<TipProduct>, TipFailure>).value;
      expect(list.map((p) => p.size), TipSize.values);
      expect(list.first.price, '1,00 €');
    });

    test('lists only what the store has', () async {
      iap.listed = ['tip_large'];
      final r = await store.products() as Ok<List<TipProduct>, TipFailure>;
      expect(r.value.map((p) => p.size), [TipSize.large]);
    });

    test('no store on the device', () async {
      iap.available = false;
      expect(
        await store.products(),
        const Err<List<TipProduct>, TipFailure>(TipFailure.storeUnavailable),
      );
    });

    test('a store error', () async {
      iap.queryError = IAPError(source: 'test', code: 'x', message: 'down');
      expect(
        await store.products(),
        const Err<List<TipProduct>, TipFailure>(TipFailure.storeUnavailable),
      );
    });

    test('the plugin throwing is an unavailable store, not a crash', () async {
      iap.throwOnQuery = Exception('no platform');
      expect(
        await store.products(),
        const Err<List<TipProduct>, TipFailure>(TipFailure.storeUnavailable),
      );
    });

    test('a store without the tip products', () async {
      iap.listed = [];
      expect(
        await store.products(),
        const Err<List<TipProduct>, TipFailure>(TipFailure.productsUnavailable),
      );
    });
  });

  group('buy', () {
    setUp(() async => store.products());

    test('before the products loaded', () async {
      final fresh = InAppPurchaseTipStore(iap);
      expect(
        await fresh.buy(TipSize.small),
        const TipFailed(TipFailure.productsUnavailable),
      );
    });

    test('purchased is thanks and completes the transaction', () async {
      iap.onBuy = () =>
          iap.send(PurchaseStatus.purchased, pendingComplete: true);
      expect(await store.buy(TipSize.small), const TipThanks());
      expect(iap.completed, hasLength(1));
    });

    test('a purchase that needs no completion is not completed', () async {
      iap.onBuy = () => iap.send(PurchaseStatus.purchased);
      expect(await store.buy(TipSize.small), const TipThanks());
      expect(iap.completed, isEmpty);
    });

    test('restored counts as thanks too', () async {
      iap.onBuy = () => iap.send(PurchaseStatus.restored);
      expect(await store.buy(TipSize.small), const TipThanks());
    });

    test('canceled is a cancel', () async {
      iap.onBuy = () => iap.send(PurchaseStatus.canceled);
      expect(await store.buy(TipSize.small), const TipCancelled());
    });

    test('error is a failed purchase', () async {
      iap.onBuy = () => iap.send(PurchaseStatus.error);
      expect(
        await store.buy(TipSize.small),
        const TipFailed(TipFailure.purchaseFailed),
      );
    });

    test('pending waits for the final answer', () async {
      iap.onBuy = () {
        iap.send(PurchaseStatus.pending);
        scheduleMicrotask(() => iap.send(PurchaseStatus.purchased));
      };
      expect(await store.buy(TipSize.small), const TipThanks());
    });

    test('updates of other products are ignored', () async {
      iap.onBuy = () {
        iap.send(PurchaseStatus.error, productId: 'tip_large');
        scheduleMicrotask(() => iap.send(PurchaseStatus.purchased));
      };
      expect(await store.buy(TipSize.small), const TipThanks());
    });

    test('the store refusing to start the purchase', () async {
      iap.buyStarts = false;
      expect(
        await store.buy(TipSize.small),
        const TipFailed(TipFailure.purchaseFailed),
      );
    });

    test('the plugin throwing', () async {
      iap.throwOnBuy = Exception('boom');
      expect(
        await store.buy(TipSize.small),
        const TipFailed(TipFailure.purchaseFailed),
      );
    });

    test('a transaction that cannot be completed is a failure', () async {
      iap
        ..throwOnComplete = Exception('boom')
        ..onBuy = () =>
            iap.send(PurchaseStatus.purchased, pendingComplete: true);
      expect(
        await store.buy(TipSize.small),
        const TipFailed(TipFailure.purchaseFailed),
      );
    });

    test('a broken update stream is a failure', () async {
      iap.onBuy = () => iap.stream.addError(Exception('boom'));
      expect(
        await store.buy(TipSize.small),
        const TipFailed(TipFailure.purchaseFailed),
      );
    });
  });
}
