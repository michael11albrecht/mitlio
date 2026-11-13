import 'dart:convert';

import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

const _iban = 'DE89370400440532013000';

Money _eur(int cents) => Money(cents, Currency.eur);

Result<String, EpcError> _build({
  String name = 'Max Mustermann',
  String iban = _iban,
  String? bic,
  Money? amount,
  String remittance = '',
}) => buildEpcQrPayload(
  name: name,
  iban: iban,
  bic: bic,
  amount: amount ?? _eur(1234),
  remittance: remittance,
);

Result<String, EpcError> _err(EpcError e) => Err(e);

void main() {
  group('buildEpcQrPayload examples', () {
    test('row 1: spaced IBAN, remittance, no BIC', () {
      expect(
        buildEpcQrPayload(
          name: 'Max Mustermann',
          iban: 'DE89 3704 0044 0532 0130 00',
          amount: _eur(1234),
          remittance: 'mitlio: Urlaub',
        ),
        const Ok<String, EpcError>(
          'BCD\n002\n1\nSCT\n\nMax Mustermann\nDE89370400440532013000\n'
          'EUR12.34\n\n\nmitlio: Urlaub',
        ),
      );
    });

    test('row 2: lower-case BIC, 5 cents, no remittance', () {
      expect(
        buildEpcQrPayload(
          name: 'Max Mustermann',
          iban: _iban,
          bic: 'cobadeffxxx',
          amount: _eur(5),
        ),
        const Ok<String, EpcError>(
          'BCD\n002\n1\nSCT\nCOBADEFFXXX\nMax Mustermann\n'
          'DE89370400440532013000\nEUR0.05\n\n\n',
        ),
      );
    });
  });

  group('name', () {
    test('trimmed', () {
      final r = _build(name: '  Max  ');
      expect((r as Ok<String, EpcError>).value.split('\n')[5], 'Max');
    });
    test('empty and blank are InvalidName', () {
      expect(_build(name: ''), _err(const InvalidName()));
      expect(_build(name: '   '), _err(const InvalidName()));
    });
    test('70 ok, 71 InvalidName', () {
      expect(_build(name: 'a' * 70), isA<Ok<String, EpcError>>());
      expect(_build(name: 'a' * 71), _err(const InvalidName()));
    });
    test('length counts code points, not UTF-16 units', () {
      expect(_build(name: '\u{1F600}' * 70), isA<Ok<String, EpcError>>());
      expect(_build(name: '\u{1F600}' * 71), _err(const InvalidName()));
    });
    test('inner line break is InvalidName', () {
      expect(_build(name: 'Max\nMuster'), _err(const InvalidName()));
      expect(_build(name: 'Max\rMuster'), _err(const InvalidName()));
    });
  });

  group('iban', () {
    test('bad checksum wraps IbanError', () {
      expect(
        _build(iban: 'DE89370400440532013001'),
        _err(const InvalidIban(InvalidChecksum())),
      );
    });
    test('bad format wraps IbanError', () {
      expect(
        _build(iban: 'DE89'),
        _err(const InvalidIban(InvalidFormat())),
      );
    });
  });

  group('bic', () {
    test('8 chars ok', () {
      final r = _build(bic: 'COBADEFF') as Ok<String, EpcError>;
      expect(r.value.split('\n')[4], 'COBADEFF');
    });
    test('11 chars ok', () {
      final r = _build(bic: 'COBADEFFXXX') as Ok<String, EpcError>;
      expect(r.value.split('\n')[4], 'COBADEFFXXX');
    });
    test('trimmed and upper-cased', () {
      final r = _build(bic: '  cobadeff  ') as Ok<String, EpcError>;
      expect(r.value.split('\n')[4], 'COBADEFF');
    });
    test('empty or blank is omitted', () {
      for (final bic in ['', '   ']) {
        final r = _build(bic: bic) as Ok<String, EpcError>;
        expect(r.value.split('\n')[4], '');
      }
    });
    test('invalid shapes are InvalidBic', () {
      for (final bic in [
        'COBADEF', // 7
        'COBADEFFX', // 9
        'COBADEFFXX', // 10
        'COBADEFFXXXX', // 12
        '1OBADEFF', // digit in institution code
        'COBA1EFF', // digit in institution code
        'COBADE-F', // symbol
        'COBADEFF XXX', // inner space
      ]) {
        expect(_build(bic: bic), _err(const InvalidBic()), reason: bic);
      }
    });
    test('digits allowed in location and branch', () {
      expect(_build(bic: 'COBADEF2'), isA<Ok<String, EpcError>>());
      expect(_build(bic: 'COBADEF2X1Z'), isA<Ok<String, EpcError>>());
    });
  });

  group('amount', () {
    test('1 cent', () {
      final r = _build(amount: _eur(1)) as Ok<String, EpcError>;
      expect(r.value.split('\n')[7], 'EUR0.01');
    });
    test('99999999999 cents', () {
      final r = _build(amount: _eur(99999999999)) as Ok<String, EpcError>;
      expect(r.value.split('\n')[7], 'EUR999999999.99');
    });
    test('whole euros keep two decimals', () {
      final r = _build(amount: _eur(1000)) as Ok<String, EpcError>;
      expect(r.value.split('\n')[7], 'EUR10.00');
    });
    test('zero, negative and above max are AmountOutOfRange', () {
      for (final c in [0, -1, 100000000000]) {
        expect(
          _build(amount: _eur(c)),
          _err(const AmountOutOfRange()),
          reason: '$c',
        );
      }
    });
    test('non-EUR is NotEur (even when out of range)', () {
      expect(
        _build(amount: Money(1234, Currency.usd)),
        _err(const NotEur()),
      );
      expect(
        _build(amount: Money(0, Currency.usd)),
        _err(const NotEur()),
      );
    });
  });

  group('remittance', () {
    test('140 ok, 141 RemittanceTooLong', () {
      expect(_build(remittance: 'a' * 140), isA<Ok<String, EpcError>>());
      expect(
        _build(remittance: 'a' * 141),
        _err(const RemittanceTooLong()),
      );
    });
    test('trimmed before length check', () {
      final r = _build(remittance: '  ${'a' * 140}  ') as Ok<String, EpcError>;
      expect(r.value.split('\n')[10], 'a' * 140);
    });
    test('line breaks become a single space', () {
      final r = _build(remittance: 'a\r\n\nb') as Ok<String, EpcError>;
      expect(r.value.split('\n'), hasLength(11));
      expect(r.value.split('\n')[10], 'a b');
    });
  });

  group('payload size', () {
    final name = 'é' * 70; // 140 bytes; fixed lines add 50 bytes
    test('exactly 331 bytes is Ok', () {
      final r = _build(name: name, remittance: '${'é' * 70}a');
      final payload = (r as Ok<String, EpcError>).value;
      expect(utf8.encode(payload), hasLength(331));
    });
    test('332 bytes is PayloadTooLarge(332)', () {
      expect(
        _build(name: name, remittance: 'é' * 71),
        _err(const PayloadTooLarge(332)),
      );
    });
    test('70 x e-acute name + 140 x e-acute remittance is 470 bytes', () {
      expect(
        _build(name: name, remittance: 'é' * 140),
        _err(const PayloadTooLarge(470)),
      );
    });
    test('ASCII maxima fit (70 + 140 chars)', () {
      expect(
        _build(name: 'a' * 70, remittance: 'a' * 140),
        isA<Ok<String, EpcError>>(),
      );
    });
    test('checked last: field errors win', () {
      expect(
        _build(name: name, remittance: 'é' * 141),
        _err(const RemittanceTooLong()),
      );
    });
  });

  group('validation order', () {
    final bad = (
      name: '',
      iban: 'x',
      bic: 'x',
      amount: Money(0, Currency.usd),
      remittance: 'a' * 141,
    );
    Result<String, EpcError> build({
      String? name,
      String? iban,
      String? bic,
      Money? amount,
      String? remittance,
    }) => buildEpcQrPayload(
      name: name ?? bad.name,
      iban: iban ?? bad.iban,
      bic: bic ?? bad.bic,
      amount: amount ?? bad.amount,
      remittance: remittance ?? bad.remittance,
    );

    test('name, then iban, bic, amount, remittance', () {
      expect(build(), _err(const InvalidName()));
      expect(
        build(name: 'n'),
        _err(const InvalidIban(InvalidFormat())),
      );
      expect(build(name: 'n', iban: _iban), _err(const InvalidBic()));
      expect(build(name: 'n', iban: _iban, bic: ''), _err(const NotEur()));
      expect(
        build(name: 'n', iban: _iban, bic: '', amount: _eur(0)),
        _err(const AmountOutOfRange()),
      );
      expect(
        build(name: 'n', iban: _iban, bic: '', amount: _eur(1)),
        _err(const RemittanceTooLong()),
      );
    });
  });

  group('EpcError', () {
    test('value equality, hashCode and toString', () {
      const errors = <EpcError>[
        InvalidName(),
        InvalidIban(InvalidFormat()),
        InvalidBic(),
        NotEur(),
        AmountOutOfRange(),
        RemittanceTooLong(),
        PayloadTooLarge(331),
      ];
      const copies = <EpcError>[
        InvalidName(),
        InvalidIban(InvalidFormat()),
        InvalidBic(),
        NotEur(),
        AmountOutOfRange(),
        RemittanceTooLong(),
        PayloadTooLarge(331),
      ];
      for (var i = 0; i < errors.length; i++) {
        for (var j = 0; j < errors.length; j++) {
          expect(errors[i] == copies[j], i == j);
        }
        expect(errors[i].hashCode, copies[i].hashCode);
      }
      expect(
        const InvalidIban(InvalidFormat()) ==
            const InvalidIban(InvalidChecksum()),
        isFalse,
      );
      expect(
        errors.map((e) => e.toString()),
        [
          'InvalidName',
          'InvalidIban(InvalidFormat)',
          'InvalidBic',
          'NotEur',
          'AmountOutOfRange',
          'RemittanceTooLong',
          'PayloadTooLarge(331)',
        ],
      );
    });
  });

  group('properties', () {
    Glados2<int, String>(
      any.intInRange(1, 100000000000),
      any.letterOrDigits,
    ).test('valid input yields exactly 11 lines, no trailing newline', (
      cents,
      text,
    ) {
      final r = _build(amount: _eur(cents), remittance: text);
      final payload = (r as Ok<String, EpcError>).value;
      expect(payload.split('\n'), hasLength(11));
      expect(payload.startsWith('BCD\n002\n1\nSCT\n'), isTrue);
      expect(payload.split('\n')[10], text.trim());
    });

    Glados<int>(any.intInRange(1, 100000000000)).test(
      'amount line equals cents / 100 with two decimals',
      (cents) {
        final r = _build(amount: _eur(cents)) as Ok<String, EpcError>;
        final line = r.value.split('\n')[7];
        final expected =
            'EUR${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
        expect(line, expected);
        expect(line, matches(RegExp(r'^EUR[0-9]+\.[0-9]{2}$')));
      },
    );

    Glados<String>(any.letterOrDigits).test(
      'remittance with line breaks still yields 11 lines',
      (text) {
        final t = text.length > 40 ? text.substring(0, 40) : text;
        final r = _build(remittance: '$t\n$t\r\n$t');
        expect((r as Ok<String, EpcError>).value.split('\n'), hasLength(11));
      },
    );
  });
}
