import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/sync/data/repositories/connections_repository.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

void main() {
  final langs = <AppLocalizations>[AppLocalizationsDe(), AppLocalizationsEn()];

  late FakeApp app;
  late ProviderContainer container;
  late Group trip;
  late List<GroupMember> people;

  GroupDetailViewModel vm() =>
      container.read(groupDetailViewModelProvider(trip.id).notifier);
  GroupDetailLoaded loaded() =>
      container.read(groupDetailViewModelProvider(trip.id))
          as GroupDetailLoaded;
  MemberItem item(int i) =>
      loaded().members.firstWhere((m) => m.member.id == people[i].id);

  GroupConnections shared({
    bool owner = true,
    bool signedIn = true,
    Set<int> connected = const {1},
    int? me,
  }) => GroupConnections(
    shared: true,
    isOwner: owner,
    signedIn: signedIn,
    connectedIds: {for (final i in connected) people[i].id},
    myMemberId: me == null ? null : people[me].id,
  );

  Future<void> open(GroupConnections c) async {
    app.connections.state = c;
    container.listen(groupDetailViewModelProvider(trip.id), (_, _) {});
    await pumpEventQueue();
  }

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

  group('local group', () {
    test('no badge, no actions', () async {
      await open(GroupConnections.localOnly);
      for (var i = 0; i < 3; i++) {
        expect(item(i).connected, isFalse);
        expect(item(i).canDisconnect, isFalse);
        expect(item(i).canClaim, isFalse);
      }
      expect(vm().beginDisconnect(people[1].id), isNull);
    });
  });

  group('badge', () {
    test('shows where an account is connected', () async {
      await open(shared(connected: {0, 1}, me: 0));
      expect(item(0).connected, isTrue);
      expect(item(1).connected, isTrue);
      expect(item(2).connected, isFalse);
      expect(item(0).isMe, isTrue);
    });

    test('a member sees the badge but has no disconnect action', () async {
      await open(shared(owner: false, me: 0, connected: {0, 1}));
      expect(item(1).connected, isTrue);
      expect(item(1).canDisconnect, isFalse);
      expect(vm().beginDisconnect(people[1].id), isNull);
    });

    test('the owner can disconnect others, never themselves', () async {
      await open(shared(me: 0, connected: {0, 1}));
      expect(item(0).canDisconnect, isFalse);
      expect(item(1).canDisconnect, isTrue);
      expect(item(2).canDisconnect, isFalse); // not connected
      expect(vm().beginDisconnect(people[0].id), isNull);
      expect(app.connections.disconnectCalls, isEmpty);
    });

    test('shows in the debug snapshot only for shared groups', () async {
      await open(shared());
      final m = vm().debugSnapshot()['members']! as List;
      expect((m[1]! as Map)['connected'], isTrue);
      expect((m[1]! as Map)['canDisconnect'], isTrue);
    });
  });

  group('disconnect (deferred)', () {
    setUp(() => open(shared(me: 0, connected: {0, 1})));

    test('begin hides the badge but sends nothing; undo brings it back', () {
      expect(vm().beginDisconnect(people[1].id), 'Ben');
      expect(item(1).connected, isFalse);
      expect(item(1).canDisconnect, isFalse);
      expect(app.connections.disconnectCalls, isEmpty);
      vm().undoDisconnect(people[1].id);
      expect(item(1).connected, isTrue);
      expect(item(1).canDisconnect, isTrue);
      expect(app.connections.disconnectCalls, isEmpty);
    });

    test('commit removes the account; the person stays', () async {
      vm().beginDisconnect(people[1].id);
      expect(await vm().commitDisconnect(people[1].id), isNull);
      await pumpEventQueue();
      expect(app.connections.disconnectCalls, [(trip.id, people[1].id)]);
      expect(item(1).connected, isFalse);
      expect(loaded().members.map((m) => m.member.name), [
        'Ann',
        'Ben',
        'Cy',
      ]);
    });

    test('commit without begin does nothing', () async {
      expect(await vm().commitDisconnect(people[1].id), isNull);
      expect(app.connections.disconnectCalls, isEmpty);
    });

    for (final error in const <RemoteError>[
      NotOwner(),
      CannotRemoveSelf(),
      Offline(),
      ServerDown(),
      RateLimitedRemote(Duration(minutes: 3)),
      NotMember(),
    ]) {
      test(
        '$error: the badge stays and the text says nothing changed',
        () async {
          app.connections.failDisconnect = error;
          vm().beginDisconnect(people[1].id);
          final problem = await vm().commitDisconnect(people[1].id);
          await pumpEventQueue();
          expect(problem, isNotNull);
          expect(problem!.error, error);
          expect(item(1).connected, isTrue);
          expect(item(1).canDisconnect, isTrue);
          for (final l10n in langs) {
            final text = problem.text(l10n);
            expect(
              text,
              anyOf(
                contains('Nichts geändert'),
                contains('Nothing changed'),
              ),
              reason: '${l10n.localeName}: $text',
            );
            if (error is Offline || error is ServerDown) {
              expect(text, contains('Ben'));
            }
          }
        },
      );
    }

    test('disconnectNow (DebugDrive) skips the undo window', () async {
      expect(await vm().disconnectNow(people[1].id), isNull);
      expect(app.connections.disconnectCalls, [(trip.id, people[1].id)]);
    });
  });

  group('Das bin ich', () {
    test('offered to a signed-in member not connected to anyone', () async {
      await open(shared(owner: false, connected: {1}));
      expect(item(0).canClaim, isTrue);
      expect(item(1).canClaim, isFalse); // taken
      expect(item(2).canClaim, isTrue);
    });

    test('hidden once connected, signed out, or for local groups', () async {
      await open(shared(me: 0, connected: {0}));
      expect(item(2).canClaim, isFalse);
      app.connections.state = shared(signedIn: false, connected: {});
      await pumpEventQueue();
      expect(item(2).canClaim, isFalse);
      app.connections.state = GroupConnections.localOnly;
      await pumpEventQueue();
      expect(item(2).canClaim, isFalse);
    });

    test('connects through the shared connect path', () async {
      await open(shared(owner: false, connected: {1}));
      expect(await vm().connectMe(people[2].id), isNull);
      await pumpEventQueue();
      expect(app.connections.connectCalls, [(trip.id, people[2].id)]);
      expect(item(2).connected, isTrue);
      expect(item(2).isMe, isTrue);
      expect(item(0).canClaim, isFalse);
    });

    test('a taken person is refused without a call', () async {
      await open(shared(owner: false, connected: {1}));
      expect(await vm().connectMe(people[1].id), isNull);
      expect(app.connections.connectCalls, isEmpty);
    });

    test('each error has its join text, de and en', () async {
      await open(shared(owner: false, connected: {1}));
      for (final error in const <RemoteError>[
        Offline(),
        MemberAlreadyClaimed(),
        MemberGone(),
        ServerDown(),
        NotMember(),
        RateLimitedRemote(Duration(minutes: 2)),
      ]) {
        app.connections.failConnect = error;
        final problem = await vm().connectMe(people[2].id);
        expect(problem!.error, error);
        for (final l10n in langs) {
          expect(problem.text(l10n), isNotEmpty);
        }
      }
      // A stale list is pulled again.
      expect(app.connections.refreshCalls, 2);
      app.connections.failConnect = const MemberAlreadyClaimed();
      final claimed = (await vm().connectMe(people[2].id))!;
      expect(claimed.text(langs.first), contains('Cy'));
    });

    test('already connected names the person you are', () async {
      await open(shared(owner: false, connected: {1}));
      app.connections
        ..failConnect = const AlreadyConnected()
        ..refreshedName = 'Ann';
      final problem = (await vm().connectMe(people[2].id))!;
      expect(app.connections.refreshCalls, 1);
      expect(problem.text(langs.first), contains('Ann'));
      expect(problem.text(langs.last), contains('Ann'));
    });
  });
}
