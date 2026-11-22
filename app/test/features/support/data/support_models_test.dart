import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/support/data/support_models.dart';

void main() {
  test('product ids are the three consumables of the stores', () {
    expect(TipSize.values.map((s) => s.productId), [
      'tip_small',
      'tip_medium',
      'tip_large',
    ]);
  });

  test('values have equality and a readable form', () {
    const p = TipProduct(size: TipSize.small, price: '1 €');
    expect(p, const TipProduct(size: TipSize.small, price: '1 €'));
    expect(
      p.hashCode,
      const TipProduct(size: TipSize.small, price: '1 €').hashCode,
    );
    expect(p, isNot(const TipProduct(size: TipSize.large, price: '1 €')));
    expect('$p', contains('small'));

    const f = TipFailed(TipFailure.purchaseFailed);
    expect(f, const TipFailed(TipFailure.purchaseFailed));
    expect(f.hashCode, const TipFailed(TipFailure.purchaseFailed).hashCode);
    expect(f, isNot(const TipFailed(TipFailure.storeUnavailable)));
    expect('$f', contains('purchaseFailed'));
  });

  test('prompt state copies and compares', () {
    final at = DateTime.utc(2026, 12);
    final s = SupportPromptState(settledSinceShown: 2, lastShown: at);
    expect(s.copyWith(dismissed: true).dismissed, isTrue);
    expect(s.copyWith(dismissed: true).lastShown, at);
    expect(s.copyWith(settledSinceShown: 3).settledSinceShown, 3);
    expect(s, SupportPromptState(settledSinceShown: 2, lastShown: at));
    expect(
      s.hashCode,
      SupportPromptState(settledSinceShown: 2, lastShown: at).hashCode,
    );
    expect(s, isNot(const SupportPromptState()));
    expect('$s', contains('2'));
  });
}
