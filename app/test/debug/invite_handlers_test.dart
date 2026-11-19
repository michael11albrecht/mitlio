import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/share.dart';

import '../features/sync/support/share_support.dart';

void main() {
  late ProviderContainer c;
  late Map<String, DriveHandler> h;

  Future<ShareWorld> start({bool member = false, bool keepLink = true}) async {
    final w = member
        ? await ShareWorld.createMember(keepLink: keepLink)
        : await ShareWorld.create();
    c = w.container();
    h = shareDriveHandlers(c);
    return w;
  }

  test('both commands need a groupId', () async {
    await start();
    expect((await h['group.invite']!({}))['error'], 'invalid_params');
    expect((await h['group.rotateInvite']!({}))['error'], 'invalid_params');
  });

  test('invite shares the group and reports a shortened link only', () async {
    final w = await start();
    final out = await h['group.invite']!({'groupId': shareGroupId});
    expect(out['isOwner'], isTrue);
    expect(out['saved'], isTrue);
    expect(out['link'], startsWith('mitlio.de/join/'));
    // The secret never leaves the app through DebugDrive.
    expect(jsonEncode(out), isNot(contains(w.storedToken)));
    expect(w.remote.hasMember(shareGroupId), isTrue);
  });

  test('invite twice keeps the same link', () async {
    final w = await start();
    await h['group.invite']!({'groupId': shareGroupId});
    final token = w.storedToken;
    await h['group.invite']!({'groupId': shareGroupId});
    expect(w.storedToken, token);
  });

  test('rotateInvite replaces the link', () async {
    final w = await start();
    await h['group.invite']!({'groupId': shareGroupId});
    final old = w.storedToken;
    final out = await h['group.rotateInvite']!({'groupId': shareGroupId});
    expect(out['error'], isNull);
    expect(w.storedToken, isNot(old));
  });

  test('a failure carries the error case', () async {
    final w = await start();
    w.remote.offline = true;
    final out = await h['group.invite']!({'groupId': shareGroupId});
    expect(out['error'], 'offline');
    expect(out['total'], 3);
  });

  test('a failed rotate carries its case and keeps the link', () async {
    final w = await start();
    await h['group.invite']!({'groupId': shareGroupId});
    final old = w.storedToken;
    w.invites.failNext(const NotOwner());
    final out = await h['group.rotateInvite']!({'groupId': shareGroupId});
    expect(out['error'], 'notOwner');
    expect(w.storedToken, old);
  });

  test('a member whose link was replaced gets linkRotated', () async {
    final w = await start(member: true);
    await w.serverInvites.createInvite(shareGroupId);
    final out = await h['group.invite']!({'groupId': shareGroupId});
    expect(out['error'], 'linkRotated');
  });

  test('a member without a stored link gets linkNotKnown', () async {
    await start(member: true, keepLink: false);
    final out = await h['group.invite']!({'groupId': shareGroupId});
    expect(out['error'], 'linkNotKnown');
  });
}
