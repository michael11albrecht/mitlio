import 'package:flutter/services.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What the IBAN field shows while the user types.
enum IbanCheck {
  /// Nothing typed.
  empty,

  /// Plausible so far, not complete yet: no verdict, no error.
  typing,

  /// Not an IBAN, however it continues.
  badFormat,

  /// Complete, but the check digits do not match (a typo).
  badChecksum,

  /// A valid IBAN.
  valid,
}

const _maxIbanLength = 34;

/// Length of a German IBAN: with a `DE` prefix the verdict is known as soon
/// as that many characters are in, so a typo is flagged while typing.
const _germanIbanLength = 22;

final _notAlnum = RegExp('[^A-Za-z0-9]');
final _leadingFormat = RegExp(r'^([A-Z]{0,2}|[A-Z]{2}[0-9]{1,2})$');

/// [raw] without spaces and in capitals, cut to the longest IBAN.
String cleanIban(String raw) {
  final clean = raw.replaceAll(_notAlnum, '').toUpperCase();
  return clean.length > _maxIbanLength
      ? clean.substring(0, _maxIbanLength)
      : clean;
}

/// [raw] in groups of four ("DE89 3704 0044 …"), as banks print it.
String formatIban(String raw) {
  final clean = cleanIban(raw);
  final out = StringBuffer();
  for (var i = 0; i < clean.length; i++) {
    if (i > 0 && i % 4 == 0) out.write(' ');
    out.write(clean[i]);
  }
  return out.toString();
}

/// The live verdict on [raw]. The checksum is only judged once the IBAN can
/// be complete: always for a valid one, and for `DE` at 22 characters.
IbanCheck checkIban(String raw) {
  final clean = cleanIban(raw);
  if (clean.isEmpty) return IbanCheck.empty;
  if (normalizeIban(clean) is Ok) return IbanCheck.valid;
  if (clean.length < 15 ||
      clean.startsWith('DE') && clean.length < _germanIbanLength) {
    // Short: only the start (two letters, two digits) can be judged.
    final lead = clean.length > 4 ? clean.substring(0, 4) : clean;
    return _leadingFormat.hasMatch(lead)
        ? IbanCheck.typing
        : IbanCheck.badFormat;
  }
  return switch (normalizeIban(clean)) {
    Err(error: InvalidChecksum()) => IbanCheck.badChecksum,
    _ => IbanCheck.badFormat,
  };
}

/// Groups the IBAN in fours while typing and keeps the caret next to the
/// character it was after.
class IbanInputFormatter extends TextInputFormatter {
  const IbanInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final caret = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final before = cleanIban(newValue.text.substring(0, caret)).length;
    final text = formatIban(newValue.text);
    final kept = before.clamp(0, cleanIban(text).length);
    // Characters before the caret plus the spaces that precede them.
    final offset = kept + (kept > 0 ? (kept - 1) ~/ 4 : 0);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset.clamp(0, text.length)),
    );
  }
}
