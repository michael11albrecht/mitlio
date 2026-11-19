import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/repositories/join_repository.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio/features/sync/ui/join_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/join_support.dart';

void main() {
  final de = AppLocalizationsDe();
  final en = AppLocalizationsEn();
  final langs = <AppLocalizations>[de, en];

  late JoinWorld w;
  late ProviderContainer c;
  late JoinViewModel vm;

  Future<void> open({String? token}) async {
    w = await JoinWorld.create();
    c = w.container();
    final t = token ?? w.token;
    c.listen(joinViewModelProvider(t), (_, _) {});
    vm = c.read(joinViewModelProvider(t).notifier);
  }

  JoinState state() => c.read(joinViewModelProvider(w.token));
  JoinChoosePerson picker() => state() as JoinChoosePerson;
  JoinProblem problem() => switch (state()) {
    JoinFailed(:final problem) => problem,
    JoinChoosePerson(:final notice?) => notice,
    final s => fail('no problem shown: $s'),
  };

  Future<int> localGroups() async => (await w.db.groupsDao.listGroups()).length;

  group('joining', () {
    setUp(open);

    test('asks who you are: people with their connection', () async {
      await vm.start();
      final s = picker();
      expect(s.groupName, joinGroupName);
      expect(
        [for (final p in s.people) (p.name, p.connected)],
        [
          ('Peter', false),
          ('Bob', true),
          ('Jonas', false),
        ],
      );
      final sync = await w.db.syncStateDao.groupSync(joinGroupId);
      expect(sync!.state, SyncState.shared.name);
      expect(sync.role, SyncRole.member.name);
      expect(w.store.values['mitlio.invite.$joinGroupId'], w.token);
    });

    test('claiming a person is the only step', () async {
      await vm.start();
      await vm.choose('m-peter');
      expect(state(), isA<JoinDone>());
      final mine = await w.invites.listMemberships(joinGroupId);
      expect(
        [
          for (final m in (mine as Ok<List<MembershipInfo>, Object?>).value)
            m.memberId,
        ],
        contains('m-peter'),
      );
    });

    test('a person connected elsewhere cannot be picked', () async {
      await vm.start();
      final calls = w.invites.calls;
      await vm.choose('m-bob');
      expect(w.invites.calls, calls, reason: 'no server call');
      expect(state(), isA<JoinChoosePerson>());
    });

    test('"Ich bin neu hier" makes the person, uploads it, connects', () async {
      await vm.start();
      await vm.createPerson('  Carla ');
      expect(state(), isA<JoinDone>());
      final rows = w.owner.row(DbTables.members, 'id-1');
      expect(rows, isNotNull, reason: 'the new person reached the server');
      expect(rows![DbMembersCols.name], 'Carla');
      final members = await w.db.membersDao.listByGroup(joinGroupId);
      expect(members.map((m) => m.name), contains('Carla'));
    });

    test('an empty name asks for one', () async {
      await vm.start();
      await vm.createPerson('   ');
      expect(problem(), isA<JoinProblemNameRequired>());
      for (final l in langs) {
        expect(problem().text(l), l.joinNameRequired);
      }
      expect(await w.db.membersDao.listByGroup(joinGroupId), hasLength(3));
    });

    test(
      'a failed upload keeps the person: retry makes no second one',
      () async {
        await vm.start();
        w.remote.offline = true;
        await vm.createPerson('Carla');
        expect(problem(), isA<JoinProblemConnect>());
        for (final l in langs) {
          expect(problem().text(l), l.joinConnectOffline);
        }
        w.remote.offline = false;
        // The failed push waits for its retry time.
        (c.read(clockProvider) as FixedClock).advance(
          const Duration(minutes: 6),
        );
        await vm.createPerson('Carla');
        expect(state(), isA<JoinDone>());
        final carlas = (await w.db.membersDao.listByGroup(
          joinGroupId,
        )).where((m) => m.name == 'Carla');
        expect(carlas, hasLength(1));
      },
    );

    test('a retry with another name renames the waiting person', () async {
      await vm.start();
      w.remote.offline = true;
      await vm.createPerson('Karla');
      w.remote.offline = false;
      (c.read(clockProvider) as FixedClock).advance(const Duration(minutes: 6));
      await vm.createPerson('Carla');
      expect(state(), isA<JoinDone>());
      final names = (await w.db.membersDao.listByGroup(
        joinGroupId,
      )).map((m) => m.name);
      expect(names, contains('Carla'));
      expect(names, isNot(contains('Karla')));
    });

    test('skipping goes into the group unconnected', () async {
      await vm.start();
      vm.skip();
      expect((state() as JoinDone).groupId, joinGroupId);
    });

    test('opening the link again goes straight to the group', () async {
      await vm.start();
      await vm.choose('m-peter');
      await vm.start();
      expect(state(), isA<JoinDone>());
      expect(await localGroups(), 1);
    });
  });

  group('errors while joining', () {
    setUp(open);

    void expectText(JoinProblem p, String Function(AppLocalizations) want) {
      for (final l in langs) {
        expect(p.text(l), want(l));
      }
    }

    test('invalid, expired and revoked are one message', () async {
      await w.ownerInvites.createInvite(joinGroupId);
      await vm.start();
      final p = problem();
      expect(p.canRetry, isFalse);
      expectText(p, (l) => l.remoteErrorInviteInvalid);
      expect(await localGroups(), 0);
    });

    test('a token nobody knows is the same message', () async {
      final other = c.read(joinViewModelProvider('tok-unknown-0').notifier);
      c.listen(joinViewModelProvider('tok-unknown-0'), (_, _) {});
      await other.start();
      final s = c.read(joinViewModelProvider('tok-unknown-0'));
      expect(
        (s as JoinFailed).problem.text(de),
        de.remoteErrorInviteInvalid,
      );
    });

    test('rate limited names the minutes from the server', () async {
      w.invites.failNext(const RateLimitedRemote(Duration(minutes: 7)));
      await vm.start();
      expectText(problem(), (l) => l.remoteErrorRateLimitedIn(7));
      expect(de.remoteErrorRateLimitedIn(7), contains('7 Min.'));
      expect(await localGroups(), 0);
      // The retry works.
      await vm.start();
      expect(state(), isA<JoinChoosePerson>());
    });

    test('offline: nothing is created on this phone, and it says so', () async {
      w.invites.offline = true;
      await vm.start();
      expectText(problem(), (l) => l.joinOffline);
      expect(await localGroups(), 0);
      expect(await w.db.syncStateDao.groupSync(joinGroupId), isNull);
      expect(w.store.values, isEmpty);
    });

    test('offline while fetching the group row also creates nothing', () async {
      w.remote.offline = true;
      await vm.start();
      expectText(problem(), (l) => l.joinOffline);
      expect(await localGroups(), 0);
    });

    test('server down', () async {
      w.invites.failNext(const ServerDown());
      await vm.start();
      expectText(problem(), (l) => l.remoteErrorServerDown);
    });

    test('app too old', () async {
      w.invites.failNext(const VersionTooOld());
      await vm.start();
      expectText(problem(), (l) => l.remoteErrorVersionTooOld);
    });

    test('the first sync fails after the join: shown, group stays', () async {
      w.remote.failNext(const ServerDown());
      // fetchGroupRow is the first remote call and fails: nothing local.
      await vm.start();
      expectText(problem(), (l) => l.remoteErrorServerDown);
      expect(await localGroups(), 0);
      await vm.start();
      expect(state(), isA<JoinChoosePerson>());
    });

    test('offline after the group is here is not "nothing was created"', () {
      const p = JoinProblemJoin(
        JoinRemoteFailure(Offline(), localCreated: true),
      );
      for (final l in langs) {
        expect(p.text(l), l.remoteErrorOffline);
      }
    });
  });

  group('errors while connecting', () {
    setUp(() async {
      await open();
      await vm.start();
    });

    test(
      'a person taken meanwhile: back to the picker, shown connected',
      () async {
        final other = w.otherPhone('other-1');
        await other.joinGroup(w.token, claimMemberId: 'm-jonas');
        await vm.choose('m-jonas');
        final s = picker();
        expect(s.people.firstWhere((p) => p.id == 'm-jonas').connected, isTrue);
        expect(s.busy, isFalse);
        for (final l in langs) {
          expect(
            s.notice!.text(l),
            l.remoteErrorMemberAlreadyClaimed('Jonas'),
          );
        }
      },
    );

    test('a person who is gone: the list is refreshed', () async {
      await w.owner.upsertRows(DbTables.members, [
        {
          DbMembersCols.id: 'm-jonas',
          DbMembersCols.groupId: joinGroupId,
          DbMembersCols.name: 'Jonas',
          DbMembersCols.position: 2,
          DbMembersCols.canDrive: true,
          DbMembersCols.createdAt: '2026-03-01T00:00:00.000Z',
          DbMembersCols.updatedAt: '2026-03-02T00:00:00.000Z-0001-a',
          DbMembersCols.deletedAt: '2026-03-02T00:00:00.000Z',
        },
      ]);
      await vm.choose('m-jonas');
      final s = picker();
      expect(s.people.map((p) => p.name), ['Peter', 'Bob']);
      for (final l in langs) {
        expect(s.notice!.text(l), l.remoteErrorMemberGone);
      }
    });

    test('already connected to someone: says who, offers the group', () async {
      await w.invites.connectMember(joinGroupId, 'm-peter');
      await vm.choose('m-jonas');
      final s = state() as JoinFailed;
      expect(s.groupId, joinGroupId);
      for (final l in langs) {
        expect(s.problem.text(l), l.remoteErrorAlreadyConnected('Peter'));
      }
    });

    test(
      'offline while connecting: stays in the picker, retry works',
      () async {
        w.invites.failNext(const Offline());
        await vm.choose('m-peter');
        for (final l in langs) {
          expect(picker().notice!.text(l), l.joinConnectOffline);
        }
        await vm.choose('m-peter');
        expect(state(), isA<JoinDone>());
      },
    );

    test('rate limited while connecting names the minutes', () async {
      w.invites.failNext(const RateLimitedRemote(Duration(minutes: 3)));
      await vm.choose('m-peter');
      for (final l in langs) {
        expect(picker().notice!.text(l), l.remoteErrorRateLimitedIn(3));
      }
    });
  });
}
