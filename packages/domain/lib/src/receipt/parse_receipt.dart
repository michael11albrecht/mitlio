import 'package:mitlio_domain/src/money/currency.dart';
import 'package:mitlio_domain/src/receipt/receipt_draft.dart';

const _maxLines = 400;
const _maxLineLength = 300;
const _maxIntegerDigits = 9;

/// Parses OCR [lines] of a receipt into a [ReceiptDraft]. Pure, deterministic,
/// never throws. See ADR-26. Fields below [receiptMinConfidence] stay empty.
///
/// Lines are expected top to bottom. When every line has a box, lines on the
/// same visual row (label left, amount right) are joined first.
ReceiptDraft parseReceipt(List<ReceiptLine> lines) {
  final rows = _buildRows(lines);
  if (rows.isEmpty) return const ReceiptDraft();
  final merchant = _findMerchant(rows);
  final category = merchant.category ?? _categoryFromText(rows);
  return ReceiptDraft(
    totalCents: _findTotal(rows),
    merchant: merchant.field,
    date: _findDate(rows),
    currency: _findCurrency(rows),
    category: category ?? const ReceiptField.empty(),
  );
}

// ---------------------------------------------------------------- rows

final class _Row {
  _Row(this.text, this.height);

  final String text;
  final double? height;
  late final String lower = text.toLowerCase();
  late final List<int> amounts = _amountsOf(text);
}

List<_Row> _buildRows(List<ReceiptLine> input) {
  final lines = <ReceiptLine>[];
  for (final l in input.take(_maxLines)) {
    final t = l.text.length > _maxLineLength
        ? l.text.substring(0, _maxLineLength)
        : l.text;
    final trimmed = t.trim();
    if (trimmed.isNotEmpty) lines.add(ReceiptLine(trimmed, box: l.box));
  }
  if (lines.isEmpty) return const [];
  if (lines.any((l) => l.box == null)) {
    return [for (final l in lines) _Row(l.text, l.box?.height)];
  }
  final sorted = [...lines]
    ..sort((a, b) {
      final byTop = a.box!.top.compareTo(b.box!.top);
      return byTop != 0 ? byTop : a.box!.left.compareTo(b.box!.left);
    });
  final groups = <List<ReceiptLine>>[];
  for (final l in sorted) {
    final anchor = groups.isEmpty ? null : groups.last.first.box!;
    if (anchor != null &&
        l.box!.centerY >= anchor.top &&
        l.box!.centerY <= anchor.bottom) {
      groups.last.add(l);
    } else {
      groups.add([l]);
    }
  }
  return [
    for (final g in groups)
      _Row(
        g.map((l) => l.text).join(' '),
        g.map((l) => l.box!.height).reduce((a, b) => a > b ? a : b),
      ),
  ];
}

// ------------------------------------------------------------- amounts

final _amountRe = RegExp(
  r"(?<![\d.,'])(\d{1,3}(?:[.,'  ]\d{3})+|\d+)([.,])(\d{2})(?!\d|[.,]\d)",
);
final _notAmountAfter = RegExp(
  r'^\s*(%|-|l\b|ltr\b|liter\b|kg\b|km\b)',
  caseSensitive: false,
);
final _nonDigit = RegExp(r'\D');
final _digit = RegExp(r'\d');

/// Positive amounts in cents found in [text], left to right.
List<int> _amountsOf(String text) {
  final out = <int>[];
  for (final m in _amountRe.allMatches(text)) {
    if (m.start > 0 && text[m.start - 1] == '-') continue;
    if (_notAmountAfter.hasMatch(text.substring(m.end))) continue;
    final whole = m.group(1)!;
    final thousandsSeps = whole.replaceAll(_digit, '');
    if (thousandsSeps.contains(m.group(2)!)) continue;
    if (thousandsSeps.split('').toSet().length > 1) continue;
    final digits = whole.replaceAll(_nonDigit, '');
    if (digits.length > _maxIntegerDigits) continue;
    final cents = int.parse(digits) * 100 + int.parse(m.group(3)!);
    if (cents > 0) out.add(cents);
  }
  return out;
}

