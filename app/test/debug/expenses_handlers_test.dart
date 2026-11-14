import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/expenses.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';

import '../features/expenses/ui/expenses_fixtures.dart';

void main() {
  late ExpensesApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;

  String id(int i) => app.people[i].id;

  Map<String, String> params({
    String? title = 'Pizza',
    String? amount = '1000',
    Object? payers,
    Object? split,
    Map<String, String> extra = const {},
  }) => {
    'groupId': app.trip.id,
    'title': ?title,
    'amountCents': ?amount,
    'payers': jsonEncode(payers ?? {id(0): 1000}),
    if (split != null) 'split': jsonEncode(split),
    ...extra,
  };

  setUp(() async {
    app = ExpensesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedTrip();
    h = expensesDriveHandlers(container);
  });

  group('expenses.add', () {
    test('defaults: today, EUR, equal among everyone', () async {
      final r = await h['expenses.add']!(params());
      expect(r, {
        'id': 'ex-1',
        'title': 'Pizza',
        'amountCents': 1000,
        'currency': 'EUR',
        'date': '2026-03-01',
        'category': null,
        'payers': {id(0): 1000},
        'shares': {id(0): 334, id(1): 333, id(2): 333},
        'splitMode': 'equal',
      });
    });

    test('takes a date and a category', () async {
      final r = await h['expenses.add']!(
        params(extra: {'date': '2026-02-14', 'category': 'food'}),
      );
      expect(r['date'], '2026-02-14');
      expect(r['category'], 'food');
    });

    test('equal split among listed participants', () async {
      final r = await h['expenses.add']!(
        params(
          split: {
            'mode': 'equal',
            'participants': [id(0), id(1)],
          },
        ),
      );
      expect(r['shares'], {id(0): 500, id(1): 500, id(2): 0});
    });

    for (final (mode, weights) in [
      ('shares', {'a': 2, 'b': 1, 'c': 1}),
      ('percent', {'a': 5000, 'b': 2500, 'c': 2500}),
      ('exact', {'a': 500, 'b': 250, 'c': 250}),
    ]) {
      test('$mode split', () async {
        final r = await h['expenses.add']!(
          params(
            split: {
              'mode': mode,
              'weights': {
                id(0): weights['a'],
                id(1): weights['b'],
                id(2): weights['c'],
              },
            },
          ),
        );
        expect(r['splitMode'], mode);
        expect(r['shares'], {id(0): 500, id(1): 250, id(2): 250});
      });
    }

    test('a foreign currency with a frozen rate (P7-T01)', () async {
      final r = await h['expenses.add']!(
        params(
          payers: {id(0): 920},
          extra: {'currency': 'USD', 'fxRatePpm': '920000'},
        ),
      );
      expect(r['error'], isNull);
      expect(r['amountCents'], 920);
      expect(r['currency'], 'EUR');
      expect(r['payers'], {id(0): 920});
      expect(r['shares'], {id(0): 307, id(1): 307, id(2): 306});
      expect(r['foreign'], {
        'currency': 'USD',
        'amountCents': 1000,
        'fxRatePpm': 920000,
      });
      final list = await h['expenses.list']!({'groupId': app.trip.id});
      expect(((list['expenses']! as List).single as Map)['foreign'], isNotNull);
    });

    test('the group currency may be named explicitly', () async {
      final r = await h['expenses.add']!(params(extra: {'currency': 'EUR'}));
      expect(r['error'], isNull);
      expect(r.containsKey('foreign'), isFalse);
    });

    test(
      'a foreign currency needs a positive rate and matching payers',
      () async {
        Future<Map<String, Object?>> add(Map<String, String> extra) =>
            h['expenses.add']!(params(payers: {id(0): 920}, extra: extra));
        for (final extra in [
          {'currency': 'USD'},
          {'currency': 'USD', 'fxRatePpm': '0'},
          {'currency': 'USD', 'fxRatePpm': 'x'},
          {'currency': 'XXX', 'fxRatePpm': '920000'},
          {'currency': 'USD', 'fxRatePpm': '999999999999999999'},
        ]) {
          expect(
            (await add(extra))['error'],
            'invalid_params',
            reason: '$extra',
          );
        }
        // Payers are in the group currency: 1000 would not match 9,20 EUR.
        final r = await h['expenses.add']!(
          params(extra: {'currency': 'USD', 'fxRatePpm': '920000'}),
        );
        expect(r['message'], contains('PayersMismatch'));
      },
    );

    test('several payers', () async {
      final r = await h['expenses.add']!(
        params(payers: {id(0): 600, id(1): 400}),
      );
      expect(r['payers'], {id(0): 600, id(1): 400});
    });

    test('the list state shows the new expense', () async {
      await h['expenses.add']!(params());
      container.listen(expensesViewModelProvider(app.trip.id), (_, _) {});
      await pumpEventQueue();
      final snap = container
          .read(expensesViewModelProvider(app.trip.id).notifier)
          .debugSnapshot();
      expect(snap['status'], 'data');
    });

    test('validation errors are invalid_params with the reason', () async {
      final r = await h['expenses.add']!(
        params(
          split: {
            'mode': 'exact',
            'weights': {id(0): 1},
          },
        ),
      );
      expect(r['error'], 'invalid_params');
      expect(r['message'], contains('ExactMismatch'));
      expect(
        (await h['expenses.add']!(params(payers: {id(0): 5})))['message'],
        contains('PayersMismatch'),
      );
      expect(
        (await h['expenses.add']!(params(title: ' ')))['message'],
        contains('EmptyTitle'),
      );
    });

    test('malformed or missing params are invalid_params', () async {
      for (final bad in [
        <String, String>{},
        params(title: null),
        params(amount: null),
        params(amount: 'x'),
        params(extra: {'currency': 'XXX'}),
        params(extra: {'date': 'yesterday'}),
        params(extra: {'payers': 'not json'}),
        params(extra: {'payers': '{"a":"b"}'}),
        params(extra: {'payers': '[1]'}),
        params(extra: {'split': 'not json'}),
        params(extra: {'split': '[1]'}),
        params(extra: {'split': '{"mode":"equal","participants":[1]}'}),
        params(extra: {'split': '{"mode":"bogus","weights":{"a":1}}'}),
        params(extra: {'split': '{"mode":"shares","weights":{"a":"x"}}'}),
        params(extra: {'split': '{"mode":"shares"}'}),
      ]) {
        expect(
          (await h['expenses.add']!(bad))['error'],
          'invalid_params',
          reason: '$bad',
        );
      }
    });

    test('an unknown group is not_found', () async {
      final r = await h['expenses.add']!(
        params(extra: {'groupId': 'nope'}),
      );
      expect(r['error'], 'not_found');
    });

    test('a failing store is internal', () async {
      app.expenses.failWith = const Storage('x');
      expect((await h['expenses.add']!(params()))['error'], 'internal');
    });
  });

  group('expenses.list', () {
    test('returns every expense of the group', () async {
      expect(await h['expenses.list']!({'groupId': app.trip.id}), {
        'expenses': <Object?>[],
      });
      await h['expenses.add']!(params());
      final r = await h['expenses.list']!({'groupId': app.trip.id});
      expect(
        (r['expenses']! as List<Object?>).single,
        containsPair('title', 'Pizza'),
      );
    });

    test('needs a group id; a failing store is internal', () async {
      expect((await h['expenses.list']!({}))['error'], 'invalid_params');
      app.expenses.watchError = const Storage('x');
      expect(
        (await h['expenses.list']!({'groupId': app.trip.id}))['error'],
        'internal',
      );
    });
  });

  group('expenses.delete', () {
    test('soft deletes; the list no longer shows it', () async {
      final added = await h['expenses.add']!(params());
      final r = await h['expenses.delete']!({'id': added['id']! as String});
      expect(r, {'id': added['id']});
      expect(await h['expenses.list']!({'groupId': app.trip.id}), {
        'expenses': <Object?>[],
      });
    });

    test('validates params and maps errors', () async {
      expect((await h['expenses.delete']!({}))['error'], 'invalid_params');
      expect(
        (await h['expenses.delete']!({'id': 'nope'}))['error'],
        'not_found',
      );
      final added = await h['expenses.add']!(params());
      app.expenses.failWith = const Storage('x');
      expect(
        (await h['expenses.delete']!({'id': added['id']! as String}))['error'],
        'internal',
      );
    });
  });
}
