import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_snapshots.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Group trip;
  late List<GroupMember> people;

  GroupDetailViewModel vm([String? id]) =>
      container.read(groupDetailViewModelProvider(id ?? trip.id).notifier);
  GroupDetailState state([String? id]) =>
      container.read(groupDetailViewModelProvider(id ?? trip.id));
  GroupDetailLoaded loaded() => state() as GroupDetailLoaded;
  List<String> names() => [for (final m in loaded().members) m.member.name];

  Future<void> open([String? id]) async {
    container.listen(groupDetailViewModelProvider(id ?? trip.id), (_, _) {});
    await pumpEventQueue();
  }

  Future<ExpenseEntry> addExpense({List<int> payers = const [0]}) async => ok(
    await app.expenses.create(
      trip.id,
      ExpenseDraft(
        title: 'Taxi',
        amountCents: 900,
        currency: Currency.eur,
        date: DateTime.utc(2026, 2),
        payers: {for (final i in payers) people[i].id: 900 ~/ payers.length},
        split: EqualSplit({for (final p in people) p.id}),
      ),
    ),
  );

  setUp(() async {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
    trip = ok(
      await app.groups.create(
        name: 'Trip',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Ann', 'Ben', 'Cy'])
        ok(await app.members.add(trip.id, name: n)),
    ];
  });

  group('state', () {
    test('loading, then the group with its members in order', () async {
      container.listen(groupDetailViewModelProvider(trip.id), (_, _) {});
      expect(state(), isA<GroupDetailLoading>());
      await pumpEventQueue();
      expect(loaded().group, trip);
      expect(names(), ['Ann', 'Ben', 'Cy']);
      expect(loaded().hasEntries, isFalse);
      expect(loaded().canChangeCurrency, isTrue);
      expect(loaded().notice, isNull);
    });

    test('a group without members is empty', () async {
      final empty = ok(
        await app.groups.create(
          name: 'Flat',
          currency: Currency.eur,
          createdBy: 'dev',
        ),
      );
      await open(empty.id);
      expect(vm(empty.id).debugSnapshot()['status'], 'empty');
    });

    test('an unknown or archived group is NotFound', () async {
      await open('nope');
      expect(
        (state('nope') as GroupDetailFailure).error,
        const NotFound('group', 'nope'),
      );
      await open();
      ok(await app.groups.softDelete(trip.id));
      await pumpEventQueue();
      expect(state(), isA<GroupDetailFailure>());
    });

    test('a failing stream shows the error; retry recovers', () async {
      app.members.watchError = StateError('boom');
      await open();
      expect(state(), isA<GroupDetailFailure>());
      expect(vm().debugSnapshot()['status'], 'error');

      app.members.watchError = null;
      vm().retry();
      expect(state(), isA<GroupDetailLoading>());
      await pumpEventQueue();
      expect(state(), isA<GroupDetailLoaded>());
    });

    test('a repository error on the stream is kept as is', () async {
      app.members.watchError = const Conflict('x');
      await open();
      expect((state() as GroupDetailFailure).error, const Conflict('x'));
    });

    test('snapshot lists members with position and usage', () async {
      await open();
      expect(vm().debugSnapshot(), {
        'status': 'data',
        'groupId': trip.id,
        'name': 'Trip',
        'currency': 'EUR',
        'hasEntries': false,
        'members': [
          for (final m in people)
            {
              'id': m.id,
              'name': m.name,
              'position': m.position,
              'inUse': false,
            },
        ],
        'notice': null,
      });
    });

    test('registers and unregisters its snapshot', () async {
      final registry = container.read(debugSnapshotRegistryProvider);
      await open();
      expect(registry.screens, ['group']);
      container.dispose();
      expect(registry.screens, isEmpty);
    });
  });

  group('addMember', () {
    test('appends at the end', () async {
      await open();
      final m = ok(await vm().addMember(' Dee '));
      expect(m.name, 'Dee');
      await pumpEventQueue();
      expect(names().last, 'Dee');
    });

    test('rejects a blank name', () async {
      await open();
      expect(err(await vm().addMember(' ')), isA<InvalidData>());
      expect(names(), hasLength(3));
    });

    test('reports a repository failure', () async {
      await open();
      app.members.failWith = const Storage('x');
      expect(err(await vm().addMember('Dee')), isA<Storage>());
    });
  });

  group('renameMember', () {
    test('renames and keeps payment hints', () async {
      final m = ok(
        await app.members.add(
          trip.id,
          name: 'Dee',
          paypalMe: 'dee',
          ibanHint: 'DE..99',
        ),
      );
      await open();
      ok(await vm().renameMember(m.id, ' Dee D. '));
      final stored = ok(await app.members.list(trip.id)).last;
      expect(stored.name, 'Dee D.');
      expect(stored.paypalMe, 'dee');
      expect(stored.ibanHint, 'DE..99');
    });

    test('validates, reports unknown ids and failures', () async {
      await open();
      expect(
        err(await vm().renameMember(people[0].id, '')),
        isA<InvalidData>(),
      );
      expect(err(await vm().renameMember('nope', 'X')), isA<NotFound>());
      app.members.failWith = const Storage('x');
      expect(err(await vm().renameMember(people[0].id, 'X')), isA<Storage>());
    });
  });

  group('reorder', () {
    test('moves a member down and up', () async {
      await open();
      ok(await vm().reorder(0, 2));
      await pumpEventQueue();
      expect(names(), ['Ben', 'Cy', 'Ann']);
      ok(await vm().reorder(2, 0));
      await pumpEventQueue();
      expect(names(), ['Ann', 'Ben', 'Cy']);
    });

    test('shows the new order before the repository answers', () async {
      await open();
      final pending = vm().reorder(0, 1);
      expect(names(), ['Ben', 'Ann', 'Cy']);
      ok(await pending);
    });

    test('persists the order (positions follow the list)', () async {
      await open();
      ok(await vm().reorder(2, 0));
      final stored = ok(await app.members.list(trip.id));
      expect([for (final m in stored) m.name], ['Cy', 'Ann', 'Ben']);
    });

    test('rolls back when the repository fails', () async {
      await open();
      app.members.failWith = const Storage('x');
      expect(err(await vm().reorder(0, 2)), isA<Storage>());
      expect(names(), ['Ann', 'Ben', 'Cy']);
    });

    test('same index is a no-op; bad indexes are rejected', () async {
      await open();
      ok(await vm().reorder(1, 1));
      expect(err(await vm().reorder(-1, 0)), isA<InvalidData>());
      expect(err(await vm().reorder(3, 0)), isA<InvalidData>());
      expect(err(await vm().reorder(0, 3)), isA<InvalidData>());
      expect(names(), ['Ann', 'Ben', 'Cy']);
    });

    test('before loading there is nothing to move', () async {
      expect(err(await vm().reorder(0, 1)), isA<InvalidData>());
    });
  });

  group('removeMember', () {
    test('soft deletes; undo restores at the same place', () async {
      await open();
      final undo = ok(await vm().removeMember(people[1].id));
      await pumpEventQueue();
      expect(names(), ['Ann', 'Cy']);
      ok(await undo());
      await pumpEventQueue();
      expect(names(), ['Ann', 'Ben', 'Cy']);
    });

    test('is refused for a payer or sharer of an expense', () async {
      await addExpense();
      await open();
      expect(loaded().hasEntries, isTrue);
      expect(loaded().members.every((m) => m.inUse), isTrue);

      expect(err(await vm().removeMember(people[0].id)), isA<Conflict>());
      expect(names(), hasLength(3));
      final notice = loaded().notice!;
      expect(notice.name, 'Ann');
      expect(notice.memberId, people[0].id);
      expect(vm().debugSnapshot()['notice'], {'memberInUse': 'Ann'});
    });

    test('is refused for a member of a settlement', () async {
      ok(
        await app.settlements.create(
          trip.id,
          SettlementDraft(
            fromId: people[1].id,
            toId: people[0].id,
            amountCents: 500,
            currency: Currency.eur,
            date: DateTime.utc(2026, 2, 2),
            method: SettlementMethod.cash,
          ),
        ),
      );
      await open();
      final inUse = {
        for (final m in loaded().members) m.member.name: m.inUse,
      };
      expect(inUse, {'Ann': true, 'Ben': true, 'Cy': false});
      expect(err(await vm().removeMember(people[1].id)), isA<Conflict>());
      ok(await vm().removeMember(people[2].id));
    });

    test('is allowed again once the expense is deleted', () async {
      final e = await addExpense();
      await open();
      ok(await app.expenses.softDelete(e.expense.id));
      await pumpEventQueue();
      expect(loaded().hasEntries, isFalse);
      ok(await vm().removeMember(people[0].id));
    });

    test(
      'the notice goes away on dismiss and after the next success',
      () async {
        await addExpense(payers: [0]);
        await open();
        await vm().removeMember(people[0].id);
        expect(loaded().notice, isNotNull);
        vm().dismissNotice();
        expect(loaded().notice, isNull);

        await vm().removeMember(people[0].id);
        expect(loaded().notice, isNotNull);
        ok(await vm().addMember('Dee'));
        expect(loaded().notice, isNull);
      },
    );

    test('unknown member is NotFound; failure is reported', () async {
      await open();
      expect(err(await vm().removeMember('nope')), isA<NotFound>());
      app.members.failWith = const Storage('x');
      expect(err(await vm().removeMember(people[0].id)), isA<Storage>());
    });

    test('before loading there is nobody to remove', () async {
      expect(err(await vm().removeMember(people[0].id)), isA<NotFound>());
    });
  });

  group('updateGroup', () {
    test('renames and changes the currency', () async {
      await open();
      final g = ok(
        await vm().updateGroup(name: ' Ski ', currency: Currency.chf),
      );
      expect(g.name, 'Ski');
      await pumpEventQueue();
      expect(loaded().group.currency, Currency.chf);
    });

    test('locks the currency once entries exist, but not the name', () async {
      await addExpense();
      await open();
      expect(loaded().canChangeCurrency, isFalse);
      expect(
        err(await vm().updateGroup(name: 'Trip', currency: Currency.usd)),
        isA<Conflict>(),
      );
      ok(await vm().updateGroup(name: 'Ski', currency: Currency.eur));
    });

    test('validates and reports failures', () async {
      await open();
      expect(
        err(await vm().updateGroup(name: ' ', currency: Currency.eur)),
        isA<InvalidData>(),
      );
      app.groups.failWith = const Storage('x');
      expect(
        err(await vm().updateGroup(name: 'Ski', currency: Currency.eur)),
        isA<Storage>(),
      );
    });

    test('before loading the group is unknown', () async {
      expect(
        err(await vm().updateGroup(name: 'Ski', currency: Currency.eur)),
        isA<NotFound>(),
      );
    });
  });

  group('archive', () {
    test('archives; undo brings the group back', () async {
      await open();
      final undo = ok(await vm().archive());
      await pumpEventQueue();
      expect(state(), isA<GroupDetailFailure>());
      ok(await undo());
      await pumpEventQueue();
      expect(state(), isA<GroupDetailLoaded>());
    });

    test('reports a repository failure', () async {
      await open();
      app.groups.failWith = const Storage('x');
      expect(err(await vm().archive()), isA<Storage>());
    });
  });
}
