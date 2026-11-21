import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

const _alnum = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

extension _Gens on Any {
  Generator<String> get handle => simple(
    generate: (random, size) {
      final len = random.nextIntInRange(1, 21);
      return String.fromCharCodes([
        for (var i = 0; i < len; i++)
          _alnum.codeUnitAt(random.nextIntInRange(0, _alnum.length)),
      ]);
    },
    shrink: (_) => const [],
  );
  Generator<int> get cents => simple(
    generate: (random, size) => random.nextIntInRange(1, 1000000000),
    shrink: (_) => const [],
  );
}

PaypalMeHandle _h(String input) =>
    (PaypalMeHandle.parse(input) as Ok<PaypalMeHandle, PayPalError>).value;

void main() {
  group('PaypalMeHandle examples (examples:paypal_handle)', () {
    for (final e in domainRulesRows('paypal_handle')) {
      test(e['input'] as String, () {
        final r = PaypalMeHandle.parse(e['input'] as String);
        if (e.containsKey('error')) {
          expect(
            (r as Err<PaypalMeHandle, PayPalError>).error.runtimeType
                .toString(),
            e['error'],
          );
        } else {
          final h = (r as Ok<PaypalMeHandle, PayPalError>).value;
          expect(h.value, e['handle']);
          expect(
            h.link(),
            Ok<Uri, PayPalError>(Uri.parse(e['link'] as String)),
          );
        }
      });
    }
  });

  group('PaypalMeHandle edge cases', () {
    test('every accepted form gives the same handle', () {
      for (final f in [
        'Max',
        '@Max',
        'paypal.me/Max',
        'PAYPAL.ME/Max',
        'https://paypal.me/Max',
        'http://www.paypal.me/Max/',
        'https://paypal.me/Max?x=1',
        ' Max ',
      ]) {
        expect(_h(f).value, 'Max', reason: f);
      }
    });
    test('20 chars ok, 21 invalid', () {
      expect(_h('a' * 20).value, 'a' * 20);
      expect(
        PaypalMeHandle.parse('a' * 21),
        const Err<PaypalMeHandle, PayPalError>(InvalidHandle()),
      );
    });
    test('invalid characters', () {
      for (final s in ['a b', 'a_b', 'a-b', 'a.b', 'mäx', 'a/b', '@@a']) {
        expect(
          PaypalMeHandle.parse(s),
          isA<Err<PaypalMeHandle, PayPalError>>(),
        );
      }
    });
    test('link with amount', () {
      expect(
        _h('max').link(amount: Money(1234, Currency.eur)),
        Ok<Uri, PayPalError>(Uri.parse('https://paypal.me/max/12.34EUR')),
      );
    });
    test('link rejects zero and negative amounts', () {
      for (final c in [0, -1]) {
        expect(
          _h('max').link(amount: Money(c, Currency.eur)),
          const Err<Uri, PayPalError>(NonPositiveAmount()),
        );
      }
    });
    test('format, equality, toString', () {
      expect(_h('Max').format(), 'paypal.me/Max');
      expect(_h('Max'), _h('@Max'));
      expect(_h('Max').hashCode, _h('@Max').hashCode);
      expect(_h('Max') == _h('max'), isFalse);
      expect(_h('Max').toString(), 'PaypalMeHandle(Max)');
    });
    test('buildPayPalMeLink strips share-link parameters too', () {
      expect(
        buildPayPalMeLink(
          handle: 'paypal.me/max?locale.x=de_DE',
          amount: Money(100, Currency.eur),
        ),
        Ok<Uri, PayPalError>(Uri.parse('https://paypal.me/max/1.00EUR')),
      );
    });
  });

  group('PaypalMeHandle properties', () {
    Glados(any.handle).test('parse(format()) is the identity', (s) {
      final h = _h(s);
      expect(h.value, s);
      expect(_h(h.format()), h);
      expect(_h('@$s'), h);
      expect(_h('https://www.paypal.me/$s/'), h);
    });
    Glados2(any.handle, any.cents).test('link(amount) extends link()', (s, c) {
      final base = (_h(s).link() as Ok<Uri, PayPalError>).value;
      final withAmount = (_h(
        s,
      ).link(amount: Money(c, Currency.eur)) as Ok<Uri, PayPalError>).value;
      expect(withAmount.pathSegments.first, base.pathSegments.first);
      expect(base.pathSegments, [s]);
      expect(withAmount.pathSegments.length, 2);
    });
  });
}
