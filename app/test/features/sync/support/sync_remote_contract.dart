import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Two accounts on one server: [owner] creates groups, [stranger] is never
/// added to them.
class SyncRemoteFixture {
  const SyncRemoteFixture({required this.owner, required this.stranger});

  final SyncRemote owner;
  final SyncRemote stranger;
}

const _g = '00000000-0000-4000-8000-00000000000a';
const _m1 = '00000000-0000-4000-8000-000000000001';
const _m2 = '00000000-0000-4000-8000-000000000002';
const _e1 = '00000000-0000-4000-8000-0000000000e1';

String _hlc(int n) =>
    '2026-03-01T00:00:00.000Z-${n.toString().padLeft(4, '0')}-a';

Map<String, Object?> _group({String name = 'Trip', int v = 1}) => {
  DbGroupsCols.id: _g,
  DbGroupsCols.name: name,
  DbGroupsCols.currency: 'EUR',
  DbGroupsCols.createdAt: '2026-03-01T00:00:00.000Z',
  DbGroupsCols.updatedAt: _hlc(v),
  DbGroupsCols.deletedAt: null,
};

Map<String, Object?> _member(String id, {String name = 'Ann', int v = 1}) => {
  DbMembersCols.id: id,
  DbMembersCols.groupId: _g,
  DbMembersCols.name: name,
  DbMembersCols.position: id == _m1 ? 0 : 1,
  DbMembersCols.paypalMe: null,
  DbMembersCols.ibanHint: null,
  DbMembersCols.canDrive: true,
  DbMembersCols.createdAt: '2026-03-01T00:00:00.000Z',
  DbMembersCols.updatedAt: _hlc(v),
  DbMembersCols.deletedAt: null,
};

Map<String, Object?> _expense({
  int v = 1,
  int paid = 3000,
  int share = 3000,
  String title = 'Dinner',
}) => {
  DbExpensesCols.id: _e1,
  DbExpensesCols.groupId: _g,
  DbExpensesCols.title: title,
  DbExpensesCols.amountCents: 3000,
  DbExpensesCols.currency: 'EUR',
  DbExpensesCols.fxRatePpm: 1000000,
  DbExpensesCols.groupAmountCents: 3000,
  DbExpensesCols.date: '2026-03-01T00:00:00.000Z',
  DbExpensesCols.category: 'food',
  DbExpensesCols.type: 'expense',
  DbExpensesCols.splitMode: 'equal',
  DbExpensesCols.tripMeta: null,
  DbExpensesCols.updatedAt: _hlc(v),
  DbExpensesCols.deletedAt: null,
  'payers': [
    {DbExpensePayersCols.memberId: _m1, DbExpensePayersCols.paidCents: paid},
  ],
  'shares': [
    {
      DbExpenseSharesCols.memberId: _m1,
      DbExpenseSharesCols.shareCents: share ~/ 2,
      DbExpenseSharesCols.weight: 1,
    },
    {
      DbExpenseSharesCols.memberId: _m2,
      DbExpenseSharesCols.shareCents: share - share ~/ 2,
      DbExpenseSharesCols.weight: 1,
    },
  ],
};

T _ok<T>(Result<T, RemoteError> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final error) => fail('expected Ok, got $error'),
};

RemoteError _err<T>(Result<T, RemoteError> r) => switch (r) {
  Ok(:final value) => fail('expected Err, got $value'),
  Err(:final error) => error,
};