// --------------------------------------------------------------- total

final _strongKw = RegExp(
  r'\b(summe|gesamt\w*|zu zahlen|zahlbetrag|endbetrag|total|totale|'
  r'grand total|amount due|balance due|to pay)\b',
);
final _cardKw = RegExp(
  r'\b(ec|ec-karte|ec-cash|girocard|karte|kartenzahlung|visa|mastercard|'
  r'maestro|card)\b',
);
final _cashKw = RegExp(r'\b(bar|cash)\b');
final _excludeKw = RegExp(
  r'zwischen|teilsumme|subtotal|sub total|netto|\bnet\b|mwst|\bust\b|steuer|'
  r'\btax\b|\bvat\b|r(ü|ue)ckgeld|\bchange\b|gegeben|given|tendered|'
  'ersparnis|rabatt|discount|saving|bonus|punkte|points',
);
final _changeKw = RegExp(r'r(ü|ue)ckgeld|\bchange\b');
final _currencyToken = RegExp(r'[€$£]|\b[A-Z]{3}\b');
final _latin = RegExp('[A-Za-z]');

bool _isAmountOnly(_Row r) =>
    r.amounts.isNotEmpty &&
    !_latin.hasMatch(
      r.text.replaceAll(_amountRe, '').replaceAll(_currencyToken, ''),
    );

/// Amount belonging to the keyword in row [i]: the rightmost one in the row,
/// else the first one of an amount-only row below.
int? _amountFor(List<_Row> rows, int i) {
  if (rows[i].amounts.isNotEmpty) return rows[i].amounts.last;
  if (i + 1 < rows.length && _isAmountOnly(rows[i + 1])) {
    return rows[i + 1].amounts.first;
  }
  return null;
}

int _max(Iterable<int> xs) => xs.reduce((a, b) => a > b ? a : b);

ReceiptField<int> _findTotal(List<_Row> rows) {
  final hasChange = rows.any((r) => _changeKw.hasMatch(r.lower));
  final strong = <int>[];
  final weak = <int>[];
  int? firstKeyword;
  for (var i = 0; i < rows.length; i++) {
    final l = rows[i].lower;
    if (_excludeKw.hasMatch(l)) continue;
    final isStrong = _strongKw.hasMatch(l);
    final isWeak = _cardKw.hasMatch(l) || (!hasChange && _cashKw.hasMatch(l));
    if (!isStrong && !isWeak) continue;
    firstKeyword ??= i;
    final a = _amountFor(rows, i);
    if (a == null) continue;
    (isStrong ? strong : weak).add(a);
  }

  // Line items: single-amount rows above the first keyword row.
  var itemSum = 0;
  var maxItem = 0;
  for (var i = 0; i < (firstKeyword ?? 0); i++) {
    final r = rows[i];
    if (r.amounts.length != 1 || _excludeKw.hasMatch(r.lower)) continue;
    itemSum += r.amounts.first;
    if (r.amounts.first > maxItem) maxItem = r.amounts.first;
  }

  final int total;
  int confidence;
  if (strong.isNotEmpty) {
    total = _max(strong);
    confidence = 85;
    if (strong.toSet().length > 1) confidence -= 25;
    if (weak.contains(total)) confidence += 10;
    if (itemSum == total) confidence += 5;
  } else if (weak.isNotEmpty && weak.toSet().length == 1) {
    total = weak.first;
    confidence = weak.length > 1 ? 70 : 60;
  } else {
    return const ReceiptField.empty();
  }
  if (maxItem > total) confidence -= 25;
  return confidence >= receiptMinConfidence
      ? ReceiptField(total, confidence)
      : const ReceiptField.empty();
}

// ---------------------------------------------------------------- date

final _deDate = RegExp(r'(?<!\d)(\d{1,2})\.(\d{1,2})\.(\d{4}|\d{2})(?!\d)');
final _isoDate = RegExp(r'(?<!\d)(\d{4})-(\d{2})-(\d{2})(?!\d)');
final _dateKw = RegExp('datum|date|zeit|time');

