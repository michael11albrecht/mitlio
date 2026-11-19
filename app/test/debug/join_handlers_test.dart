import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/join.dart';

import '../features/sync/support/join_support.dart';

void main() {
  late JoinWorld w;
  late ProviderContainer c;
  late Map<String, DriveHandler> h;

  setUp(() async {
    w = await JoinWorld.create();
    c = w.container();
    h = joinDriveHandlers(c);
  });

  test('needs a token and a join before connect', () async {
    expect((await h['join']!({}))['error'], 'invalid_params');
    expect((await h['join.connect']!({}))['error'], 'invalid_params');
    expect(
      (await h['join.connect']!({'memberId': 'm-peter'}))['error'],
      'invalid_params',
    );
  });

  test('joins, lists the people, connects; the token is cut short', () async {
    final joined = await h['join']!({'token': w.token});
    expect(joined['state'], 'choosePerson');
    expect(joined['groupId'], joinGroupId);
    expect(joined['token'], '${w.token.substring(0, 4)}…');
    expect(joined.toString(), isNot(contains(w.token)));
    expect((joined['people']! as List).length, 3);

    final done = await h['join.connect']!({'memberId': 'm-peter'});
    expect(done['state'], 'done');
    expect(done.toString(), isNot(contains(w.token)));
  });

  test('a person taken is reported with its case', () async {
    await h['join']!({'token': w.token});
    final r = await h['join.connect']!({'memberId': 'm-bob'});
    expect(r['state'], 'choosePerson', reason: 'connected people are refused');
  });

  test('creates a person', () async {
    await h['join']!({'token': w.token});
    expect((await h['join.create']!({'name': ' '}))['error'], 'nameRequired');
    expect((await h['join.create']!({'name': 'Carla'}))['state'], 'done');
  });

  test('skip', () async {
    await h['join']!({'token': w.token});
    expect((await h['join.skip']!({}))['state'], 'done');
  });

  test('errors carry the case name', () async {
    final r = await h['join']!({'token': 'tok-unknown-0'});
    expect(r['state'], 'failed');
    expect(r['error'], 'inviteInvalid');
  });
}
