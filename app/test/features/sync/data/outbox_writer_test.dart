import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/drift_payment_details_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/outbox_writer.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../db/test_support.dart' show newMember;
import '../../members/data/payment_details_repository_contract.dart';
import '../../repo_test_support.dart';

/// Everything a group can hold, written through the Drift repositories.
class _World {
  _World(this.r, this.groupId, this.m, this.car);

  final Repos r;
  final String groupId;
  final List<GroupMember> m;
  final Vehicle car;

  AppDatabase get db => r.db!;

  Future<List<LocalOutboxRow>> outbox() => db.syncStateDao.outboxOf(groupId);

  Future<LocalOutboxRow?> opOf(OutboxEntity e, String id) async {
    final rows = (await outbox()).where(
      (o) => o.entity == e.table && o.entityId == id,
    );
    return rows.isEmpty ? null : rows.single;
  }

  Map<String, Object?> payload(LocalOutboxRow row) =>
      jsonDecode(row.payload) as Map<String, Object?>;

  Ride ride(String id, {int distance = 12000}) => Ride(
    id: id,
    date: DateTime.utc(2026, 3, 2),
    distanceMeters: distance,
    roundTrip: true,
    tollsCents: 150,
    vehicleId: car.id,
    driverId: m[0].id,
    passengerIds: {m[2].id, m[1].id},
    driverCounts: false,
    pricePerUnitMilli: 1700,
    useKmRate: true,
  );

  ExpenseDraft draft({String title = 'Dinner', int cents = 3000}) =>
      ExpenseDraft(
        title: title,
        amountCents: cents,
        currency: eur,
        date: DateTime.utc(2026, 3),
        payers: {m[0].id: cents},
        split: EqualSplit({m[0].id, m[1].id, m[2].id}),
        category: 'food',
      );
}

Future<_World> _world({required SyncState? state}) async {
  final r = await driftRepos();
  final seeded = await seedGroup(r);
  final car = ok(
    await r.vehicles.add(
      seeded.groupId,
      name: 'Golf',
      fuelType: FuelType.diesel,
      consumptionMilliPer100km: 5500,
      wearMilliPerKm: 80,
      kmRateMilliPerKm: 300,
    ),
  );
  if (state != null) await r.db!.syncStateDao.setState(seeded.groupId, state);
  return _World(r, seeded.groupId, seeded.members, car);
}

void _expectServerShape(String entity, Map<String, Object?> payload) {
  final cols = dbContract[entity]!;
  for (final key in payload.keys) {
    if (entity == DbTables.expenses && (key == 'payers' || key == 'shares')) {
      continue;
    }
    expect(cols.containsKey(key), isTrue, reason: '$entity has no column $key');
  }
  expect(payload.containsKey(DbExpensesCols.serverSeq), isFalse);
  for (final MapEntry(:key, :value) in cols.entries) {
    if (value.nullable || key == 'server_seq') continue;
    // Required non-null columns the server does not assign itself.
    const serverAssigned = {'created_by', 'user_id'};
    if (serverAssigned.contains(key)) continue;
    if (entity == DbTables.expenses && key == 'created_at') continue;
    expect(payload.containsKey(key), isTrue, reason: '$entity misses $key');
  }
}

