import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/crash/scrubber.dart';
import 'package:sentry/sentry.dart';

const _ibans = [
  'DE89370400440532013000',
  'DE89 3704 0044 0532 0130 00',
  'de89 3704 0044 0532 0130 00',
  'GB29NWBK60161331926819',
  'FR1420041010050500013M02606',
  'CH9300762011623852957',
];

void main() {
  group('scrubString', () {
    test('redacts IBANs in every common notation', () {
      for (final iban in _ibans) {
        expect(scrubString('pay to $iban now'), 'pay to [iban] now');
      }
    });

    test('redacts emails and phone numbers', () {
      expect(scrubString('mail anna@example.com!'), 'mail [email]!');
      expect(scrubString('call +49 170 1234567'), 'call [phone]');
      expect(scrubString('call 0170/1234567.'), 'call [phone].');
    });

    test('leaves harmless text alone', () {
      expect(scrubString('Bad state: no element'), 'Bad state: no element');
      expect(scrubString('groups/:id'), 'groups/:id');
    });

    test('property: random text with an embedded IBAN never keeps it', () {
      final rnd = Random(7);
      const alphabet = 'abcdefghij klmnopqrstuvwxyzXYZ.,:;-_/()0123456789\n';
      String noise() => String.fromCharCodes(
        List.generate(
          rnd.nextInt(30),
          (_) => alphabet.codeUnitAt(rnd.nextInt(alphabet.length)),
        ),
      );
      for (var i = 0; i < 500; i++) {
        final iban = _ibans[rnd.nextInt(_ibans.length)];
        final out = scrubString('${noise()} $iban ${noise()}');
        final bare = iban.replaceAll(' ', '').toUpperCase();
        expect(out.replaceAll(' ', '').toUpperCase(), isNot(contains(bare)));
        expect(out, isNot(contains(iban)));
      }
    });

    test('property: random IBAN-shaped strings never survive', () {
      final rnd = Random(11);
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      for (var i = 0; i < 500; i++) {
        final body = String.fromCharCodes(
          List.generate(
            11 + rnd.nextInt(20),
            (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
          ),
        );
        final iban = 'DE${10 + rnd.nextInt(90)}$body';
        expect(scrubString('x $iban y'), isNot(contains(body)));
      }
    });
  });

  group('scrubEventJson', () {
    test('drops user, request, server name and extra', () {
      final out = scrubEventJson({
        'event_id': 'ab12cd34ab12cd34ab12cd34ab12cd34',
        'user': {'id': '1', 'email': 'a@b.de'},
        'request': {'url': 'https://x'},
        'server_name': 'Annas-iPhone',
        'extra': {'note': 'Pizza bei Anna'},
      });
      expect(out.keys, ['event_id']);
      expect(out['event_id'], 'ab12cd34ab12cd34ab12cd34ab12cd34');
    });

    test('redacts exception messages but keeps type and stack', () {
      final out = scrubEventJson({
        'exception': {
          'values': [
            {
              'type': 'StateError',
              'value': 'Member Anna Schmidt DE89370400440532013000',
              'stacktrace': {
                'frames': [
                  {
                    'function': 'main',
                    'vars': {'name': 'Anna'},
                  },
                ],
              },
            },
          ],
        },
        'message': {
          'formatted': 'Anna owes 5',
          'message': 'x',
          'params': ['Anna'],
        },
      });
      final ex = ((out['exception'] as Map)['values'] as List).single as Map;
      expect(ex['type'], 'StateError');
      expect(ex['value'], redacted);
      final frames = (ex['stacktrace'] as Map)['frames'] as List;
      expect(frames.single, {'function': 'main'});
      expect(out['message'], {'formatted': redacted});
    });

    test('keeps only navigation and command breadcrumbs, names only', () {
      final out = scrubEventJson({
        'breadcrumbs': [
          {
            'category': 'navigation',
            'message': 'groups/:id',
            'data': {'a': 1},
          },
          {'category': 'ui.click', 'message': 'Pizza bei Anna'},
          {'category': 'navigation', 'message': 'Anna Schmidt'},
          {'category': 'command', 'message': 'addExpense'},
          {'category': 'http', 'message': 'GET https://x'},
        ],
      });
      expect(out['breadcrumbs'], [
        {'category': 'navigation', 'message': 'groups/:id'},
        {'category': 'navigation', 'message': redacted},
        {'category': 'command', 'message': 'addExpense'},
      ]);
    });

    test('keeps only safe contexts and scrubs strings in tags', () {
      final out = scrubEventJson({
        'contexts': {
          'os': {'name': 'Android', 'version': '14'},
          'device': {'name': 'Annas Phone', 'model': 'Pixel'},
          'custom': {'note': 'secret'},
        },
        'tags': {'k': 'a@b.de'},
      });
      expect(out['contexts'], {
        'os': {'name': 'Android', 'version': '14'},
      });
      expect(out['tags'], {'k': '[email]'});
    });

    test('removes an IBAN hidden anywhere in the remaining data', () {
      final out = scrubEventJson({
        'tags': {'a': 'IBAN DE89 3704 0044 0532 0130 00'},
        'contexts': {
          'app': {'app_name': 'DE89370400440532013000'},
        },
        'release': 'GB29NWBK60161331926819',
      });
      expect(out.toString(), isNot(contains('3704')));
      expect(out.toString(), isNot(contains('NWBK')));
    });
  });

  group('sentry hooks', () {
    test('scrubEvent returns a scrubbed event', () {
      final event = SentryEvent(
        message: SentryMessage('Anna anna@example.com'),
        user: SentryUser(id: '1', email: 'a@b.de'),
        breadcrumbs: [Breadcrumb(message: 'Pizza', category: 'ui.click')],
      );
      final out = scrubEvent(event, Hint());
      expect(out, isNotNull);
      expect(out!.user, isNull);
      expect(out.breadcrumbs, isNull);
      expect(out.message?.formatted, redacted);
      expect(out.eventId, event.eventId);
    });

    test('scrubBreadcrumb drops free-text breadcrumbs', () {
      expect(
        scrubBreadcrumb(
          Breadcrumb(message: 'tap Anna', category: 'ui.click'),
          Hint(),
        ),
        isNull,
      );
      final kept = scrubBreadcrumb(
        Breadcrumb(
          message: 'groups/:id',
          category: 'navigation',
          data: {'a': 1},
        ),
        Hint(),
      );
      expect(kept?.message, 'groups/:id');
      expect(kept?.data, isNull);
    });
  });
}
