import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

const _alnum = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Independent oracle: check digits via BigInt (the implementation uses
/// piecewise int arithmetic).
String _withCheckDigits(String country, String bban) {
  final digits = StringBuffer();
  for (final u in '$bban${country}00'.codeUnits) {
    digits.write(
      u >= 0x41 ? (u - 0x41 + 10).toString() : String.fromCharCode(u),
    );
  }
  final check =
      98 - (BigInt.parse(digits.toString()) % BigInt.from(97)).toInt();
  return '$country${check.toString().padLeft(2, '0')}$bban';
}

extension IbanAny on Any {
  /// A valid IBAN: random country, random BBAN of 11-30 chars, computed
  /// check digits. No shrinking.
  Generator<String> get validIban => simple(
    generate: (random, size) {
      String pick(int n, String chars) => List.generate(
        n,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
      final country = pick(2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      final bban = pick(11 + random.nextInt(20), _alnum);
      return _withCheckDigits(country, bban);
    },
    shrink: (_) => const [],
  );
}

void main() {
  group('normalizeIban examples', () {
    for (final e in domainRulesRows('iban')) {
      test(e['input'] as String, () {
        final r = normalizeIban(e['input'] as String);
        if (e.containsKey('result')) {
          expect(r, equals(Ok<String, IbanError>(e['result'] as String)));
        } else {
          expect(
            (r as Err<String, IbanError>).error.runtimeType.toString(),
            e['error'],
          );
        }
      });
    }
  });

  group('normalizeIban edge cases', () {
    test('removes tabs, newlines and nbsp-free whitespace', () {
      expect(
        normalizeIban(' DE89\t3704\n0044 0532 0130 00 '),
        const Ok<String, IbanError>('DE89370400440532013000'),
      );
    });

    test('empty input is InvalidFormat', () {
      expect(normalizeIban(''), const Err<String, IbanError>(InvalidFormat()));
    });

    test('length boundaries: 14 too short, 15 ok, 34 ok, 35 too long', () {
      final l14 = _withCheckDigits('XX', 'A' * 10);
      final l15 = _withCheckDigits('XX', 'A' * 11);
      final l34 = _withCheckDigits('XX', 'A' * 30);
      final l35 = _withCheckDigits('XX', 'A' * 31);
      expect(
        [l14.length, l15.length, l34.length, l35.length],
        [14, 15, 34, 35],
      );
      expect(normalizeIban(l14), const Err<String, IbanError>(InvalidFormat()));
      expect(normalizeIban(l15), Ok<String, IbanError>(l15));
      expect(normalizeIban(l34), Ok<String, IbanError>(l34));
      expect(normalizeIban(l35), const Err<String, IbanError>(InvalidFormat()));
    });

    test('letters in check digits are InvalidFormat', () {
      expect(
        normalizeIban('DEA9370400440532013000'),
        const Err<String, IbanError>(InvalidFormat()),
      );
      expect(
        normalizeIban('DE8A370400440532013000'),
        const Err<String, IbanError>(InvalidFormat()),
      );
    });

    test('digits in country code are InvalidFormat', () {
      expect(
        normalizeIban('1E89370400440532013000'),
        const Err<String, IbanError>(InvalidFormat()),
      );
    });

    test('non-alphanumeric characters are InvalidFormat', () {
      expect(
        normalizeIban('DE89-3704-0044-0532-0130-00'),
        const Err<String, IbanError>(InvalidFormat()),
      );
    });

    test('format is checked before checksum', () {
      expect(
        normalizeIban('DE00'),
        const Err<String, IbanError>(InvalidFormat()),
      );
    });

    test('errors have value equality and readable names', () {
      expect(const InvalidFormat(), const InvalidFormat());
      expect(const InvalidFormat().hashCode, const InvalidFormat().hashCode);
      expect(const InvalidChecksum(), const InvalidChecksum());
      expect(
        const InvalidChecksum().hashCode,
        const InvalidChecksum().hashCode,
      );
      expect(const InvalidFormat() == const InvalidChecksum(), isFalse);
      expect(const InvalidFormat().toString(), 'InvalidFormat');
      expect(const InvalidChecksum().toString(), 'InvalidChecksum');
    });
  });

  group('normalizeIban properties', () {
    Glados<String>(any.validIban).test('generated valid IBANs are Ok', (iban) {
      expect(normalizeIban(iban), Ok<String, IbanError>(iban));
    });

    Glados<String>(any.validIban).test('idempotent on valid IBANs', (iban) {
      final once = normalizeIban(iban);
      expect(once, isA<Ok<String, IbanError>>());
      final twice = normalizeIban((once as Ok<String, IbanError>).value);
      expect(twice, once);
    });

    Glados2<String, int>(any.validIban, any.positiveIntOrZero).test(
      'spaces and lower case do not matter',
      (iban, seed) {
        final spaced = [
          for (var i = 0; i < iban.length; i++)
            (i % 4 == 0 && i > 0 ? ' ' : '') +
                (seed.isEven ? iban[i].toLowerCase() : iban[i]),
        ].join();
        expect(normalizeIban(spaced), Ok<String, IbanError>(iban));
      },
    );

    Glados2<String, int>(any.validIban, any.positiveIntOrZero).test(
      'changing one digit is InvalidChecksum',
      (iban, seed) {
        // Positions 2..end that are digits (check digits + digit BBAN chars).
        final digitPositions = [
          for (var i = 2; i < iban.length; i++)
            if (iban.codeUnitAt(i) >= 0x30 && iban.codeUnitAt(i) <= 0x39) i,
        ];
        final pos = digitPositions[seed % digitPositions.length];
        final old = iban.codeUnitAt(pos) - 0x30;
        final replacement = (old + 1 + (seed ~/ 7) % 9) % 10;
        expect(replacement, isNot(old));
        final broken =
            iban.substring(0, pos) +
            replacement.toString() +
            iban.substring(pos + 1);
        expect(
          normalizeIban(broken),
          const Err<String, IbanError>(InvalidChecksum()),
        );
      },
    );
  });
}