void main() {
  group('local group', () {
    test('queues nothing for any write', () async {
      final w = await _world(state: null);
      ok(await w.r.groups.update(w.groupId, name: 'New', currency: eur));
      final e = ok(await w.r.expenses.create(w.groupId, w.draft()));
      ok(await w.r.expenses.softDelete(e.expense.id));
      ok(await w.r.rides.log(w.groupId, w.ride('r1')));
      expect(await w.outbox(), isEmpty);
    });

    test('a removed group queues nothing', () async {
      final w = await _world(state: SyncState.removed);
      ok(await w.r.members.add(w.groupId, name: 'Dan'));
      expect(await w.outbox(), isEmpty);
    });
  });

  group('shared group', () {
    for (final state in [SyncState.shared, SyncState.uploading]) {
      test('${state.name} queues a member add', () async {
        final w = await _world(state: state);
        final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
        final op = (await w.opOf(OutboxEntity.member, dan.id))!;
        expect(op.op, outboxOpUpsert);
        expect(op.groupId, w.groupId);
        expect(w.payload(op)[DbMembersCols.name], 'Dan');
      });
    }

    test('group create, update, delete and restore', () async {
      final r = await driftRepos();
      final g = ok(
        await r.groups.create(name: 'A', currency: eur, createdBy: 'dev'),
      );
      expect(await r.db!.syncStateDao.outboxOf(g.id), isEmpty);
      await r.db!.syncStateDao.setState(g.id, SyncState.shared);
      ok(await r.groups.update(g.id, name: 'B', currency: eur));
      var op = (await r.db!.syncStateDao.outboxOf(g.id)).single;
      expect(op.entity, DbTables.groups);
      var p = jsonDecode(op.payload) as Map<String, Object?>;
      expect(p[DbGroupsCols.name], 'B');
      expect(p[DbGroupsCols.deletedAt], isNull);
      _expectServerShape(DbTables.groups, p);

      final undo = ok(await r.groups.softDelete(g.id));
      op = (await r.db!.syncStateDao.outboxOf(g.id)).single;
      p = jsonDecode(op.payload) as Map<String, Object?>;
      expect(p[DbGroupsCols.deletedAt], isNotNull);

      ok(await undo());
      op = (await r.db!.syncStateDao.outboxOf(g.id)).single;
      p = jsonDecode(op.payload) as Map<String, Object?>;
      expect(p[DbGroupsCols.deletedAt], isNull);
    });

    test('members: update, canDrive, reorder, delete, restore', () async {
      final w = await _world(state: SyncState.shared);
      final a = w.m[0].id;
      ok(await w.r.members.update(a, name: 'Anna', paypalMe: 'anna'));
      expect(
        w.payload((await w.opOf(OutboxEntity.member, a))!)['name'],
        'Anna',
      );
      ok(await w.r.members.setCanDrive(a, canDrive: false));
      expect(
        w.payload(
          (await w.opOf(OutboxEntity.member, a))!,
        )[DbMembersCols.canDrive],
        false,
      );
      ok(
        await w.r.members.reorder(w.groupId, [w.m[2].id, w.m[0].id, w.m[1].id]),
      );
      for (final x in w.m) {
        expect(await w.opOf(OutboxEntity.member, x.id), isNotNull);
      }
      final undo = ok(await w.r.members.softDelete(a));
      expect(
        w.payload(
          (await w.opOf(OutboxEntity.member, a))!,
        )[DbMembersCols.deletedAt],
        isNotNull,
      );
      ok(await undo());
      expect(
        w.payload(
          (await w.opOf(OutboxEntity.member, a))!,
        )[DbMembersCols.deletedAt],
        isNull,
      );
      _expectServerShape(
        DbTables.members,
        w.payload((await w.opOf(OutboxEntity.member, a))!),
      );
    });

    test('expense payload is the upsert_expense shape', () async {
      final w = await _world(state: SyncState.shared);
      final e = ok(await w.r.expenses.create(w.groupId, w.draft()));
      final op = (await w.opOf(OutboxEntity.expense, e.expense.id))!;
      final p = w.payload(op);
      _expectServerShape(DbTables.expenses, p);
      expect(p[DbExpensesCols.amountCents], 3000);
      expect(p[DbExpensesCols.groupAmountCents], 3000);
      expect(p[DbExpensesCols.date], '2026-03-01T00:00:00.000Z');
      expect(p[DbExpensesCols.splitMode], 'equal');
      expect(p[DbExpensesCols.category], 'food');
      expect(p[DbExpensesCols.tripMeta], isNull);
      expect(p[DbExpensesCols.deletedAt], isNull);
      expect(p[DbExpensesCols.updatedAt], isA<String>());
      final payers = (p['payers']! as List).cast<Map<String, Object?>>();
      expect(payers, [
        {
          DbExpensePayersCols.memberId: w.m[0].id,
          DbExpensePayersCols.paidCents: 3000,
        },
      ]);
      final shares = (p['shares']! as List).cast<Map<String, Object?>>();
      expect(shares, hasLength(3));
      expect(
        shares.fold<int>(0, (s, x) => s + (x['share_cents']! as int)),
        3000,
      );
      for (final x in [...payers, ...shares]) {
        for (final k in x.keys) {
          expect(
            dbContract[DbTables.expensePayers]!.containsKey(k) ||
                dbContract[DbTables.expenseShares]!.containsKey(k),
            isTrue,
          );
        }
      }
    });

    test(
      'expense edit coalesces into one op with the latest payload',
      () async {
        final w = await _world(state: SyncState.shared);
        final e = ok(await w.r.expenses.create(w.groupId, w.draft()));
        final id = e.expense.id;
        final first = (await w.opOf(OutboxEntity.expense, id))!;
        w.r.clock.advance(const Duration(minutes: 1));
        ok(await w.r.expenses.update(id, w.draft(title: 'Lunch', cents: 4500)));
        final ops = (await w.outbox()).where((o) => o.entityId == id);
        expect(ops, hasLength(1));
        final op = ops.single;
        expect(op.opId, isNot(first.opId));
        final p = w.payload(op);
        expect(p[DbExpensesCols.title], 'Lunch');
        expect(p[DbExpensesCols.amountCents], 4500);
        expect(
          (p['payers']! as List).single,
          {
            DbExpensePayersCols.memberId: w.m[0].id,
            DbExpensePayersCols.paidCents: 4500,
          },
        );
        expect(
          (p[DbExpensesCols.updatedAt]! as String).compareTo(
            w.payload(first)[DbExpensesCols.updatedAt]! as String,
          ),
          greaterThan(0),
        );
      },
    );

    test('a re-queued op moves behind ops it may depend on', () async {
      final w = await _world(state: SyncState.shared);
      final e = ok(await w.r.expenses.create(w.groupId, w.draft()));
      final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
      ok(await w.r.expenses.update(e.expense.id, w.draft(title: 'X')));
      final order = [for (final o in await w.outbox()) o.entityId];
      expect(order.indexOf(dan.id), lessThan(order.indexOf(e.expense.id)));
    });

    test('expense delete and restore enqueue', () async {
      final w = await _world(state: SyncState.shared);
      final e = ok(await w.r.expenses.create(w.groupId, w.draft()));
      final id = e.expense.id;
      final undo = ok(await w.r.expenses.softDelete(id));
      var p = w.payload((await w.opOf(OutboxEntity.expense, id))!);
      expect(p[DbExpensesCols.deletedAt], '2026-03-01T12:00:00.000Z');
      expect(p['payers'], isNotEmpty);
      ok(await undo());
      p = w.payload((await w.opOf(OutboxEntity.expense, id))!);
      expect(p[DbExpensesCols.deletedAt], isNull);
    });

    test('settlement create, update, delete, restore', () async {
      final w = await _world(state: SyncState.shared);
      final s = ok(
        await w.r.settlements.create(
          w.groupId,
          SettlementDraft(
            fromId: w.m[1].id,
            toId: w.m[0].id,
            amountCents: 500,
            currency: eur,
            date: DateTime.utc(2026, 3, 5),
            method: SettlementMethod.cash,
          ),
        ),
      );
      final id = s.settlement.id;
      var p = w.payload((await w.opOf(OutboxEntity.settlement, id))!);
      _expectServerShape(DbTables.settlements, p);
      expect(p[DbSettlementsCols.amountCents], 500);
      ok(
        await w.r.settlements.update(
          id,
          amountCents: 700,
          method: SettlementMethod.paypal,
          date: DateTime.utc(2026, 3, 6),
        ),
      );
      expect(
        (await w.outbox()).where((o) => o.entityId == id),
        hasLength(1),
      );
      p = w.payload((await w.opOf(OutboxEntity.settlement, id))!);
      expect(p[DbSettlementsCols.amountCents], 700);
      expect(p[DbSettlementsCols.method], 'paypal');
      final undo = ok(await w.r.settlements.softDelete(id));
      p = w.payload((await w.opOf(OutboxEntity.settlement, id))!);
      expect(p[DbSettlementsCols.deletedAt], isNotNull);
      ok(await undo());
      p = w.payload((await w.opOf(OutboxEntity.settlement, id))!);
      expect(p[DbSettlementsCols.deletedAt], isNull);
    });

    test('vehicle add, update, delete, restore', () async {
      final w = await _world(state: SyncState.shared);
      final v = ok(
        await w.r.vehicles.add(
          w.groupId,
          name: 'Zoe',
          fuelType: FuelType.electric,
          consumptionMilliPer100km: 16000,
        ),
      );
      var p = w.payload((await w.opOf(OutboxEntity.vehicle, v.id))!);
      _expectServerShape(DbTables.vehicles, p);
      expect(p[DbVehiclesCols.kmRateMilliPerKm], isNull);
      ok(
        await w.r.vehicles.update(
          Vehicle(
            id: v.id,
            name: 'Zoe 2',
            fuelType: FuelType.electric,
            consumptionMilliPer100km: 17000,
            wearMilliPerKm: 10,
            kmRateMilliPerKm: 250,
          ),
        ),
      );
      p = w.payload((await w.opOf(OutboxEntity.vehicle, v.id))!);
      expect(p[DbVehiclesCols.name], 'Zoe 2');
      expect(p[DbVehiclesCols.kmRateMilliPerKm], 250);
      final undo = ok(await w.r.vehicles.softDelete(v.id));
      p = w.payload((await w.opOf(OutboxEntity.vehicle, v.id))!);
      expect(p[DbVehiclesCols.deletedAt], isNotNull);
      ok(await undo());
      p = w.payload((await w.opOf(OutboxEntity.vehicle, v.id))!);
      expect(p[DbVehiclesCols.deletedAt], isNull);
    });

    test('ride template add, update, delete, restore', () async {
      final w = await _world(state: SyncState.shared);
      RideTemplate t(String name) => RideTemplate(
        id: 'ignored',
        name: name,
        distanceMeters: 5000,
        vehicleId: w.car.id,
        roundTrip: true,
        defaultDriverId: w.m[0].id,
        defaultPassengerIds: {w.m[2].id, w.m[1].id},
        tollsCents: 100,
      );
      final added = ok(await w.r.rideTemplates.add(w.groupId, t('Work')));
      var p = w.payload((await w.opOf(OutboxEntity.rideTemplate, added.id))!);
      _expectServerShape(DbTables.rideTemplates, p);
      expect(
        p[DbRideTemplatesCols.defaultPassengerIds],
        [w.m[1].id, w.m[2].id]..sort(),
      );
      ok(
        await w.r.rideTemplates.update(
          RideTemplate(
            id: added.id,
            name: 'Gym',
            distanceMeters: 5000,
            vehicleId: w.car.id,
          ),
        ),
      );
      p = w.payload((await w.opOf(OutboxEntity.rideTemplate, added.id))!);
      expect(p[DbRideTemplatesCols.name], 'Gym');
      final undo = ok(await w.r.rideTemplates.softDelete(added.id));
      p = w.payload((await w.opOf(OutboxEntity.rideTemplate, added.id))!);
      expect(p[DbRideTemplatesCols.deletedAt], isNotNull);
      ok(await undo());
      p = w.payload((await w.opOf(OutboxEntity.rideTemplate, added.id))!);
      expect(p[DbRideTemplatesCols.deletedAt], isNull);
    });

    test('ride log, update, delete, restore', () async {
      final w = await _world(state: SyncState.shared);
      ok(await w.r.rides.log(w.groupId, w.ride('r1')));
      var p = w.payload((await w.opOf(OutboxEntity.ride, 'r1'))!);
      _expectServerShape(DbTables.rides, p);
      expect(p[DbRidesCols.passengerIds], [w.m[1].id, w.m[2].id]..sort());
      expect(p[DbRidesCols.settledExpenseId], isNull);
      ok(await w.r.rides.update(w.ride('r1', distance: 999)));
      expect((await w.outbox()).where((o) => o.entityId == 'r1'), hasLength(1));
      p = w.payload((await w.opOf(OutboxEntity.ride, 'r1'))!);
      expect(p[DbRidesCols.distanceMeters], 999);
      final undo = ok(await w.r.rides.softDelete('r1'));
      p = w.payload((await w.opOf(OutboxEntity.ride, 'r1'))!);
      expect(p[DbRidesCols.deletedAt], isNotNull);
      ok(await undo());
      p = w.payload((await w.opOf(OutboxEntity.ride, 'r1'))!);
      expect(p[DbRidesCols.deletedAt], isNull);
    });

    test(
      'settle and unsettle a period queue the expense and its rides',
      () async {
        final w = await _world(state: SyncState.shared);
        ok(await w.r.rides.log(w.groupId, w.ride('r1')));
        ok(await w.r.rides.log(w.groupId, w.ride('r2')));
        final expenses = ok(
          await w.r.rides.settlePeriod(w.groupId, [
            PeriodSettlement(
              rideIds: const ['r1', 'r2'],
              draft: ExpenseDraft(
                title: 'Rides',
                amountCents: 600,
                currency: eur,
                date: DateTime.utc(2026, 3, 31),
                payers: {w.m[0].id: 600},
                split: ExactSplit({
                  w.m[0].id: 200,
                  w.m[1].id: 200,
                  w.m[2].id: 200,
                }),
              ),
            ),
          ]),
        );
        final expenseId = expenses.single.expense.id;
        expect(await w.opOf(OutboxEntity.expense, expenseId), isNotNull);
        for (final id in ['r1', 'r2']) {
          expect(
            w.payload(
              (await w.opOf(OutboxEntity.ride, id))!,
            )[DbRidesCols.settledExpenseId],
            expenseId,
          );
        }
        // The expense is queued before the rides that point at it.
        final order = [for (final o in await w.outbox()) o.entityId];
        expect(order.indexOf(expenseId), lessThan(order.indexOf('r1')));

        ok(await w.r.rides.unsettle([expenseId]));
        for (final id in ['r1', 'r2']) {
          expect(
            w.payload(
              (await w.opOf(OutboxEntity.ride, id))!,
            )[DbRidesCols.settledExpenseId],
            isNull,
          );
        }
        expect(
          w.payload(
            (await w.opOf(OutboxEntity.expense, expenseId))!,
          )[DbExpensesCols.deletedAt],
          isNotNull,
        );
      },
    );

    test('a failed settle rolls the queue back with the data', () async {
      final w = await _world(state: SyncState.shared);
      ok(await w.r.rides.log(w.groupId, w.ride('r1')));
      final before = (await w.outbox()).map((o) => o.opId).toList();
      final result = await w.r.rides.settlePeriod(w.groupId, [
        PeriodSettlement(
          rideIds: const ['r1', 'missing'],
          draft: ExpenseDraft(
            title: 'Rides',
            amountCents: 600,
            currency: eur,
            date: DateTime.utc(2026, 3, 31),
            payers: {w.m[0].id: 600},
            split: ExactSplit({w.m[0].id: 600}),
          ),
        ),
      ]);
      expect(err(result), isA<NotFound>());
      expect((await w.outbox()).map((o) => o.opId).toList(), before);
    });
  });

  group('atomicity', () {
    test('a failure after the write rolls back row and op', () async {
      final w = await _world(state: SyncState.shared);
      final writer = OutboxWriter(
        db: w.db,
        clock: w.r.clock,
        ids: SequentialIdGenerator(),
      );
      await expectLater(
        w.db.transaction(() async {
          await w.db.membersDao.insertMember(newMember('m-x', w.groupId));
          await writer.enqueue(OutboxEntity.member, 'm-x');
          expect(await w.opOf(OutboxEntity.member, 'm-x'), isNotNull);
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect(await w.db.membersDao.findById('m-x'), isNull);
      expect(await w.opOf(OutboxEntity.member, 'm-x'), isNull);
    });

    test('a failing enqueue surfaces as a storage error and keeps the old '
        'data', () async {
      final w = await _world(state: SyncState.shared);
      await w.db.customStatement('DROP TABLE local_outbox');
      final result = await w.r.groups.update(
        w.groupId,
        name: 'Changed',
        currency: eur,
      );
      expect(err(result), isA<Storage>());
      expect(ok(await w.r.groups.get(w.groupId)).name, 'Trip');
    });

    test(
      'enqueue for a row that was never written is a programming error',
      () async {
        final w = await _world(state: SyncState.shared);
        final writer = OutboxWriter(
          db: w.db,
          clock: w.r.clock,
          ids: SequentialIdGenerator(),
        );
        await expectLater(
          writer.enqueue(OutboxEntity.expense, 'nope'),
          throwsStateError,
        );
      },
    );
  });

  group('local-only data stays out', () {
    test('no IBAN, BIC or account name in any payload', () async {
      final w = await _world(state: SyncState.shared);
      final payments = DriftPaymentDetailsRepository(
        db: w.db,
        clock: w.r.clock,
        ids: SequentialIdGenerator(),
        cipher: const PlaintextIbanCipher(),
      );
      ok(
        await payments.save(
          w.m[0].id,
          paypalMe: 'ann',
          iban: testIban,
          bic: 'COBADEFFXXX',
          accountName: 'Ann Example',
        ),
      );
      ok(await w.r.expenses.create(w.groupId, w.draft()));
      ok(await w.r.rides.log(w.groupId, w.ride('r1')));
      final ops = await w.outbox();
      expect(ops, isNotEmpty);
      for (final op in ops) {
        expect(op.payload, isNot(contains(testIban)));
        expect(op.payload, isNot(contains('COBADEFFXXX')));
        expect(op.payload, isNot(contains('Ann Example')));
        _assertNoKey(jsonDecode(op.payload), (k) {
          final key = k.toLowerCase();
          return key == 'iban' ||
              key == 'bic' ||
              key == 'account_name' ||
              key.startsWith('local_');
        });
      }
      // The member op carries the masked hint, never the number.
      final member = w.payload((await w.opOf(OutboxEntity.member, w.m[0].id))!);
      expect(member[DbMembersCols.paypalMe], 'ann');
      expect(member[DbMembersCols.ibanHint], isNot(contains(testIban)));
      expect(member[DbMembersCols.ibanHint], isNotNull);
    });

    test('server-assigned columns are never sent', () async {
      final w = await _world(state: SyncState.shared);
      final dan = ok(await w.r.members.add(w.groupId, name: 'Dan'));
      final p = w.payload((await w.opOf(OutboxEntity.member, dan.id))!);
      expect(p.containsKey(DbMembersCols.userId), isFalse);
      expect(p.containsKey(DbMembersCols.serverSeq), isFalse);
    });
  });
}

void _assertNoKey(Object? node, bool Function(String) forbidden) {
  if (node is Map<String, Object?>) {
    for (final MapEntry(:key, :value) in node.entries) {
      expect(forbidden(key), isFalse, reason: 'forbidden key $key');
      _assertNoKey(value, forbidden);
    }
  } else if (node is List<Object?>) {
    for (final e in node) {
      _assertNoKey(e, forbidden);
    }
  }
}
