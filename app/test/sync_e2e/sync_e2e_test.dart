@Tags(['supabase'])
@Timeout(Duration(minutes: 8))
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio/features/sync/data/repositories/join_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'support/local_supabase.dart';
import 'support/phone.dart';

/// Two headless phones (real repositories, real SyncService, real Supabase
/// implementations, one anonymous account each) against the local stack. After
/// every scenario the canonical state of phone A, phone B and the server is
/// the same (ADR-27 §4, plan P6-T13).
void main() {
  final server = LocalSupabase.instance;
  late World world;

  setUp(() async {
    await server.wipe();
    world = World();
  });

  /// A and B hold, and the server stores, the same group.
  Future<Snapshot> expectConverged(
    Phone a,
    Phone b,
    String groupId, {
    String what = 'converged',
  }) async {
    final onA = await a.snapshot(groupId);
    final onB = await b.snapshot(groupId);
    final onServer = await a.server.snapshot(groupId);
    expectSame(onA, onServer, '$what: phone A vs server');
    expectSame(onB, onServer, '$what: phone B vs server');
    expect(onA.lines, isNotEmpty);
    return onA;
  }

  test(
    'a local group with history is shared and a second phone joins it',
    () async {
      final a = world.phone('A', 1);
      final b = world.phone('B', 2);
      final seeded = await a.seedGroup();
      final gid = seeded.groupId;
      final [ann, ben, cy] = seeded.members;

      final car = unwrap(
        await a.vehicles.add(
          gid,
          name: 'Golf',
          fuelType: FuelType.diesel,
          consumptionMilliPer100km: 5500,
          wearMilliPerKm: 80,
          kmRateMilliPerKm: 300,
        ),
      );
      expect(car.name, 'Golf');
      world.tick();
      final dinner = unwrap(
        await a.expenses.create(gid, a.draft(ann.id, [ann.id, ben.id, cy.id])),
      );
      world.tick();
      final taxi = unwrap(
        await a.expenses.create(
          gid,
          a.draft(ben.id, [ann.id, ben.id], title: 'Taxi', cents: 1001),
        ),
      );
      world.tick();
      unwrap(
        await a.expenses.update(
          taxi.expense.id,
          a.draft(ben.id, [ann.id, ben.id], title: 'Taxi home', cents: 1201),
        ),
      );
      world.tick();
      unwrap(await a.expenses.softDelete(dinner.expense.id));
      world.tick();
      unwrap(
        await a.settlements.create(
          gid,
          SettlementDraft(
            fromId: cy.id,
            toId: ann.id,
            amountCents: 500,
            currency: Currency.eur,
            date: DateTime.utc(2026, 3, 2),
            method: SettlementMethod.cash,
          ),
        ),
      );

      final shared = await a.share.makeShared(gid);
      expect(shared, isA<Ok<Object?, Object?>>(), reason: '$shared');
      expect(await a.pending(gid), 0);
      expect((await a.server.snapshot(gid)).lines, isNotEmpty);
      expectSame(
        await a.snapshot(gid),
        await a.server.snapshot(gid),
        'history uploaded as it is, deleted rows included',
      );

      final link = switch (await a.links.link(gid, isOwner: true)) {
        Ok(:final value) => value,
        Err(:final error) => fail('no link: $error'),
      };
      final joined = switch (await b.join.join(link.token)) {
        Ok(:final value) => value,
        Err(:final error) => fail('join failed: $error'),
      };
      expect(joined.groupName, 'Trip');
      expect(joined.people.map((p) => p.name), ['Ann', 'Ben', 'Cy']);
      unwrapRemote(await b.join.connect(gid, cy.id));
      await b.syncBoth(gid);
      await a.syncBoth(gid);
      final state = await expectConverged(a, b, gid);
      expect(state.text, contains('Taxi home'));
      expect(state.text, contains('expense|${dinner.expense.id}|Dinner|'));
    },
  );

  test('offline edits on both phones: the later edit wins (LWW)', () async {
    final a = world.phone('A', 3);
    final b = world.phone('B', 4);
    final t = await shareAndJoin(a, b);
    final gid = t.groupId;
    final [ann, ben, cy] = t.people;
    world.tick();
    final e = unwrap(
      await a.expenses.create(gid, a.draft(ann.id, [ann.id, ben.id, cy.id])),
    );
    final id = e.expense.id;
    await a.syncBoth(gid);
    await b.syncBoth(gid);

    // Both edit while offline; B edits last, A uploads last.
    world.tick();
    unwrap(
      await a.expenses.update(
        id,
        a.draft(ann.id, [ann.id, ben.id], title: 'From A', cents: 4000),
      ),
    );
    world.tick();
    unwrap(
      await b.expenses.update(
        id,
        b.draft(ben.id, [ann.id, ben.id, cy.id], title: 'From B', cents: 6000),
      ),
    );
    expect(await b.push(gid), const SyncIdle());
    expect(
      await a.push(gid),
      const SyncIdle(),
      reason: 'stale is not an error',
    );
    await a.pull(gid);
    await b.pull(gid);
    var state = await expectConverged(a, b, gid, what: 'B edited last');
    expect(state.text, contains('From B'));
    expect(state.text, isNot(contains('From A')));

    // And the other way round: A edits last, B uploads last.
    world.tick();
    unwrap(
      await b.expenses.update(
        id,
        b.draft(ben.id, [ann.id, ben.id], title: 'B again', cents: 100),
      ),
    );
    world.tick();
    unwrap(
      await a.expenses.update(
        id,
        a.draft(ann.id, [ann.id, cy.id], title: 'A again', cents: 200),
      ),
    );
    expect(await a.push(gid), const SyncIdle());
    expect(await b.push(gid), const SyncIdle());
    await a.pull(gid);
    await b.pull(gid);
    state = await expectConverged(a, b, gid, what: 'A edited last');
    expect(state.text, contains('A again'));
    expect(state.text, isNot(contains('B again')));
  });

  test('delete against edit: the later change wins either way', () async {
    final a = world.phone('A', 5);
    final b = world.phone('B', 6);
    final t = await shareAndJoin(a, b);
    final gid = t.groupId;
    final [ann, ben, cy] = t.people;
    world.tick();
    final id = unwrap(
      await a.expenses.create(gid, a.draft(ann.id, [ann.id, ben.id, cy.id])),
    ).expense.id;
    await a.syncBoth(gid);
    await b.syncBoth(gid);

    // A deletes, then B edits (later): the expense lives on, with B's edit.
    world.tick();
    unwrap(await a.expenses.softDelete(id));
    world.tick();
    unwrap(
      await b.expenses.update(
        id,
        b.draft(ben.id, [ann.id, ben.id], title: 'Kept', cents: 900),
      ),
    );
    expect(await a.push(gid), const SyncIdle());
    expect(await b.push(gid), const SyncIdle());
    await a.pull(gid);
    await b.pull(gid);
    var state = await expectConverged(a, b, gid, what: 'edit after delete');
    expect(state.text, contains('expense|$id|Kept|900|'));
    expect(state.text, contains('|false|'));

    // B edits, then A deletes (later): it stays deleted.
    world.tick();
    unwrap(
      await b.expenses.update(
        id,
        b.draft(ben.id, [ann.id, ben.id], title: 'Too late', cents: 800),
      ),
    );
    world.tick();
    unwrap(await a.expenses.softDelete(id));
    expect(await b.push(gid), const SyncIdle());
    expect(await a.push(gid), const SyncIdle());
    await a.pull(gid);
    await b.pull(gid);
    state = await expectConverged(a, b, gid, what: 'delete after edit');
    final line = state.lines.firstWhere((l) => l.startsWith('expense|$id|'));
    expect(line.split('|')[5], 'true');
  });

  test(
    'join by link, connect to a person, new link locks the old one out',
    () async {
      final a = world.phone('A', 7);
      final b = world.phone('B', 8);
      final c = world.phone('C', 9);
      final t = await shareAndJoin(a, b);
      final gid = t.groupId;
      final [ann, ben, cy] = t.people;

      // B is connected to Ben; a third phone sees that, and cannot take Ben.
      final joinedC = switch (await c.join.join(t.token)) {
        Ok(:final value) => value,
        Err(:final error) => fail('C could not join: $error'),
      };
      expect(
        {for (final p in joinedC.people) p.name: p.connected},
        {'Ann': false, 'Ben': true, 'Cy': false},
      );
      expect(
        await c.join.connect(gid, ben.id),
        const Err<void, RemoteError>(MemberAlreadyClaimed()),
      );
      unwrapRemote(await c.join.connect(gid, cy.id));

      // B still has the current link; the owner makes a new one.
      expect(
        switch (await b.links.link(gid, isOwner: false)) {
          Ok(:final value) => value.token,
          Err(:final error) => fail('B lost the link: $error'),
        },
        t.token,
      );
      final fresh = switch (await a.links.rotate(gid)) {
        Ok(:final value) => value.token,
        Err(:final error) => fail('no new link: $error'),
      };
      expect(fresh, isNot(t.token));
      expect(
        switch (await b.links.link(gid, isOwner: false)) {
          Err(:final error) => error,
          Ok() => fail('the old link should be gone'),
        },
        isA<LinkRotated>(),
      );
      final late = world.phone('D', 10);
      expect(
        switch (await late.join.join(t.token)) {
          Err(error: JoinRemoteFailure(:final error)) => error,
          Err(:final error) => fail('unexpected failure $error'),
          Ok() => fail('an old link must not let anyone in'),
        },
        const InviteInvalid(),
      );

      world.tick();
      unwrap(
        await c.expenses.create(gid, c.draft(cy.id, [ann.id, ben.id, cy.id])),
      );
      await c.syncBoth(gid);
      await a.syncBoth(gid);
      await b.syncBoth(gid);
      final state = await expectConverged(a, b, gid);
      expectSame(await c.snapshot(gid), state, 'phone C');
    },
  );

  test('a removed account is told so and keeps its data', () async {
    final a = world.phone('A', 11);
    final b = world.phone('B', 12);
    final t = await shareAndJoin(a, b);
    final gid = t.groupId;
    final [ann, ben, _] = t.people;
    world.tick();
    unwrap(await a.expenses.create(gid, a.draft(ann.id, [ann.id, ben.id])));
    await a.syncBoth(gid);
    await b.syncBoth(gid);

    final memberships = unwrapRemote(
      await a.container.read(inviteRemoteProvider).listMemberships(gid),
    );
    final bsMembership = memberships.firstWhere((m) => m.userId == b.userId);
    unwrapRemote(
      await a.container
          .read(inviteRemoteProvider)
          .removeMembership(bsMembership.id),
    );

    world.tick();
    unwrap(
      await b.expenses.create(
        gid,
        b.draft(ben.id, [ann.id, ben.id], title: 'After'),
      ),
    );
    final status = await b.push(gid);
    expect(status, isA<SyncError>());
    expect((status as SyncError).error, const NotMember());
    expect(
      (await b.db.syncStateDao.groupSync(gid))?.state,
      SyncState.removed.name,
    );
    expect(await b.pending(gid), 1, reason: 'the edit stays on this phone');
    expect((await b.snapshot(gid)).text, contains('After'));

    // The owner and the server are untouched by it.
    expectSame(await a.snapshot(gid), await a.server.snapshot(gid), 'owner');
    expect((await a.server.snapshot(gid)).text, isNot(contains('After')));
  });

  test('500 random operations on two phones converge', () async {
    final a = world.phone('A', 13);
    final b = world.phone('B', 14);
    final t = await shareAndJoin(a, b);
    final gid = t.groupId;
    final ids = t.people.map((p) => p.id).toList();
    final rnd = Random(20260301);
    final phones = [a, b];

    for (var i = 0; i < 500; i++) {
      world.tick(const Duration(seconds: 1));
      final p = phones[rnd.nextInt(2)];
      final live = [
        for (final e in await p.db.select(p.db.expenses).get())
          if (e.deletedAt == null) e.id,
      ];
      final dead = [
        for (final e in await p.db.select(p.db.expenses).get())
          if (e.deletedAt != null) e.id,
      ];
      final draft = p.draft(
        ids[rnd.nextInt(3)],
        ids.take(1 + rnd.nextInt(3)),
        title: 'Op $i',
        cents: 100 + rnd.nextInt(9000),
      );
      final roll = rnd.nextInt(100);
      if (live.isEmpty || roll < 35) {
        unwrap(await p.expenses.create(gid, draft));
      } else if (roll < 65) {
        unwrap(await p.expenses.update(live[rnd.nextInt(live.length)], draft));
      } else if (roll < 80) {
        unwrap(await p.expenses.softDelete(live[rnd.nextInt(live.length)]));
      } else if (dead.isNotEmpty && roll < 90) {
        unwrap(await p.expenses.restore(dead[rnd.nextInt(dead.length)]));
      } else {
        unwrap(
          await p.members.update(
            ids[rnd.nextInt(3)],
            name: 'Name $i',
          ),
        );
      }
      // Phones are mostly offline: sync only now and then.
      if (rnd.nextInt(100) < 15) await p.push(gid);
      if (rnd.nextInt(100) < 15) await p.pull(gid);
    }

    for (var round = 0; round < 4; round++) {
      await a.push(gid);
      await b.push(gid);
      await a.pull(gid);
      await b.pull(gid);
    }
    expect(await a.pending(gid), 0);
    expect(await b.pending(gid), 0);
    final state = await expectConverged(a, b, gid, what: '500 operations');
    expect(state.lines.length, greaterThan(10));
  });
}
