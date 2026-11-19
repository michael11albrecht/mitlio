import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/sync/data/repositories/connections_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../repo_test_support.dart';

/// The "verbunden" badge, "Verbindung trennen" with its undo window and
/// "Das bin ich" on the real screen (German, the default locale).
void main() {
  late FakeApp app;
  late Group trip;
  late List<GroupMember> people;

  GroupConnections shared({
    bool owner = true,
    Set<int> connected = const {0, 1},
    int? me = 0,
  }) => GroupConnections(
    shared: true,
    isOwner: owner,
    signedIn: true,
    connectedIds: {for (final i in connected) people[i].id},
    myMemberId: me == null ? null : people[me].id,
  );

  Future<void> open(WidgetTester tester, GroupConnections c) async {
    app.connections.state = c;
    await pumpMitlio(tester, app);
    await tester.tap(find.text('Trip'));
    await tester.pumpAndSettle();
  }

  /// The bar shows (animation), waits its 4 seconds, and hides again.
  Future<void> barCloses(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  final badge = find.text('verbunden');
  final disconnect = find.text('Verbindung trennen');

  setUp(() async {
    app = FakeApp();
    trip = ok(
      await app.groups.create(
        name: 'Trip',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Anna', 'Ben', 'Chiara'])
        ok(await app.members.add(trip.id, name: n)),
    ];
  });

  group('badge', () {
    testWidgets('a local group shows no badge and no actions', (tester) async {
      await open(tester, GroupConnections.localOnly);
      expect(badge, findsNothing);
      expect(disconnect, findsNothing);
      expect(find.text('Das bin ich'), findsNothing);
    });

    testWidgets('the owner sees it on connected people', (tester) async {
      await open(tester, shared());
      expect(badge, findsNWidgets(2));
      // Not on yourself (Anna), only on Ben.
      expect(disconnect, findsOneWidget);
    });

    testWidgets('a member sees the badge but no disconnect', (tester) async {
      await open(tester, shared(owner: false));
      expect(badge, findsNWidgets(2));
      expect(disconnect, findsNothing);
    });
  });

  group('Verbindung trennen', () {
    testWidgets('undo: the badge comes back and nothing is sent', (
      tester,
    ) async {
      await open(tester, shared());
      await tester.tap(disconnect);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Ben ist nicht mehr verbunden'), findsOneWidget);
      expect(badge, findsOneWidget);

      await tester.tap(find.text('Rückgängig'));
      await barCloses(tester);
      expect(app.connections.disconnectCalls, isEmpty);
      expect(badge, findsNWidgets(2));
      expect(disconnect, findsOneWidget);
    });

    testWidgets('the bar closing commits once; the person stays', (
      tester,
    ) async {
      await open(tester, shared());
      await tester.tap(disconnect);
      await tester.pump();
      expect(app.connections.disconnectCalls, isEmpty);

      await barCloses(tester);
      expect(app.connections.disconnectCalls, [(trip.id, people[1].id)]);
      expect(badge, findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
    });

    testWidgets('leaving the screen while the bar is open still commits', (
      tester,
    ) async {
      await open(tester, shared());
      await tester.tap(disconnect);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(BackButton));
      await tester.pump(const Duration(milliseconds: 500));
      expect(app.connections.disconnectCalls, isEmpty);

      await barCloses(tester);
      expect(app.connections.disconnectCalls, [(trip.id, people[1].id)]);
    });

    testWidgets('a second snack bar replacing the first commits it', (
      tester,
    ) async {
      await open(tester, shared(connected: {0, 1, 2}));
      await tester.tap(disconnect.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(disconnect.first);
      await barCloses(tester);
      expect(app.connections.disconnectCalls.length, 2);
    });

    testWidgets('offline: says nothing changed, the badge stays', (
      tester,
    ) async {
      app.connections.failDisconnect = const Offline();
      await open(tester, shared());
      await tester.tap(disconnect);
      await barCloses(tester);
      expect(
        find.textContaining('Nichts geändert: Ben bleibt verbunden'),
        findsOneWidget,
      );
      expect(badge, findsNWidgets(2));
      expect(disconnect, findsOneWidget);
    });
  });

  group('Das bin ich', () {
    testWidgets('on unconnected people of a shared group', (tester) async {
      await open(tester, shared(owner: false, me: null, connected: {1}));
      expect(find.text('Das bin ich'), findsNWidgets(2));
    });

    testWidgets('connects, then goes away', (tester) async {
      await open(tester, shared(owner: false, me: null, connected: {1}));
      await tester.tap(find.text('Das bin ich').first);
      await tester.pumpAndSettle();
      expect(app.connections.connectCalls, [(trip.id, people[0].id)]);
      expect(find.text('Das bin ich'), findsNothing);
      expect(badge, findsNWidgets(2));
    });

    testWidgets('a refusal says why, the person stays unconnected', (
      tester,
    ) async {
      app.connections.failConnect = const MemberAlreadyClaimed();
      await open(tester, shared(owner: false, me: null, connected: {1}));
      await tester.tap(find.text('Das bin ich').first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Anna ist schon mit einem anderen Handy'),
        findsOneWidget,
      );
      expect(find.text('Das bin ich'), findsNWidgets(2));
    });

    testWidgets('hidden once you are connected', (tester) async {
      await open(tester, shared(owner: false, connected: {0}));
      expect(find.text('Das bin ich'), findsNothing);
    });
  });
}