/// The rules the app relies on in a sync backend (ADR-27 §4). Run against
/// `FakeSyncRemote` in `make test` and against local Supabase in P6-T13, so
/// the fake cannot drift from the real server. [create] gives every test a
/// fresh, empty server.
void runSyncRemoteContract(
  String name,
  Future<SyncRemoteFixture> Function() create,
) {
  group('SyncRemote contract: $name', () {
    late SyncRemoteFixture f;
    setUp(() async => f = await create());

    Future<void> seed() async {
      expect(
        _ok(await f.owner.upsertRows(DbTables.groups, [_group()])),
        PushOutcome.applied,
      );
      expect(_ok(await f.owner.bootstrapMembership(_g)), isTrue);
      expect(
        _ok(
          await f.owner.upsertRows(DbTables.members, [
            _member(_m1),
            _member(_m2, name: 'Ben'),
          ]),
        ),
        PushOutcome.applied,
      );
    }

    group('bootstrap membership', () {
      Future<void> groupOnly() async => expect(
        _ok(await f.owner.upsertRows(DbTables.groups, [_group()])),
        PushOutcome.applied,
      );

      test('a new group has no member until the bootstrap', () async {
        await groupOnly();
        expect(
          _err(await f.owner.upsertRows(DbTables.members, [_member(_m1)])),
          const NotMember(),
        );
        expect(
          _err(await f.owner.upsertExpense(_expense())),
          const NotMember(),
        );
      });

      test(
        'the creator bootstraps once; again is done, not an error',
        () async {
          await groupOnly();
          expect(_ok(await f.owner.bootstrapMembership(_g)), isTrue);
          expect(_ok(await f.owner.bootstrapMembership(_g)), isFalse);
          expect(
            _ok(await f.owner.upsertRows(DbTables.members, [_member(_m1)])),
            PushOutcome.applied,
          );
        },
      );

      test('the group row can be sent again before the bootstrap', () async {
        await groupOnly();
        expect(
          _ok(await f.owner.upsertRows(DbTables.groups, [_group(v: 2)])),
          PushOutcome.applied,
        );
        expect(_ok(await f.owner.bootstrapMembership(_g)), isTrue);
      });

      test('nobody else can bootstrap the group', () async {
        await groupOnly();
        expect(
          _err(await f.stranger.bootstrapMembership(_g)),
          const NotMember(),
        );
        expect(_ok(await f.owner.bootstrapMembership(_g)), isTrue);
        expect(
          _err(await f.stranger.bootstrapMembership(_g)),
          const NotMember(),
        );
      });

      test('a group the server does not hold cannot be bootstrapped', () async {
        expect(_err(await f.owner.bootstrapMembership(_g)), const NotMember());
      });
    });

    test('a pushed row is pulled back with a server_seq', () async {
      await seed();
      final rows = _ok(
        await f.owner.pullChanges(
          groupId: _g,
          table: DbTables.members,
          afterSeq: 0,
          limit: 10,
        ),
      );
      expect(rows.map((r) => r[DbMembersCols.id]), containsAll([_m1, _m2]));
      expect(rows.first[DbMembersCols.serverSeq], isA<int>());
    });

    test('sending the same row twice leaves one row (idempotent)', () async {
      await seed();
      expect(
        _ok(await f.owner.upsertRows(DbTables.members, [_member(_m1)])),
        PushOutcome.applied,
      );
      final rows = _ok(
        await f.owner.pullChanges(
          groupId: _g,
          table: DbTables.members,
          afterSeq: 0,
          limit: 10,
        ),
      );
      expect(rows, hasLength(2));
    });

    test('a newer version replaces the row and bumps server_seq', () async {
      await seed();
      final before = _ok(
        await f.owner.pullChanges(
          groupId: _g,
          table: DbTables.members,
          afterSeq: 0,
          limit: 10,
        ),
      );
      final seq = before.first[DbMembersCols.serverSeq]! as int;
      _ok(
        await f.owner.upsertRows(DbTables.members, [
          _member(_m1, name: 'Anna', v: 2),
        ]),
      );
      final after = _ok(
        await f.owner.pullChanges(
          groupId: _g,
          table: DbTables.members,
          afterSeq: seq,
          limit: 10,
        ),
      );
      expect(after.map((r) => r[DbMembersCols.name]), contains('Anna'));
    });

    test('a backwards updated_at is stale and changes nothing', () async {
      await seed();
      _ok(
        await f.owner.upsertRows(DbTables.members, [
          _member(_m1, name: 'Anna', v: 5),
        ]),
      );
      expect(
        _ok(
          await f.owner.upsertRows(DbTables.members, [
            _member(_m1, name: 'Old', v: 2),
          ]),
        ),
        PushOutcome.stale,
      );
      final rows = _ok(
        await f.owner.pullChanges(
          groupId: _g,
          table: DbTables.members,
          afterSeq: 0,
          limit: 10,
        ),
      );
      expect(
        rows.firstWhere((r) => r[DbMembersCols.id] == _m1)[DbMembersCols.name],
        'Anna',
      );
    });

    test('pullChanges pages by server_seq', () async {
      await seed();
      final first = _ok(
        await f.owner.pullChanges(
          groupId: _g,
          table: DbTables.members,
          afterSeq: 0,
          limit: 1,
        ),
      );
      expect(first, hasLength(1));
      final rest = _ok(
        await f.owner.pullChanges(
          groupId: _g,
          table: DbTables.members,
          afterSeq: first.single[DbMembersCols.serverSeq]! as int,
          limit: 10,
        ),
      );
      expect(rest, hasLength(1));
      expect(
        rest.single[DbMembersCols.id],
        isNot(first.single[DbMembersCols.id]),
      );
    });

    test('a stranger cannot write into the group: NotMember', () async {
      await seed();
      expect(
        _err(await f.stranger.upsertRows(DbTables.members, [_member(_m1)])),
        const NotMember(),
      );
      expect(
        _err(await f.stranger.upsertExpense(_expense())),
        const NotMember(),
      );
    });

    test('a stranger cannot pull the group: NotMember', () async {
      await seed();
      expect(
        _err(
          await f.stranger.pullChanges(
            groupId: _g,
            table: DbTables.members,
            afterSeq: 0,
            limit: 10,
          ),
        ),
        const NotMember(),
      );
    });

    group('upsert_expense', () {
      test('stores the expense with payers and shares', () async {
        await seed();
        expect(
          _ok(await f.owner.upsertExpense(_expense())),
          PushOutcome.applied,
        );
        final children = _ok(await f.owner.fetchExpenseChildren([_e1]));
        expect(children[_e1]!.payers, hasLength(1));
        expect(children[_e1]!.shares, hasLength(2));
        final expenses = _ok(
          await f.owner.pullChanges(
            groupId: _g,
            table: DbTables.expenses,
            afterSeq: 0,
            limit: 10,
          ),
        );
        expect(expenses.single[DbExpensesCols.title], 'Dinner');
      });

      test('an older or equal HLC is stale and keeps the stored one', () async {
        await seed();
        _ok(await f.owner.upsertExpense(_expense(v: 5, title: 'New')));
        expect(
          _ok(await f.owner.upsertExpense(_expense(v: 2, title: 'Old'))),
          PushOutcome.stale,
        );
        expect(
          _ok(await f.owner.upsertExpense(_expense(v: 5, title: 'Replay'))),
          PushOutcome.stale,
        );
        final expenses = _ok(
          await f.owner.pullChanges(
            groupId: _g,
            table: DbTables.expenses,
            afterSeq: 0,
            limit: 10,
          ),
        );
        expect(expenses.single[DbExpensesCols.title], 'New');
      });

      test('payers that do not add up are rejected with a code', () async {
        await seed();
        expect(
          _err(await f.owner.upsertExpense(_expense(paid: 2000))),
          const Rejected('payers_sum_mismatch'),
        );
      });

      test('a payer from outside the group is rejected', () async {
        await seed();
        final bad = _expense();
        (bad['payers']! as List<Object?>)[0] = {
          DbExpensePayersCols.memberId: '00000000-0000-4000-8000-0000000000ff',
          DbExpensePayersCols.paidCents: 3000,
        };
        expect(
          _err(await f.owner.upsertExpense(bad)),
          const Rejected('member_not_in_group'),
        );
      });
    });
  });
}
