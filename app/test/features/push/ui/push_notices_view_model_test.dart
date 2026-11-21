import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/push_providers.dart';
import 'package:mitlio/features/push/ui/push_notices_view_model.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';

import 'push_fixtures.dart';

void main() {
  late PushWorld w;
  late ProviderContainer c;

  PushNoticesViewModel vm() => c.read(pushNoticesViewModelProvider.notifier);
  PushNotice? state() => c.read(pushNoticesViewModelProvider);

  setUp(() async {
    w = await PushWorld.create();
    c = w.container()..listen(pushNoticesViewModelProvider, (_, _) {});
  });
  tearDown(() async {
    c.dispose();
    await w.close();
  });

  group('offer', () {
    test(
      'after the first share or join: once, when push can be asked',
      () async {
        await vm().offer();
        expect(state(), isA<PushNoticeOffer>());
      },
    );

    test('not without push, not when asked, not when decided', () async {
      w.service.available = false;
      await vm().offer();
      expect(state(), isNull);
      w.service.available = true;
      w.store.wasAsked = true;
      await vm().offer();
      expect(state(), isNull);
      w.store.wasAsked = false;
      w.service.permissionState = PushPermission.granted;
      await vm().offer();
      expect(state(), isNull);
    });

    test('a note that is showing is not replaced', () async {
      w.service.permissionAnswer = PushPermission.denied;
      await vm().enable();
      expect(state(), isA<PushNoticeDenied>());
      await vm().offer();
      expect(state(), isA<PushNoticeDenied>());
    });
  });

  group('act', () {
    test('"Ja, bitte": asks the OS, registers, the note goes away', () async {
      await vm().offer();
      await vm().act(state()!);
      expect(state(), isNull);
      expect(w.service.permissionRequests, 1);
      expect(w.remote.tokens, hasLength(1));
      expect(w.store.wasAsked, isTrue);
    });

    test('the OS says no: a quiet note says how to change it', () async {
      w.service.permissionAnswer = PushPermission.denied;
      await vm().offer();
      await vm().act(state()!);
      expect(state(), isA<PushNoticeDenied>());
      expect(w.remote.tokens, isEmpty);
    });

    test('a failure is a note with the cause', () async {
      w.remote.offline = true;
      await vm().offer();
      await vm().act(state()!);
      final failed = state()! as PushNoticeFailed;
      expect((failed.error as PushRemoteError).error, const Offline());
    });

    test(
      '"Ansehen" opens the change, notes without action do nothing',
      () async {
        final payload = PushPayload.parse({'group_id': 'g1'})!;
        final incoming = PushNoticeIncoming(payload);
        await vm().act(incoming);
        await vm().act(const PushNoticeDenied());
        await vm().act(const PushNoticeFailed(PushUnavailable()));
        await vm().act(const PushNoticeOpenFailed());
        expect(state(), isNull);
      },
    );
  });

  group('dismissed', () {
    test('an offer that goes unanswered is not made again', () async {
      await vm().offer();
      await vm().dismissed(state()!);
      expect(state(), isNull);
      expect(w.store.wasAsked, isTrue);
      await vm().offer();
      expect(state(), isNull);
    });

    test('other notes just go away', () async {
      w.service.permissionAnswer = PushPermission.denied;
      await vm().enable();
      await vm().dismissed(state()!);
      expect(state(), isNull);
      expect(w.store.wasAsked, isTrue);
    });

    test('clear ignores a note that is not the current one', () async {
      await vm().offer();
      final offer = state()!;
      vm().clear(const PushNoticeDenied());
      expect(state(), same(offer));
      vm().clear(offer);
      expect(state(), isNull);
    });
  });

  group('start', () {
    test(
      'foreground messages become in-app notes, taps are not notes',
      () async {
        await vm().start();
        await vm().start();
        w.service.emitForeground(
          const PushMessage({'group_id': 'g1'}, body: 'Anna hat ...'),
        );
        await pumpEventQueue();
        final note = state()! as PushNoticeIncoming;
        expect(note.body, 'Anna hat ...');
        expect(note.payload.groupId, 'g1');
      },
    );

    test('a tapped notification without ids is a note', () async {
      await vm().start();
      w.service.emitOpened(const PushMessage({'group_id': '../'}));
      await pumpEventQueue();
      expect(state(), isA<PushNoticeOpenFailed>());
    });

    test('keeps the server token current', () async {
      await vm().offer();
      await vm().act(state()!);
      await vm().start();
      w.service.emitTokenRefresh('fake-token-9');
      await pumpEventQueue();
      expect(w.remote.tokensOf('fake-user-1'), contains('fake-token-9'));
      expect(c.read(pushRepositoryProvider).isAvailable, isTrue);
    });
  });

  group('words', () {
    test('every note says what happened and what to do, in de and en', () {
      final de = AppLocalizationsDe();
      final en = AppLocalizationsEn();
      final payload = PushPayload.parse({'group_id': 'g1'})!;
      final notes = <PushNotice>[
        const PushNoticeOffer(),
        PushNoticeIncoming(payload),
        const PushNoticeDenied(),
        const PushNoticeFailed(PushUnavailable()),
        const PushNoticeFailed(PushPlatformError('x')),
        const PushNoticeFailed(PushRemoteError(Offline())),
        const PushNoticeOpenFailed(),
      ];
      for (final n in notes) {
        expect(n.text(de), isNotEmpty);
        expect(n.text(en), isNotEmpty);
        expect(n.text(de), isNot(n.text(en)));
      }
      expect(const PushNoticeOffer().actionLabel(de), 'Ja, bitte');
      expect(PushNoticeIncoming(payload).actionLabel(en), 'Open');
      expect(const PushNoticeDenied().actionLabel(de), isNull);
      expect(PushNoticeIncoming(payload, body: 'B').text(de), 'B');
      expect(
        const PushNoticeFailed(PushRemoteError(Offline())).text(de),
        de.remoteErrorOffline,
      );
    });
  });
}
