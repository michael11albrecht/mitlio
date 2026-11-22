import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/recurring.dart';

import '../features/expenses/ui/expenses_fixtures.dart';

void main() {
  late ExpensesApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;

  String id(int i) => app.people[i].id;

  Map<String, String> params({Map<String, String> extra = const {}}) => {
    'groupId': app.trip.id,
    'title': 'Miete',
    'amountCents': '90000',
    'frequency': 'monthly',
    ...extra,
  };

  setUp(() async {
    app = ExpensesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedTrip();
    h = recurringDriveHandlers(container);
  });

  group('recurring.create', () {
    test('defaults: starts today, first member pays, equal split', () async {
      final r = await h['recurring.create']!(params());
      expect(r, {
        'id': 'rec-1',
        'groupId': app.trip.id,
        'title': 'Miete',
        'amountCents': 90000,
        'payers': {id(0): 90000},
        'category': null,
        'frequency': 'monthly',
        'interval': 1,
        'start': '2026-03-01',
        'end': null,
        'lastGenerated': null,
        'next': '2026-04-01',
        'paused': false,
      });
    });

    test('takes start, end, interval, payers, split and category', () async {
      final r = await h['recurring.create']!(
        params(
          extra: {
            'frequency': 'weekly',
            'interval': '2',
            'start': '2026-01-05',
            'end': '2026-12-31',
            'payers': jsonEncode({id(1): 90000}),
            'split': jsonEncode({
              'mode': 'shares',
              'weights': {id(0): 2, id(1): 1},
            }),
            'category': 'stay',
            'lastGenerated': '2026-02-16',
          },
        ),
      );
      expect(r['error'], isNull);
      expect(r['payers'], {id(1): 90000});
      expect(r['interval'], 2);
      expect(r['end'], '2026-12-31');
      expect(r['category'], 'stay');
      expect(r['lastGenerated'], '2026-02-16');
    });

    test('rejects missing and malformed params', () async {
      for (final bad in <Map<String, String>>[
        {'groupId': app.trip.id},
        params(extra: {'frequency': 'hourly'}),
        params(extra: {'amountCents': 'x'}),
        params(extra: {'start': '1.3.2026'}),
        params(extra: {'end': 'soon'}),
        params(extra: {'payers': 'nope'}),
        params(extra: {'split': '{"mode":"x"}'}),
        params(extra: {'interval': '0'}),
        params(extra: {'start': '2026-03-02', 'end': '2026-03-01'}),
      ]) {
        expect((await h['recurring.create']!(bad))['error'], 'invalid_params');
      }
      expect((await h['recurring.create']!({}))['error'], 'invalid_params');
    });

    test('what the domain refuses is invalid_params, not stored', () async {
      final r = await h['recurring.create']!(
        params(
          extra: {
            'payers': jsonEncode({id(0): 5}),
          },
        ),
      );
      expect(r['error'], 'invalid_params');
      expect(
        (await h['recurring.list']!({'groupId': app.trip.id}))['rules'],
        isEmpty,
      );
    });

    test('a storage failure is internal', () async {
      app.base.recurring.failWith = const Storage('disk');
      expect((await h['recurring.create']!(params()))['error'], 'internal');
    });
  });

  test('update, list, pause, resume and delete', () async {
    final created = await h['recurring.create']!(params());
    final rid = created['id']! as String;

    final updated = await h['recurring.update']!({
      'id': rid,
      'title': 'Miete neu',
      'amountCents': '95000',
      'frequency': 'yearly',
    });
    expect(updated['title'], 'Miete neu');
    expect(updated['frequency'], 'yearly');

    final listed = await h['recurring.list']!({'groupId': app.trip.id});
    expect((listed['rules']! as List).single, updated);

    final paused = await h['recurring.pause']!({'id': rid});
    expect(paused['paused'], isTrue);
    final resumed = await h['recurring.pause']!({'id': rid, 'paused': 'false'});
    expect(resumed['paused'], isFalse);

    expect(await h['recurring.delete']!({'id': rid}), {'id': rid});
    expect(
      (await h['recurring.list']!({'groupId': app.trip.id}))['rules'],
      isEmpty,
    );
  });

  test('unknown ids are not_found, missing params invalid', () async {
    for (final call in [
      h['recurring.update']!({'id': 'nope', ...params()}),
      h['recurring.pause']!({'id': 'nope'}),
      h['recurring.delete']!({'id': 'nope'}),
    ]) {
      expect((await call)['error'], 'not_found');
    }
    for (final call in [
      h['recurring.update']!({}),
      h['recurring.pause']!({}),
      h['recurring.pause']!({'id': 'x', 'paused': 'maybe'}),
      h['recurring.delete']!({}),
      h['recurring.list']!({}),
    ]) {
      expect((await call)['error'], 'invalid_params');
    }
  });

  test('catchUp makes what is due and reports failures', () async {
    await h['recurring.create']!(params(extra: {'start': '2026-01-31'}));
    final failing = await (() async {
      app.expenses.failWith = const Storage('disk');
      return h['recurring.catchUp']!({});
    })();
    expect(failing['created'], 0);
    expect((failing['failures']! as List).single, {
      'title': 'Miete',
      'error': 'Storage(disk)',
    });
    app.expenses.failWith = null;
    final done = await h['recurring.catchUp']!({});
    expect(done['created'], 2);
    expect(done['skipped'], 0);
    expect(done['failures'], isEmpty);
    expect((await h['recurring.catchUp']!({}))['created'], 0);
  });
}
