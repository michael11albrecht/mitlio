import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/expenses/data/expense_revision.dart';

ExpenseSnapshot snap({
  String title = 'Dinner',
  int amount = 1000,
  String currency = 'EUR',
  int fx = 1000000,
  int groupAmount = 1000,
  DateTime? date,
  String? category,
  String splitMode = 'equal',
  String? tripMeta,
  Map<String, int>? payers,
  Map<String, int>? shares,
  Map<String, int>? weights,
}) => ExpenseSnapshot(
  title: title,
  amountCents: amount,
  currency: currency,
  fxRatePpm: fx,
  groupAmountCents: groupAmount,
  date: date ?? DateTime.utc(2026, 2),
  category: category,
  type: tripMeta == null ? 'regular' : 'trip',
  splitMode: splitMode,
  tripMeta: tripMeta,
  payers: payers ?? {'a': 1000},
  shares: shares ?? {'a': 500, 'b': 500},
  weights: weights ?? {'a': 1, 'b': 1},
);

void main() {
  group('diffSnapshots', () {
    test('identical snapshots have no changes', () {
      expect(diffSnapshots(snap(), snap()), isEmpty);
    });

    test('title', () {
      final c = diffSnapshots(snap(), snap(title: 'Lunch')).single;
      expect(c, isA<TitleChange>());
      expect((c as TitleChange).from, 'Dinner');
      expect(c.to, 'Lunch');
    });

    test('amount in the same currency, total change hides share noise', () {
      final changes = diffSnapshots(
        snap(),
        snap(
          amount: 1500,
          groupAmount: 1500,
          payers: {'a': 1500},
          shares: {'a': 750, 'b': 750},
        ),
      );
      expect(changes.map((c) => c.runtimeType), [AmountChange, PaidChange]);
      final amount = changes.first as AmountChange;
      expect(
        (
          amount.fromCents,
          amount.fromCurrency,
          amount.toCents,
          amount.toCurrency,
        ),
        (1000, 'EUR', 1500, 'EUR'),
      );
    });

    test('currency change and rate change', () {
      final changes = diffSnapshots(
        snap(),
        snap(currency: 'USD', fx: 920000, groupAmount: 920),
      );
      expect(changes.map((c) => c.runtimeType), [AmountChange, RateChange]);
    });

    test('date, category, split mode and trip details', () {
      final changes = diffSnapshots(
        snap(category: 'food'),
        snap(
          date: DateTime.utc(2026, 2, 3),
          category: 'fun',
          splitMode: 'shares',
          tripMeta: '{"v":1}',
        ),
      );
      expect(changes.map((c) => c.runtimeType), [
        DateChange,
        CategoryChange,
        SplitModeChange,
        TripDetailsChange,
      ]);
      expect((changes[1] as CategoryChange).from, 'food');
      expect((changes[1] as CategoryChange).to, 'fun');
      expect((changes[0] as DateChange).to, DateTime.utc(2026, 2, 3));
      expect((changes[2] as SplitModeChange).to, 'shares');
    });

    test('category set from and cleared to null', () {
      final set = diffSnapshots(snap(), snap(category: 'food')).single;
      expect((set as CategoryChange).from, isNull);
      final cleared = diffSnapshots(snap(category: 'food'), snap()).single;
      expect((cleared as CategoryChange).to, isNull);
    });

    test('payers added, removed and re-amounted, sorted by member id', () {
      final changes = diffSnapshots(
        snap(payers: {'a': 600, 'b': 400}),
        snap(payers: {'a': 700, 'c': 300}),
      );
      expect(changes.map((c) => c.runtimeType), [
        PaidChange,
        PayerRemoved,
        PayerAdded,
      ]);
      final paid = changes[0] as PaidChange;
      expect((paid.memberId, paid.fromCents, paid.toCents), ('a', 600, 700));
      expect((changes[1] as PayerRemoved).memberId, 'b');
      expect((changes[2] as PayerAdded).memberId, 'c');
    });

    test('participant removed ("no longer involved") and added', () {
      final changes = diffSnapshots(
        snap(),
        snap(
          shares: {'a': 500, 'b': 0, 'c': 500},
          weights: {'a': 1, 'b': 0, 'c': 1},
        ),
      );
      expect(changes.map((c) => c.runtimeType), [
        ParticipantRemoved,
        ParticipantAdded,
      ]);
      expect((changes[0] as ParticipantRemoved).memberId, 'b');
      expect((changes[1] as ParticipantAdded).memberId, 'c');
    });

    test('share change is reported only when the total is unchanged', () {
      final changes = diffSnapshots(
        snap(),
        snap(shares: {'a': 700, 'b': 300}),
      );
      expect(changes, hasLength(2));
      final share = changes.first as ShareChange;
      expect((share.memberId, share.fromCents, share.toCents), ('a', 500, 700));
    });
  });

  group('ExpenseSnapshot', () {
    test('json round trip keeps everything', () {
      final s = snap(
        category: 'food',
        tripMeta: '{"v":1}',
        splitMode: 'shares',
        weights: {'a': 2, 'b': 1},
      );
      final back = ExpenseSnapshot.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
      );
      expect(back, s);
      expect(back.hashCode, s.hashCode);
      expect(back.weights, {'a': 2, 'b': 1});
    });

    test('server snapshots nest trip meta as json', () {
      final json = snap(tripMeta: '{"v":1}').toJson()..['trip_meta'] = {'v': 1};
      expect(ExpenseSnapshot.fromJson(json).tripMeta, '{"v":1}');
      expect(ExpenseSnapshot.fromJson(snap().toJson()).tripMeta, isNull);
    });

    test('equality distinguishes every field', () {
      final base = snap();
      expect(base == snap(), isTrue);
      expect(base == snap(title: 'x'), isFalse);
      expect(base == snap(amount: 1), isFalse);
      expect(base == snap(currency: 'USD'), isFalse);
      expect(base == snap(fx: 1), isFalse);
      expect(base == snap(groupAmount: 1), isFalse);
      expect(base == snap(date: DateTime.utc(2027)), isFalse);
      expect(base == snap(category: 'x'), isFalse);
      expect(base == snap(splitMode: 'shares'), isFalse);
      expect(base == snap(tripMeta: '{}'), isFalse);
      expect(base == snap(payers: {'b': 1000}), isFalse);
      expect(base == snap(shares: {'a': 1000}), isFalse);
      expect(base == snap(weights: {'a': 1}), isFalse);
      expect(base.toString(), contains('Dinner'));
    });

    test('never contains bank data', () {
      final json = jsonEncode(snap().toJson()).toLowerCase();
      expect(json, isNot(contains('iban')));
      expect(json, isNot(contains('bic')));
      expect(json, isNot(contains('bank')));
    });
  });

  test('ExpenseRevision equality and toString', () {
    ExpenseRevision rev({int n = 1, String? author}) => ExpenseRevision(
      id: 'r',
      expenseId: 'e',
      groupId: 'g',
      revision: n,
      changedAt: DateTime.utc(2026),
      authorMemberId: author,
      snapshot: snap(),
    );
    expect(rev(), rev());
    expect(rev().hashCode, rev().hashCode);
    expect(rev() == rev(n: 2), isFalse);
    expect(rev() == rev(author: 'a'), isFalse);
    expect(rev().toString(), 'ExpenseRevision(e #1)');
  });
}
