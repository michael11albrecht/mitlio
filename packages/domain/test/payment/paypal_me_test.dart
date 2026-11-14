import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

const _alnum = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

extension PayPalAny on Any {
  Generator<String> get validHandle => simple(
    generate: (random, size) {
      final len = random.nextIntInRange(1, 21);
      return String.fromCharCodes([
        for (var i = 0; i < len; i++)
          _alnum.codeUnitAt(random.nextIntInRange(0, _alnum.length)),
      ]);
    },
    shrink: (_) => const [],
  );

  /// Positive cents. No shrinking: glados shrinks ints by 1, which would take
  /// ~1e9 steps on a failing property (and time out mutation runs).
  Generator<int> get positiveCents => simple(
    generate: (random, size) => random.nextIntInRange(1, 1000000000),
    shrink: (_) => const [],
  );
}

Result<Uri, PayPalError> _build(String handle, int cents, Currency c) =>
    buildPayPalMeLink(handle: handle, amount: Money(cents, c));

void _ok(String handle, int cents, Currency c, String url) {
  expect(_build(handle, cents, c), Ok<Uri, PayPalError>(Uri.parse(url)));
}

void _err(Result<Uri, PayPalError> r, PayPalError e, {String? reason}) {
  expect(r, Err<Uri, PayPalError>(e), reason: reason);
}

void main() {
  group('PayPal.Me examples (domain-rules)', () {
    for (final e in domainRulesRows('paypal')) {
      test('${e['handle']} ${e['cents']} ${e['currency']}', () {
        final r = _build(
          e['handle'] as String,
          e['cents'] as int,
          Currency.tryParse(e['currency'] as String)!,
        );
        if (e.containsKey('url')) {
          expect(r, Ok<Uri, PayPalError>(Uri.parse(e['url'] as String)));
        } else {
          expect(
            (r as Err<Uri, PayPalError>).error.runtimeType.toString(),
            e['error'],
          );
        }
      });
    }
  });

  group('PayPal.Me edge cases', () {
    test('20 chars ok, 21 chars invalid', () {
      final h20 = 'a' * 20;
      _ok(h20, 100, Currency.eur, 'https://paypal.me/$h20/1.00EUR');
      _err(_build('a' * 21, 100, Currency.eur), const InvalidHandle());
    });
    test('unicode and punctuation invalid', () {
      for (final h in [
        'mäx',
        'max_muster',
        'max-muster',
        'max.muster',
        '日本',
        'a/b',
      ]) {
        _err(_build(h, 100, Currency.eur), const InvalidHandle(), reason: h);
      }
    });
    test('paypal.me/ without scheme, case-insensitive prefixes', () {
      const url = 'https://paypal.me/Max/1.00EUR';
      _ok('paypal.me/Max', 100, Currency.eur, url);
      _ok('PayPal.Me/Max', 100, Currency.eur, url);
      _ok('HTTP://WWW.PAYPAL.ME/Max', 100, Currency.eur, url);
      _ok('http://paypal.me/Max', 100, Currency.eur, url);
      _ok('www.paypal.me/Max', 100, Currency.eur, url);
      _ok('@paypal.me/Max', 100, Currency.eur, url);
    });
    test('only one trailing slash is stripped', () {
      _err(_build('max//', 100, Currency.eur), const InvalidHandle());
      _ok('max/', 100, Currency.eur, 'https://paypal.me/max/1.00EUR');
    });
    test('handle that is only a prefix is invalid', () {
      for (final h in ['@', 'https://', 'paypal.me/', '/', '   ']) {
        _err(_build(h, 100, Currency.eur), const InvalidHandle(), reason: h);
      }
    });
    test('KWD uses 3 decimals', () {
      _ok('max', 1234, Currency.kwd, 'https://paypal.me/max/1.234KWD');
      _ok('max', 5, Currency.kwd, 'https://paypal.me/max/0.005KWD');
      _ok('max', 1000, Currency.kwd, 'https://paypal.me/max/1.000KWD');
    });
    test('amount formatting', () {
      _ok('max', 1, Currency.eur, 'https://paypal.me/max/0.01EUR');
      _ok('max', 100, Currency.eur, 'https://paypal.me/max/1.00EUR');
      _ok('max', 1, Currency.jpy, 'https://paypal.me/max/1JPY');
      _ok('max', 1050, Currency.usd, 'https://paypal.me/max/10.50USD');
    });
    test('negative amount', () {
      _err(_build('max', -1, Currency.eur), const NonPositiveAmount());
      _err(_build('max', -1000, Currency.jpy), const NonPositiveAmount());
    });
    test('invalid handle wins over bad amount', () {
      _err(_build('', 0, Currency.eur), const InvalidHandle());
    });
    test('error value semantics', () {
      expect(const InvalidHandle(), const InvalidHandle());
      expect(
        const InvalidHandle().hashCode,
        const InvalidHandle().hashCode,
      );
      expect(const NonPositiveAmount(), const NonPositiveAmount());
      expect(
        const NonPositiveAmount().hashCode,
        const NonPositiveAmount().hashCode,
      );
      expect(const InvalidHandle() == const NonPositiveAmount(), isFalse);
      expect(const NonPositiveAmount() == const InvalidHandle(), isFalse);
      expect(const InvalidHandle().toString(), 'InvalidHandle()');
      expect(const NonPositiveAmount().toString(), 'NonPositiveAmount()');
    });
  });

  group('PayPal.Me properties', () {
    Glados2(any.validHandle, any.positiveCents).test(
      'valid handle + positive cents gives parseable URL that round-trips',
      (handle, cents) {
        for (final c in [Currency.eur, Currency.jpy, Currency.kwd]) {
          final r = _build(handle, cents, c);
          expect(r, isA<Ok<Uri, PayPalError>>());
          final uri = (r as Ok<Uri, PayPalError>).value;
          expect(Uri.parse(uri.toString()), uri);
          expect(uri.scheme, 'https');
          expect(uri.host, 'paypal.me');
          expect(uri.pathSegments.length, 2);
          expect(uri.pathSegments[0], handle);
          final seg = uri.pathSegments[1];
          expect(seg.endsWith(c.code), isTrue);
          final num = seg.substring(0, seg.length - c.code.length);
          final parts = num.split('.');
          final decimals = parts.length == 2 ? parts[1] : '';
          expect(decimals.length, c.minorUnits);
          expect(int.parse(parts[0] + decimals), cents);
        }
      },
    );
  });
}
