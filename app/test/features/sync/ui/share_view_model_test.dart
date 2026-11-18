import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/ui/share_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/share_support.dart';

void main() {
  final de = AppLocalizationsDe();
  final en = AppLocalizationsEn();
  final langs = <AppLocalizations>[de, en];

  late ProviderContainer c;
  late ShareViewModel vm;

  /// Builds the view model of [world] and keeps it alive (auto dispose).
  void open(ShareWorld world) {
    c = world.container()
      ..listen(shareViewModelProvider(shareGroupId), (_, _) {});
    vm = c.read(shareViewModelProvider(shareGroupId).notifier);
  }

  ShareState state() => c.read(shareViewModelProvider(shareGroupId));
  ShareReady ready() => state() as ShareReady;
  ShareFailure failure() => (state() as ShareFailed).failure;

  group('owner, local group', () {
    late ShareWorld w;
    setUp(() async {
      w = await ShareWorld.create();
      open(w);
    });

    test('starts loading', () {
      expect(state(), isA<ShareLoading>());
    });

    test('shares the group first, then shows its new link', () async {
      await vm.share();
      final s = ready();
      expect(s.isOwner, isTrue);
      expect(s.groupName, 'Trip');
      expect(s.link.url, startsWith('https://mitlio.web.app/join/'));
      expect(s.link.url, endsWith(w.storedToken!));
      expect(
        (await w.db.syncStateDao.groupSync(shareGroupId))!.state,
        SyncState.shared.name,
      );
      expect(w.remote.hasMember(shareGroupId), isTrue);
      expect(w.remote.row('groups', shareGroupId), isNotNull);
    });

    test('a second open shows the stored link, no new one is made', () async {
      await vm.share();
      final first = ready().link;
      final createCalls = w.invites.calls;
      await vm.share();
      expect(ready().link.token, first.token);
      expect(w.invites.calls, createCalls);
    });

    test('the token never shows up in toString or the short url', () async {
      await vm.share();
      final link = ready().link;
      expect('$link', isNot(contains(link.token)));
      expect(link.shortUrl, isNot(contains(link.token)));
      expect(link.shortUrl, startsWith('mitlio.web.app/join/'));
    });

    test('rotate: ask, cancel, ask, confirm replaces the link', () async {
      await vm.share();
      final old = ready().link.token;
      vm.askRotate();
      expect(ready().confirmingRotate, isTrue);
      vm.cancelRotate();
      expect(ready().confirmingRotate, isFalse);
      expect(ready().link.token, old);

      vm.askRotate();
      await vm.confirmRotate();
      final s = ready();
      expect(s.link.token, isNot(old));
      expect(s.confirmingRotate, isFalse);
      expect(s.rotateError, isNull);
      expect(w.storedToken, s.link.token);
      // The server revoked the old link at once.
      expect(
        (await w.invites.isCurrentLink(
          shareGroupId,
          old,
        ) as Ok<bool, Object?>).value,
        isFalse,
      );
    });

    test('confirming without asking first does nothing visible', () async {
      await vm.share();
      final old = ready().link.token;
      vm.cancelRotate();
      await vm.confirmRotate();
      // confirmRotate is the second step: it still works when asked for.
      expect(ready().link.token, isNot(old));
    });

    test('a failed rotate keeps the old link and says why', () async {
      await vm.share();
      final old = ready().link.token;
      vm.askRotate();
      w.invites.failNext(const Offline());
      await vm.confirmRotate();
      final s = ready();
      expect(s.link.token, old);
      expect(s.confirmingRotate, isTrue);
      expect(s.rotating, isFalse);
      for (final l in langs) {
        expect(
          s.rotateError!.text(l),
          remoteErrorText(l, const Offline()),
        );
      }
      // Trying again works.
      await vm.confirmRotate();
      expect(ready().link.token, isNot(old));
      expect(ready().rotateError, isNull);
    });

    test('the system share gets the invitation text', () async {
      await vm.share();
      final result = await vm.shareLink(de);
      expect(result, isA<Ok<void, Object>>());
      expect(
        w.share.shared.single,
        'Komm in die Gruppe Trip bei mitlio: ${ready().link.url}',
      );
      await vm.shareLink(en);
      expect(
        w.share.shared.last,
        'Join the group Trip on mitlio: ${ready().link.url}',
      );
    });

    test('a system share that fails is an Err for the view', () async {
      await vm.share();
      w.share.failWith = Exception('no share sheet');
      expect(await vm.shareLink(de), isA<Err<void, Object>>());
    });

    test('shareLink before there is a link is a no-op', () async {
      expect(await vm.shareLink(de), isA<Ok<void, Object>>());
      expect(w.share.shared, isEmpty);
    });

    test('a running share() ignores a second call', () async {
      final a = vm.share();
      final b = vm.share();
      await Future.wait([a, b]);
      expect(w.invites.calls, 1);
    });

    test('keychain write failure: the link works, the view is told', () async {
      w.store.failWrite = Exception('keychain locked');
      await vm.share();
      expect(ready().link.saved, isFalse);
      expect(w.storedToken, isNull);
    });

    test('keychain read failure: no silent new link', () async {
      await vm.share();
      final createCalls = w.invites.calls;
      w.store.failRead = Exception('keychain locked');
      await vm.share();
      expect(
        failure(),
        const ShareFailureLink(LinkStoreUnreadable()),
      );
      expect(w.invites.calls, createCalls);
      for (final l in langs) {
        expect(
          failure().text(l),
          l.inviteStoreUnreadable,
        );
      }
    });
  });

  group('share failures (group still local)', () {
    test('offline: the upload text with the numbers and the cause', () async {
      final w = await ShareWorld.create();
      open(w);
      w.remote.offline = true;
      await vm.share();
      expect(failure(), isA<ShareFailureUpload>());
      for (final l in langs) {
        final text = failure().text(l);
        expect(text, contains(remoteErrorText(l, const Offline())));
        expect(text, startsWith(l.shareUploadPartial(0, 3)));
      }
      // Nothing changed locally; trying again works.
      expect(await w.db.syncStateDao.groupSync(shareGroupId), isNull);
      w.remote.offline = false;
      await vm.share();
      expect(state(), isA<ShareReady>());
    });

    test('a removed group says so', () async {
      final w = await ShareWorld.create();
      await w.db.syncStateDao.setState(shareGroupId, SyncState.removed);
      open(w);
      await vm.share();
      expect(
        failure(),
        const ShareFailureUpload(ShareGroupRemoved()),
      );
      for (final l in langs) {
        expect(failure().text(l), l.remoteErrorNotMember);
      }
    });

    test('a server that keeps failing is a visible upload failure', () async {
      final w = await ShareWorld.create();
      open(w);
      // One entry is refused, the rest is waiting.
      w.remote.failNext(const ServerDown(), times: 99);
      await vm.share();
      expect(failure(), isA<ShareFailureUpload>());
    });

    test('the sign-in failing is shown, not swallowed', () async {
      final w = await ShareWorld.create();
      w.auth.failWith = const RateLimitedRemote(Duration(minutes: 3));
      open(w);
      await vm.share();
      for (final l in langs) {
        expect(
          failure().text(l),
          contains(l.remoteErrorRateLimitedIn(3)),
        );
      }
    });

    test('unfinished upload text is the partial text', () {
      for (final l in langs) {
        expect(
          const ShareFailureUnfinished(2, 5).text(l),
          l.shareUploadPartial(2, 5),
        );
      }
    });

    test('a group that is not on this phone', () {
      for (final l in langs) {
        expect(
          const ShareFailureUpload(ShareGroupMissing()).text(l),
          l.shareGroupMissing,
        );
      }
    });
  });

  group('owner, shared group, link errors', () {
    final errors = <RemoteError>[
      const Offline(),
      const RateLimitedRemote(Duration(minutes: 6)),
      const RateLimitedRemote(null),
      const NotOwner(),
      const NotMember(),
      const ServerDown(),
      const VersionTooOld(),
    ];

    for (final error in errors) {
      test(
        'creating the link fails with $error: visible in de and en',
        () async {
          final w = await ShareWorld.create();
          // Shared already, owner, no stored link (e.g. a new phone).
          await w.remote.upsertRows('groups', [
            {
              'id': shareGroupId,
              'name': 'Trip',
              'currency': 'EUR',
              'created_at': '2026-03-01T00:00:00.000Z',
              'updated_at': '2026-03-01T00:00:00.000Z-0001-a',
              'deleted_at': null,
            },
          ]);
          await w.remote.bootstrapMembership(shareGroupId);
          await w.db.syncStateDao.setState(
            shareGroupId,
            SyncState.shared,
            role: SyncRole.owner,
          );
          open(w);
          w.invites.failNext(error);
          await vm.share();
          expect(failure(), ShareFailureLink(LinkRemoteFailure(error)));
          for (final l in langs) {
            expect(failure().text(l), remoteErrorText(l, error));
          }
          expect(w.storedToken, isNull);
          // Retry works once the server answers.
          await vm.share();
          expect(state(), isA<ShareReady>());
        },
      );
    }

    test('the exact German words of the main cases', () {
      expect(
        remoteErrorText(de, const Offline()),
        'Keine Verbindung. Deine Änderungen sind gespeichert und gehen raus, '
        'sobald du online bist.',
      );
      expect(
        remoteErrorText(de, const RateLimitedRemote(Duration(minutes: 6))),
        'Zu viele Versuche. Versuch es in 6 Min. nochmal.',
      );
      expect(
        remoteErrorText(de, const NotOwner()),
        'Das kann nur, wer die Gruppe erstellt hat.',
      );
      expect(
        remoteErrorText(de, const ServerDown()),
        'Der Server antwortet gerade nicht. Wir versuchen es gleich nochmal.',
      );
    });
  });

  group('member', () {
    test('sees the stored link and no way to make a new one', () async {
      final w = await ShareWorld.createMember();
      open(w);
      final base = w.invites.calls;
      await vm.share();
      final s = ready();
      expect(s.isOwner, isFalse);
      expect(s.link.token, w.storedToken);
      vm.askRotate();
      expect(ready().confirmingRotate, isFalse);
      await vm.confirmRotate();
      expect(ready().link.token, s.link.token);
      // The member never calls create_invite.
      expect(w.invites.calls, base + 1); // only the validation read
    });

    test('the owner made a new link: the stored one is refused', () async {
      final w = await ShareWorld.createMember();
      await w.serverInvites.createInvite(shareGroupId);
      open(w);
      await vm.share();
      expect(failure(), const ShareFailureLink(LinkRotated()));
      expect(w.storedToken, isNull);
      expect(
        failure().text(de),
        'Dieser Link gilt nicht mehr. Frag, wer die Gruppe erstellt hat, '
        'nach dem neuen.',
      );
      expect(
        failure().text(en),
        'This link no longer works. Ask whoever created the group for the '
        'new one.',
      );
    });

    test('no stored link: asks the owner, never creates one', () async {
      final w = await ShareWorld.createMember(keepLink: false);
      open(w);
      await vm.share();
      expect(failure(), const ShareFailureLink(LinkNotKnownToMember()));
      for (final l in langs) {
        expect(failure().text(l), l.inviteNoLinkMember);
      }
      expect(w.invites.calls, 1); // the join in the fixture only
      expect(w.storedToken, isNull);
    });

    test('offline while checking the link: offline text, link kept', () async {
      final w = await ShareWorld.createMember();
      open(w);
      w.invites.offline = true;
      await vm.share();
      expect(failure(), const ShareFailureLink(LinkRemoteFailure(Offline())));
      expect(w.storedToken, isNotNull);
    });

    test('a stale link that cannot be deleted is still refused', () async {
      final w = await ShareWorld.createMember();
      await w.serverInvites.createInvite(shareGroupId);
      w.store.failDelete = Exception('keychain locked');
      open(w);
      await vm.share();
      expect(failure(), const ShareFailureLink(LinkRotated()));
    });

    test('removed from the group: the sheet says so', () async {
      final w = await ShareWorld.createMember();
      await w.db.syncStateDao.setState(shareGroupId, SyncState.removed);
      open(w);
      await vm.share();
      for (final l in langs) {
        expect(failure().text(l), l.remoteErrorNotMember);
      }
    });
  });

  group('ShareLinkRepository', () {
    test('saveToken tells when the keychain refused', () async {
      final w = await ShareWorld.create();
      open(w);
      final repo = c.read(shareLinkRepositoryProvider);
      expect(await repo.saveToken(shareGroupId, 'abc'), isTrue);
      w.store.failWrite = Exception('x');
      expect(await repo.saveToken(shareGroupId, 'abc'), isFalse);
    });

    test('forget removes the stored link, and fails loudly', () async {
      final w = await ShareWorld.create();
      open(w);
      final repo = c.read(shareLinkRepositoryProvider);
      await repo.saveToken(shareGroupId, 'abc');
      await repo.forget(shareGroupId);
      expect(w.storedToken, isNull);
      w.store.failDelete = Exception('x');
      expect(repo.forget(shareGroupId), throwsException);
    });
  });
}
