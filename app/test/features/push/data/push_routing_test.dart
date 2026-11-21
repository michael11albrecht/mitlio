import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/repositories/push_routing.dart';
import 'package:mitlio/features/push/data/services/fake_push_service.dart';

const _expense = PushMessage({
  'group_id': 'g1',
  'event': 'expense_added',
  'expense_id': 'e1',
  'link': 'mitlio://group/g1/expense/e1',
  'hide_amounts': 'false',
}, body: 'Anna hat „Tanken“ eingetragen · 42,00 €');

void main() {
  late FakePushService service;
  late List<String> pulled;
  late List<List<String>> shown;
  late List<Object> errors;
  late Exception? pullFails;
  late PushRouting routing;

  setUp(() {
    service = FakePushService();
    pulled = [];
    shown = [];
    errors = [];
    pullFails = null;
    routing = PushRouting(
      service: service,
      pull: (groupId) async {
        pulled.add(groupId);
        final e = pullFails;
        if (e != null) throw e;
      },
      navigate: shown.add,
      onError: (e, _) => errors.add(e),
    );
  });
  tearDown(() async {
    await routing.dispose();
    await service.dispose();
  });

  group('handle', () {
    test('tap: pulls first, then opens the group and the expense', () async {
      final order = <String>[];
      routing = PushRouting(
        service: service,
        pull: (_) async => order.add('pull'),
        navigate: (_) => order.add('navigate'),
        onError: (e, _) => errors.add(e),
      );
      final r = await routing.handle(_expense, PushSource.tap);
      expect(order, ['pull', 'navigate']);
      expect(r.pulled, isTrue);
      expect(r.opened, ['/groups/g1', '/groups/g1/expenses/e1']);
      expect(r.announced, isNull);
    });

    test('tap on a group message opens just the group', () async {
      await routing.handle(
        const PushMessage({'group_id': 'g1', 'event': 'group_updates'}),
        PushSource.tap,
      );
      expect(pulled, ['g1']);
      expect(shown, [
        ['/groups/g1'],
      ]);
    });

    test('foreground: pulls and announces, never navigates', () async {
      final seen = <PushAnnouncement>[];
      routing.announcements.listen(seen.add);
      final r = await routing.handle(_expense, PushSource.foreground);
      await pumpEventQueue();
      expect(pulled, ['g1']);
      expect(shown, isEmpty);
      final note = r.announced! as PushIncoming;
      expect(note.text, 'Anna hat „Tanken“ eingetragen · 42,00 €');
      expect(note.payload.expenseId, 'e1');
      expect(seen, [note]);
    });

    test(
      'foreground with hidden amounts: generic words, not the body',
      () async {
        final r = await routing.handle(
          const PushMessage({
            'group_id': 'g1',
            'hide_amounts': 'true',
          }, body: 'Anna · 42,00 €'),
          PushSource.foreground,
        );
        expect((r.announced! as PushIncoming).text, isNull);
      },
    );

    test('background: pull only', () async {
      final r = await routing.handle(_expense, PushSource.background);
      expect(pulled, ['g1']);
      expect(shown, isEmpty);
      expect(r.announced, isNull);
      expect(r.pulled, isTrue);
    });

    test(
      'a message without a usable group is reported, a tap says so',
      () async {
        final seen = <PushAnnouncement>[];
        routing.announcements.listen(seen.add);
        const bad = PushMessage({'group_id': '../x'});
        final tap = await routing.handle(bad, PushSource.tap);
        final fg = await routing.handle(bad, PushSource.foreground);
        await pumpEventQueue();
        expect(tap.announced, isA<PushOpenFailed>());
        expect(fg.announced, isNull);
        expect(tap.payload, isNull);
        expect(seen, hasLength(1));
        expect(pulled, isEmpty);
        expect(shown, isEmpty);
        expect(errors, hasLength(2));
        expect(errors.first, isA<FormatException>());
      },
    );

    test(
      'a failing pull is reported and the tap still opens the screen',
      () async {
        pullFails = Exception('boom');
        final r = await routing.handle(_expense, PushSource.tap);
        expect(r.pulled, isFalse);
        expect(errors.single, isA<Exception>());
        expect(shown, hasLength(1));
      },
    );

    test('open shows the screens of an in-app note', () {
      routing.open(PushPayload.parse(_expense.data)!);
      expect(shown, [
        ['/groups/g1', '/groups/g1/expenses/e1'],
      ]);
    });
  });

  group('start', () {
    test('routes the three platform streams and the launch message', () async {
      service.launchMessage = const PushMessage({'group_id': 'launch'});
      await routing.start();
      await routing.start();
      expect(pulled, ['launch']);
      expect(shown.single, ['/groups/launch']);

      service.emitOpened(
        const PushMessage({'group_id': 'tapped', 'expense_id': 'e9'}),
      );
      await pumpEventQueue();
      expect(shown.last, ['/groups/tapped', '/groups/tapped/expenses/e9']);

      final seen = <PushAnnouncement>[];
      routing.announcements.listen(seen.add);
      service.emitForeground(_expense);
      await pumpEventQueue();
      expect(seen.single, isA<PushIncoming>());

      service.emitBackground(const PushMessage({'group_id': 'bg'}));
      await pumpEventQueue();
      expect(pulled, ['launch', 'tapped', 'g1', 'bg']);
      expect(shown, hasLength(2));
    });
  });
}
