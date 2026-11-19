import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/connections.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/sync/data/repositories/connections_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart';
import '../helpers/fake_app.dart';

void main() {
  late FakeApp app;
  late Map<String, DriveHandler> h;
  late Group trip;
  late List<GroupMember> people;

  setUp(() async {
    app = FakeApp();
    final container = app.container();
    addTearDown(container.dispose);
    h = connectionsDriveHandlers(container);
    trip = ok(
      await app.groups.create(
        name: 'Trip',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Anna', 'Ben'])
        ok(await app.members.add(trip.id, name: n)),
    ];
    app.connections.state = GroupConnections(
      shared: true,
      isOwner: true,
      signedIn: true,
      connectedIds: {people[1].id},
      myMemberId: null,
    );
  });

  test('both commands need groupId and memberId', () async {
    for (final key in ['group.removeConnection', 'group.connectMe']) {
      expect((await h[key]!({}))['error'], 'invalid_params');
      expect((await h[key]!({'groupId': trip.id}))['error'], 'invalid_params');
    }
  });

  test('removeConnection ends the connection, no undo window', () async {
    final result = await h['group.removeConnection']!({
      'groupId': trip.id,
      'memberId': people[1].id,
    });
    expect(result, {'ok': true});
    expect(app.connections.disconnectCalls, [(trip.id, people[1].id)]);
  });

  test('removeConnection reports the case and the German words', () async {
    app.connections.failDisconnect = const Offline();
    final result = await h['group.removeConnection']!({
      'groupId': trip.id,
      'memberId': people[1].id,
    });
    expect(result['error'], 'offline');
    expect(result['message'], contains('Nichts geändert'));
  });

  test('connectMe connects this account', () async {
    final result = await h['group.connectMe']!({
      'groupId': trip.id,
      'memberId': people[0].id,
    });
    expect(result, {'ok': true});
    expect(app.connections.connectCalls, [(trip.id, people[0].id)]);
  });

  test('connectMe reports the refusal', () async {
    app.connections.failConnect = const MemberAlreadyClaimed();
    final result = await h['group.connectMe']!({
      'groupId': trip.id,
      'memberId': people[0].id,
    });
    expect(result['error'], 'memberAlreadyClaimed');
    expect(result['message'], contains('Anna'));
  });
}
