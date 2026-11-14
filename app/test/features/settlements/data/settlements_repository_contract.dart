import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

/// Behaviour every `SettlementsRepository` must show.
void runSettlementsRepositoryContract(
  String name,
  Future<Repos> Function() create,
) {
  group('SettlementsRepository contract ($name)', () {
    late Repos r;
    late String gid;
    late List<GroupMember> m;
    setUp(() async {
      r = await create();
      final seeded = await seedGroup(r);
      gid = seeded.groupId;
      m = seeded.members;
    });

    SettlementDraft draft({
      int from = 1,
      int to = 0,
      int amount = 500,
      DateTime? date,
      SettlementMethod method = SettlementMethod.cash,
      Currency? currency,
    }) => SettlementDraft(
      fromId: m[from].id,
      toId: m[to].id,
      amountCents: amount,
      currency: currency ?? eur,
      date: date ?? DateTime.utc(2026, 2, 2),
      method: method,
    );

    Future<SettlementEntry> add([SettlementDraft? d]) async =>
        ok(await r.settlements.create(gid, d ?? draft()));

    test('create stores a validated settlement', () async {
      final s = await add(draft(method: SettlementMethod.paypal));
      expect(s.groupId, gid);
      expect(s.settlement.fromId, m[1].id);
      expect(s.settlement.toId, m[0].id);
      expect(s.settlement.amountCents, 500);
      expect(s.settlement.currency, eur);
      expect(s.settlement.date, DateTime.utc(2026, 2, 2));
      expect(s.method, SettlementMethod.paypal);
      expect(s.createdAt, DateTime.utc(2026, 3, 1, 12));
      expect(ok(await r.settlements.get(s.settlement.id)), s);
    });

    test('invalid drafts are InvalidData', () async {
      final bad = [
        draft(amount: 0),
        draft(to: 1),
        draft(currency: Currency.usd),
        SettlementDraft(
          fromId: 'ghost',
          toId: m[0].id,
          amountCents: 1,
          currency: eur,
          date: DateTime.utc(2026),
          method: SettlementMethod.other,
        ),
      ];
      for (final d in bad) {
        expect(err(await r.settlements.create(gid, d)), isA<InvalidData>());
      }
    });

    test('create in an unknown group is NotFound', () async {
      expect(err(await r.settlements.create('nope', draft())), isA<NotFound>());
    });

    test('a soft-deleted member cannot be used for new settlements', () async {
      ok(await r.members.softDelete(m[1].id));
      expect(err(await r.settlements.create(gid, draft())), isA<InvalidData>());
    });

    test('update changes amount, method and date only', () async {
      final s = await add();
      final u = ok(
        await r.settlements.update(
          s.settlement.id,
          amountCents: 700,
          method: SettlementMethod.sepa,
          date: DateTime.utc(2026, 4),
        ),
      );
      expect(u.settlement.amountCents, 700);
      expect(u.method, SettlementMethod.sepa);
      expect(u.settlement.date, DateTime.utc(2026, 4));
      expect(u.settlement.fromId, s.settlement.fromId);
      expect(u.createdAt, s.createdAt);
      expect(ok(await r.settlements.get(s.settlement.id)), u);
    });

    test('update errors leave the settlement untouched', () async {
      final s = await add();
      expect(
        err(
          await r.settlements.update(
            s.settlement.id,
            amountCents: 0,
            method: SettlementMethod.cash,
            date: DateTime.utc(2026),
          ),
        ),
        isA<InvalidData>(),
      );
      expect(
        err(
          await r.settlements.update(
            'nope',
            amountCents: 1,
            method: SettlementMethod.cash,
            date: DateTime.utc(2026),
          ),
        ),
        isA<NotFound>(),
      );
      expect(ok(await r.settlements.get(s.settlement.id)), s);
    });

    test(
      'settlements of a deleted member stay readable and editable',
      () async {
        final s = await add();
        ok(await r.members.softDelete(m[1].id));
        expect(ok(await r.settlements.get(s.settlement.id)), s);
        final u = ok(
          await r.settlements.update(
            s.settlement.id,
            amountCents: 600,
            method: SettlementMethod.cash,
            date: DateTime.utc(2026, 2, 2),
          ),
        );
        expect(u.settlement.amountCents, 600);
      },
    );

    test('soft delete hides, undo restores, errors are typed', () async {
      final s = await add();
      final undo = ok(await r.settlements.softDelete(s.settlement.id));
      expect(err(await r.settlements.get(s.settlement.id)), isA<NotFound>());
      expect(
        err(await r.settlements.softDelete(s.settlement.id)),
        isA<NotFound>(),
      );
      ok(await undo());
      expect(ok(await r.settlements.get(s.settlement.id)), s);
      expect(
        err(await r.settlements.restore(s.settlement.id)),
        isA<Conflict>(),
      );
      expect(err(await r.settlements.restore('nope')), isA<NotFound>());
      expect(err(await r.settlements.softDelete('nope')), isA<NotFound>());
    });

    test(
      'watchSettlements: initial value, changes, oldest date first',
      () async {
        final probe = StreamProbe(r.settlements.watchSettlements(gid));
        expect(await probe.next(), isEmpty);

        final later = await add(draft(date: DateTime.utc(2026, 5)));
        expect(await probe.next(), [later]);

        final earlier = await add(draft(date: DateTime.utc(2026, 3)));
        expect(await probe.next(), [earlier, later]);

        final undo = ok(await r.settlements.softDelete(earlier.settlement.id));
        expect(await probe.next(), [later]);
        ok(await undo());
        expect(await probe.next(), [earlier, later]);
      },
    );
  });
}