DateTime? _validDate(int y, int m, int d) {
  if (y < 2000 || y > 2099) return null;
  final dt = DateTime.utc(y, m, d);
  return dt.year == y && dt.month == m && dt.day == d ? dt : null;
}

ReceiptField<DateTime> _findDate(List<_Row> rows) {
  final found = <DateTime>[];
  DateTime? keyworded;
  for (final r in rows) {
    final inRow = <(int, DateTime)>[];
    for (final m in _deDate.allMatches(r.text)) {
      final year = m.group(3)!;
      final dt = _validDate(
        year.length == 2 ? 2000 + int.parse(year) : int.parse(year),
        int.parse(m.group(2)!),
        int.parse(m.group(1)!),
      );
      if (dt != null) inRow.add((m.start, dt));
    }
    for (final m in _isoDate.allMatches(r.text)) {
      final dt = _validDate(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
      if (dt != null) inRow.add((m.start, dt));
    }
    inRow.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, dt) in inRow) {
      found.add(dt);
      if (_dateKw.hasMatch(r.lower)) keyworded ??= dt;
    }
  }
  if (found.isEmpty) return const ReceiptField.empty();
  if (keyworded != null) return ReceiptField(keyworded, 90);
  return ReceiptField(found.first, found.toSet().length == 1 ? 90 : 75);
}

// ------------------------------------------------------------ currency

final _currencyRes = <Currency, RegExp>{
  for (final c in Currency.all) c: RegExp('(?<![A-Za-z])${c.code}(?![A-Za-z])'),
};

final _dollarAmount = RegExp(r'\$[ \t]*\d|\d[ \t]*\$');

ReceiptField<Currency> _findCurrency(List<_Row> rows) {
  final text = rows.map((r) => r.text).join('\n');
  final counts = <Currency, int>{};
  void add(Currency c, int n) {
    if (n > 0) counts[c] = (counts[c] ?? 0) + n;
  }

  for (final e in _currencyRes.entries) {
    add(e.key, e.value.allMatches(text).length);
  }
  add(Currency.eur, '€'.allMatches(text).length);
  add(Currency.gbp, '£'.allMatches(text).length);
  if (counts.isEmpty) {
    // A bare dollar sign could be USD, CAD or AUD: weak, but above the gate.
    return _dollarAmount.hasMatch(text)
        ? const ReceiptField(Currency.usd, 55)
        : const ReceiptField.empty();
  }
  final best = _max(counts.values);
  final top = counts.entries.where((e) => e.value == best).toList();
  return top.length == 1
      ? ReceiptField(top.single.key, 90)
      : const ReceiptField.empty();
}

// ------------------------------------------------------------ merchant

final class _Chain {
  _Chain(String pattern, this.name, this.category) : re = RegExp(pattern);

  final RegExp re;
  final String name;
  final ReceiptCategory category;
}

final _chains = <_Chain>[
  _Chain(r'\brewe\b', 'REWE', ReceiptCategory.groceries),
  _Chain(r'\bedeka\b', 'EDEKA', ReceiptCategory.groceries),
  _Chain(r'\baldi\b', 'ALDI', ReceiptCategory.groceries),
  _Chain(r'\blidl\b', 'Lidl', ReceiptCategory.groceries),
  _Chain(r'\bpenny\b', 'Penny', ReceiptCategory.groceries),
  _Chain(r'\bnetto\b', 'Netto', ReceiptCategory.groceries),
  _Chain(r'\bkaufland\b', 'Kaufland', ReceiptCategory.groceries),
  _Chain(r'\btegut\b', 'tegut', ReceiptCategory.groceries),
  _Chain(r"\bdenn'?s\b", "denn's Biomarkt", ReceiptCategory.groceries),
  _Chain(r'\bdm\b|\bdm-drogerie', 'dm', ReceiptCategory.drugstore),
  _Chain(r'\brossmann\b', 'Rossmann', ReceiptCategory.drugstore),
  _Chain(r'\bshell\b', 'Shell', ReceiptCategory.fuel),
  _Chain(r'\baral\b', 'Aral', ReceiptCategory.fuel),
  _Chain(r'\besso\b', 'Esso', ReceiptCategory.fuel),
  _Chain(r'\bjet\b', 'JET', ReceiptCategory.fuel),
  _Chain(r'\bomv\b', 'OMV', ReceiptCategory.fuel),
  _Chain(r'\bagip\b', 'Agip', ReceiptCategory.fuel),
  _Chain(r'\bhem\b', 'HEM', ReceiptCategory.fuel),
  _Chain('total ?energies', 'TotalEnergies', ReceiptCategory.fuel),
  _Chain("mc ?donald'?s", "McDonald's", ReceiptCategory.restaurant),
  _Chain('burger king', 'Burger King', ReceiptCategory.restaurant),
  _Chain(r'\bstarbucks\b', 'Starbucks', ReceiptCategory.restaurant),
];

