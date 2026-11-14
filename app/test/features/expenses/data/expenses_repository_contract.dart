import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

/// Behaviour every `ExpensesRepository` must show.
void runExpensesRepositoryContract(
  String name,
  Future<Repos> Function() create,
) {
  group('ExpensesRepository contract ($name)', () {
    late Repos r;
    late String gid;
    late List<GroupMember> m;
    setUp(() async {
      r = await create();
      final seeded = await seedGroup(r);
      gid = seeded.groupId;
      m = seeded.members;
    });

    ExpenseDraft draft({
      String title = 'Dinner',
      int amount = 1000,
      Map<String, int>? payers,
      SplitSpec? split,
      DateTime? date,
      String? category,
      String? tripMeta,
    }) => ExpenseDraft(
      title: title,
      amountCents: amount,
      currency: eur,
      date: date ?? DateTime.utc(2026, 2),
      payers: payers ?? {m[0].id: amount},
      split: split ?? EqualSplit({m[0].id, m[1].id, m[2].id}),
      category: category,
      tripMeta: tripMeta,
    );

    Future<ExpenseEntry> add([ExpenseDraft? d]) async =>
        ok(await r.expenses.create(gid, d ?? draft()));

    test('create rebuilds the aggregate through the domain', () async {
      final e = await add(draft(title: ' Dinner ', category: 'food'));
      expect(e.groupId, gid);
      expect(e.expense.title, 'Dinner');
      expect(e.expense.amountCents, 1000);
      expect(e.expense.currency, eur);
      expect(e.expense.date, DateTime.utc(2026, 2));
      expect(e.expense.payers, {m[0].id: 1000});
      expect(e.expense.shares, {m[0].id: 334, m[1].id: 333, m[2].id: 333});
      expect(e.split, EqualSplit({m[0].id, m[1].id, m[2].id}));
      expect(e.category, 'food');
      expect(e.createdAt, DateTime.utc(2026, 3, 1, 12));
      expect(ok(await r.expenses.get(e.expense.id)), e);
    });

    test('tripMeta is stored and returned, and can be replaced', () async {
      final trip = await add(draft(tripMeta: '{"v":1}'));
      expect(trip.tripMeta, '{"v":1}');
      expect(ok(await r.expenses.get(trip.expense.id)).tripMeta, '{"v":1}');
      final updated = ok(
        await r.expenses.update(trip.expense.id, draft(tripMeta: '{"v":2}')),
      );
      expect(updated.tripMeta, '{"v":2}');
      expect((await add()).tripMeta, isNull);
    });

    test('every split mode round-trips for re-editing', () async {
      final specs = <SplitSpec>[
        EqualSplit({m[0].id, m[2].id}),
        SharesSplit({m[0].id: 2, m[1].id: 1}),
        PercentSplit({m[0].id: 7000, m[1].id: 3000}),
        ExactSplit({m[0].id: 400, m[2].id: 600}),
      ];
      for (final spec in specs) {
        final e = await add(draft(split: spec));
        expect(e.split, spec, reason: '$spec');
        final reloaded = ok(await r.expenses.get(e.expense.id));
        expect(reloaded.split, spec, reason: '$spec');
        expect(reloaded.expense.shares, e.expense.shares);
        expect(reloaded, e);
      }
    });

    test('multiple payers are stored', () async {
      final e = await add(
        draft(payers: {m[0].id: 600, m[1].id: 400}),
      );
      expect(e.expense.payers, {m[0].id: 600, m[1].id: 400});
    });

    test('invalid drafts are InvalidData and store nothing', () async {
      final bad = <ExpenseDraft>[
        draft(title: ' '),
        draft(amount: 0, payers: {m[0].id: 0}),
        draft(payers: {m[0].id: 999}),
        draft(payers: {'ghost': 1000}),
        draft(split: EqualSplit({'ghost'})),
        draft(split: PercentSplit({m[0].id: 5000})),
      ];
      for (final d in bad) {
        expect(err(await r.expenses.create(gid, d)), isA<InvalidData>());
      }
      final probe = StreamProbe(r.expenses.watchExpenses(gid));
      expect(await probe.next(), isEmpty);
    });

    test('a foreign currency is rejected', () async {
      final d = ExpenseDraft(
        title: 'Taxi',
        amountCents: 500,
        currency: Currency.usd,
        date: DateTime.utc(2026),
        payers: {m[0].id: 500},
        split: EqualSplit({m[0].id}),
      );
      expect(err(await r.expenses.create(gid, d)), isA<InvalidData>());
    });

    group('foreign currency (P7-T01)', () {
      ExpenseDraft usd({
        int foreignCents = 1000,
        int ppm = 920000,
        int? groupCents,
        Currency foreignCurrency = Currency.usd,
      }) {
        final inGroup =
            groupCents ??
            convert(
              Money(foreignCents, foreignCurrency),
              eur,
              FxRate(ppm),
            ).cents;
        return ExpenseDraft(
          title: 'Taxi',
          amountCents: inGroup,
          currency: eur,
          date: DateTime.utc(2026, 2),
          payers: {m[0].id: inGroup},
          split: EqualSplit({m[0].id, m[1].id, m[2].id}),
          foreign: ForeignAmount(
            currency: foreignCurrency,
            amountCents: foreignCents,
            ratePpm: ppm,
          ),
        );
      }

      test(
        'stores the original, the frozen rate and the group amount',
        () async {
          final e = await add(usd());
          expect(e.expense.amountCents, 920);
          expect(e.expense.currency, eur);
          expect(e.expense.shares, {m[0].id: 307, m[1].id: 307, m[2].id: 306});
          expect(
            e.foreign,
            const ForeignAmount(
              currency: Currency.usd,
              amountCents: 1000,
              ratePpm: 920000,
            ),
          );
          expect(ok(await r.expenses.get(e.expense.id)), e);
          final probe = StreamProbe(r.expenses.watchExpenses(gid));
          expect((await probe.next()).single, e);
        },
      );

      test('a zero-decimal currency converts on the major unit', () async {
        final e = await add(
          usd(foreignCents: 12340, ppm: 1600, foreignCurrency: Currency.jpy),
        );
        expect(e.expense.amountCents, 1974);
        expect(e.foreign!.amountCents, 12340);
      });

      test('update can add and drop the foreign part', () async {
        final plain = await add();
        final toUsd = ok(
          await r.expenses.update(plain.expense.id, usd()),
        );
        expect(toUsd.foreign!.ratePpm, 920000);
        final back = ok(await r.expenses.update(plain.expense.id, draft()));
        expect(back.foreign, isNull);
        expect(back.expense.amountCents, 1000);
      });

      test('a group amount that does not match the rate is rejected', () async {
        for (final d in [
          usd(groupCents: 921),
          usd(ppm: 0, groupCents: 1000),
          usd(foreignCents: 0, groupCents: 1000),
          usd(foreignCurrency: eur, groupCents: 1000),
          usd(
            foreignCents: Money.maxAbsCents,
            ppm: 999999999,
            groupCents: 1000,
          ),
        ]) {
          expect(err(await r.expenses.create(gid, d)), isA<InvalidData>());
        }
      });
    });

    test('create in an unknown or deleted group is NotFound', () async {
      expect(err(await r.expenses.create('nope', draft())), isA<NotFound>());
      ok(await r.groups.softDelete(gid));
      expect(err(await r.expenses.create(gid, draft())), isA<NotFound>());
    });

    test('a soft-deleted member cannot be used for new expenses', () async {
      ok(await r.members.softDelete(m[1].id));
      expect(
        err(await r.expenses.create(gid, draft(payers: {m[1].id: 1000}))),
        isA<InvalidData>(),
      );
    });

    test('update replaces the whole aggregate and keeps createdAt', () async {
      final e = await add();
      r.clock.advance(const Duration(hours: 1));
      final u = ok(
        await r.expenses.update(
          e.expense.id,
          draft(
            title: 'Lunch',
            amount: 900,
            payers: {m[1].id: 900},
            split: SharesSplit({m[0].id: 1, m[1].id: 2}),
            category: 'food',
          ),
        ),
      );
      expect(u.expense.id, e.expense.id);
      expect(u.expense.title, 'Lunch');
      expect(u.expense.payers, {m[1].id: 900});
      expect(u.expense.shares, {m[0].id: 300, m[1].id: 600, m[2].id: 0});
      expect(u.split, SharesSplit({m[0].id: 1, m[1].id: 2}));
      expect(u.createdAt, e.createdAt);
      expect(ok(await r.expenses.get(e.expense.id)), u);
    });

    test('update errors leave the expense untouched', () async {
      final e = await add();
      expect(
        err(await r.expenses.update(e.expense.id, draft(title: ''))),
        isA<InvalidData>(),
      );
      expect(err(await r.expenses.update('nope', draft())), isA<NotFound>());
      expect(ok(await r.expenses.get(e.expense.id)), e);
    });

    test('soft delete hides, undo restores, errors are typed', () async {
      final e = await add();
      final undo = ok(await r.expenses.softDelete(e.expense.id));
      expect(err(await r.expenses.get(e.expense.id)), isA<NotFound>());
      expect(
        err(await r.expenses.update(e.expense.id, draft())),
        isA<NotFound>(),
      );
      expect(err(await r.expenses.softDelete(e.expense.id)), isA<NotFound>());
      ok(await undo());
      expect(ok(await r.expenses.get(e.expense.id)), e);
      expect(err(await r.expenses.restore(e.expense.id)), isA<Conflict>());
      expect(err(await r.expenses.restore('nope')), isA<NotFound>());
      expect(err(await r.expenses.softDelete('nope')), isA<NotFound>());
    });

    test('expenses of a deleted member stay readable', () async {
      final e = await add(draft(payers: {m[1].id: 1000}));
      ok(await r.members.softDelete(m[1].id));
      expect(ok(await r.expenses.get(e.expense.id)), e);
    });

    test('get of an unknown id is NotFound', () async {
      expect(err(await r.expenses.get('nope')), isA<NotFound>());
    });

    test('watchExpenses: initial value, changes, newest date first', () async {
      final probe = StreamProbe(r.expenses.watchExpenses(gid));
      expect(await probe.next(), isEmpty);

      final older = await add(draft(date: DateTime.utc(2026)));
      expect(await probe.next(), [older]);

      final newer = await add(
        draft(title: 'Newer', date: DateTime.utc(2026, 5)),
      );
      expect(await probe.next(), [newer, older]);

      final u = ok(
        await r.expenses.update(older.expense.id, draft(title: 'Older')),
      );
      expect(await probe.next(), [newer, u]);

      final undo = ok(await r.expenses.softDelete(newer.expense.id));
      expect(await probe.next(), [u]);
      ok(await undo());
      expect(await probe.next(), [newer, u]);
    });
  });
}
