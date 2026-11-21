import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/profile/ui/iban_input.dart';

const _valid = 'DE89370400440532013000';

void main() {
  group('formatIban', () {
    test('groups in fours, upper-case, without separators', () {
      expect(
        formatIban('de89370400440532013000'),
        'DE89 3704 0044 0532 0130 00',
      );
      expect(
        formatIban('de89-3704.0044 0532 0130 00'),
        'DE89 3704 0044 0532 0130 00',
      );
    });

    test('has no trailing space and handles short input', () {
      expect(formatIban(''), '');
      expect(formatIban('DE89'), 'DE89');
      expect(formatIban('DE891'), 'DE89 1');
    });

    test('cuts at the longest IBAN (34 characters)', () {
      expect(cleanIban('A' * 40).length, 34);
    });
  });

  group('checkIban', () {
    test('empty', () => expect(checkIban(' '), IbanCheck.empty));

    test('valid, with or without spaces', () {
      expect(checkIban(_valid), IbanCheck.valid);
      expect(checkIban(formatIban(_valid)), IbanCheck.valid);
      expect(checkIban('gb82 west 1234 5698 7654 32'), IbanCheck.valid);
    });

    test('a plausible start is still typing', () {
      for (final partial in [
        'D',
        'DE',
        'DE8',
        'DE89',
        'DE89 3704',
        _valid.substring(0, 21),
      ]) {
        expect(checkIban(partial), IbanCheck.typing, reason: partial);
      }
    });

    test('a start that cannot be an IBAN is a format error at once', () {
      expect(checkIban('12'), IbanCheck.badFormat);
      expect(checkIban('D3'), IbanCheck.badFormat);
      expect(checkIban('DEAB'), IbanCheck.badFormat);
    });

    test('a complete German IBAN with a typo is a checksum error', () {
      expect(checkIban('DE89370400440532013001'), IbanCheck.badChecksum);
    });

    test('a long non-German IBAN with a typo is a checksum error', () {
      expect(checkIban('GB82WEST12345698765433'), IbanCheck.badChecksum);
    });
  });

  group('IbanInputFormatter', () {
    const formatter = IbanInputFormatter();

    TextEditingValue type(String text, [int? caret]) =>
        formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: caret ?? text.length),
          ),
        );

    test('formats while typing and keeps the caret at the end', () {
      final v = type('de893');
      expect(v.text, 'DE89 3');
      expect(v.selection.baseOffset, 6);
    });

    test('a caret in the middle stays next to its character', () {
      // "DE89 3704" with the caret after the "3": 5 characters before it.
      final v = type('DE893704', 5);
      expect(v.text, 'DE89 3704');
      expect(v.selection.baseOffset, 6);
    });

    test('pasting a formatted IBAN keeps it intact', () {
      final v = type('DE89 3704 0044 0532 0130 00');
      expect(v.text, 'DE89 3704 0044 0532 0130 00');
      expect(v.selection.baseOffset, v.text.length);
    });
  });
}