final _noiseKw = RegExp(
  r'kassenbon|beleg|rechnung|quittung|receipt|invoice|\btel\b|telefon|www\.|'
  r'http|@|ust-?id|steuernr|str\b|stra(ß|ss)e|platz\b|\b\d{5}\b|willkommen|'
  'welcome|vielen dank|thank',
);
final _letter = RegExp(r'\p{L}', unicode: true);
final _whitespace = RegExp(r'\s+');
final _edgeJunk = RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}.)]+$', unicode: true);

const _headRows = 10;
const _candidateRows = 5;
const _maxMerchantLength = 40;

final class _Merchant {
  const _Merchant(this.field, this.category);
  final ReceiptField<String> field;
  final ReceiptField<ReceiptCategory>? category;
}

_Merchant _findMerchant(List<_Row> rows) {
  for (final r in rows.take(_headRows)) {
    if (r.amounts.isNotEmpty) continue;
    for (final c in _chains) {
      if (c.re.hasMatch(r.lower)) {
        return _Merchant(
          ReceiptField(c.name, 95),
          ReceiptField(c.category, 90),
        );
      }
    }
  }
  // Unknown shop: the tallest plausible row near the top (when boxes exist),
  // else the first one.
  _Row? best;
  for (final r in rows.take(_candidateRows)) {
    if (!_plausibleMerchant(r)) continue;
    final h = r.height;
    final bh = best?.height;
    if (best == null) {
      best = r;
    } else if (h != null && bh != null && h > bh) {
      best = r;
    }
  }
  if (best == null) return const _Merchant(ReceiptField.empty(), null);
  final name = best.text.replaceAll(_whitespace, ' ').replaceAll(_edgeJunk, '');
  if (name.isEmpty) return const _Merchant(ReceiptField.empty(), null);
  return _Merchant(ReceiptField(name, best.height == null ? 60 : 70), null);
}

bool _plausibleMerchant(_Row r) {
  final letters = _letter.allMatches(r.text).length;
  return letters >= 3 &&
      r.text.length <= _maxMerchantLength &&
      r.amounts.isEmpty &&
      _digit.allMatches(r.text).length * 2 <= letters &&
      !_noiseKw.hasMatch(r.lower) &&
      !_strongKw.hasMatch(r.lower) &&
      !_cardKw.hasMatch(r.lower) &&
      !_deDate.hasMatch(r.text) &&
      !_isoDate.hasMatch(r.text);
}

// ------------------------------------------------------------ category

final _categoryKw = <(RegExp, ReceiptCategory)>[
  (RegExp('apotheke|pharmacy|pharmacie'), ReceiptCategory.pharmacy),
  (
    RegExp(
      'restaurant|gasthaus|gasthof|ristorante|pizzeria|trattoria|bistro|'
      r'imbiss|caf(é|e\b)|bewirtung',
    ),
    ReceiptCategory.restaurant,
  ),
  (
    RegExp('tankstelle|diesel|super e10|super e5|benzin|zapfs(ä|ae)ule'),
    ReceiptCategory.fuel,
  ),
];

ReceiptField<ReceiptCategory>? _categoryFromText(List<_Row> rows) {
  final text = rows.map((r) => r.lower).join('\n');
  for (final (re, cat) in _categoryKw) {
    if (re.hasMatch(text)) return ReceiptField(cat, 70);
  }
  return null;
}
