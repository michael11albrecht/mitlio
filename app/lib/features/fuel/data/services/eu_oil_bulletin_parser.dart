import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Latest national prices of the EU Weekly Oil Bulletin (with taxes).
final class BulletinPrices {
  const BulletinPrices({
    required this.date,
    required this.e5Milli,
    required this.dieselMilli,
  });

  /// Day the prices are in force on (UTC midnight).
  final DateTime date;

  /// Euro-super 95, thousandths of EUR per litre.
  final int e5Milli;

  /// Automotive gas oil, thousandths of EUR per litre.
  final int dieselMilli;
}

/// The file is not what we expect (layout changed, truncated, wrong country).
class BulletinFormatException implements Exception {
  const BulletinFormatException(this.message);

  final String message;

  @override
  String toString() => 'BulletinFormatException: $message';
}

/// Reads the bulletin XLSX (port of `supabase/functions/_shared/oil_bulletin.ts`):
/// one sheet, row 1 headers, `A2` the date as Excel serial, from row 3 on
/// `A` the English country name and EUR per 1000 l (= milli-EUR per litre)
/// in the grade columns. Pure Dart, `ZLibCodec` for the zip entries, no
/// package.
BulletinPrices parseBulletinXlsx(
  Uint8List bytes, {
  String country = 'Germany',
}) {
  if (bytes.length > _maxXlsxBytes) {
    throw const BulletinFormatException('bulletin too large');
  }
  final entries = _readCentralDirectory(bytes);
  final sheetEntry = entries['xl/worksheets/sheet1.xml'];
  final stringsEntry = entries['xl/sharedStrings.xml'];
  if (sheetEntry == null || stringsEntry == null) {
    throw const BulletinFormatException('unexpected bulletin layout');
  }
  final strings = _parseSharedStrings(_readEntry(bytes, stringsEntry));
  final cells = _parseSheet(_readEntry(bytes, sheetEntry), strings);

  String? superCol;
  String? dieselCol;
  for (final MapEntry(key: ref, value: text) in cells.entries) {
    final match = _headerRef.firstMatch(ref);
    if (match == null) continue;
    final col = match.group(1)!;
    if (_superHeader.hasMatch(text)) superCol ??= col;
    if (_dieselHeader.hasMatch(text)) dieselCol ??= col;
  }
  if (superCol == null || dieselCol == null) {
    throw const BulletinFormatException('bulletin columns not found');
  }

  final serial = double.tryParse(cells['A2'] ?? '');
  if (serial == null || serial < 40000 || serial > 80000) {
    throw const BulletinFormatException('bulletin date not found');
  }

  for (final MapEntry(key: ref, value: text) in cells.entries) {
    if (!_countryRef.hasMatch(ref) || text.trim() != country) continue;
    final row = ref.substring(1);
    return BulletinPrices(
      date: excelSerialToDate(serial),
      e5Milli: _toMilli(cells['$superCol$row']),
      dieselMilli: _toMilli(cells['$dieselCol$row']),
    );
  }
  throw const BulletinFormatException('country not in bulletin');
}

/// Excel 1900 date serial to UTC midnight.
DateTime excelSerialToDate(double serial) =>
    DateTime.fromMillisecondsSinceEpoch(
      ((serial - 25569) * Duration.millisecondsPerDay).round(),
      isUtc: true,
    );

const _maxXlsxBytes = 5000000;
const _maxEntryBytes = 10000000;

final _headerRef = RegExp(r'^([A-Z]+)1$');
final _countryRef = RegExp(r'^A\d+$');
final _superHeader = RegExp('Euro-super 95', caseSensitive: false);
final _dieselHeader = RegExp(
  'gas oil automobile|Dieselkraftstoff',
  caseSensitive: false,
);

/// EUR per 1000 l to milli-EUR per litre; implausible values are rejected.
int _toMilli(String? raw) {
  final value = double.tryParse(raw ?? '');
  if (value == null || !value.isFinite || value < 500 || value > 5000) {
    throw const BulletinFormatException('implausible bulletin price');
  }
  return value.round();
}

typedef _ZipEntry = ({int method, int compressedSize, int localOffset});

Map<String, _ZipEntry> _readCentralDirectory(Uint8List bytes) {
  final dv = ByteData.sublistView(bytes);
  var eocd = -1;
  final lowest = (bytes.length - 65557).clamp(0, bytes.length);
  for (var i = bytes.length - 22; i >= lowest; i--) {
    if (dv.getUint32(i, Endian.little) == 0x06054b50) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) throw const BulletinFormatException('not a zip file');
  final count = dv.getUint16(eocd + 10, Endian.little);
  var p = dv.getUint32(eocd + 16, Endian.little);
  final entries = <String, _ZipEntry>{};
  for (var n = 0; n < count; n++) {
    if (p + 46 > bytes.length || dv.getUint32(p, Endian.little) != 0x02014b50) {
      throw const BulletinFormatException('corrupt zip directory');
    }
    final nameLen = dv.getUint16(p + 28, Endian.little);
    final extraLen = dv.getUint16(p + 30, Endian.little);
    final commentLen = dv.getUint16(p + 32, Endian.little);
    if (p + 46 + nameLen > bytes.length) {
      throw const BulletinFormatException('corrupt zip directory');
    }
    final name = utf8.decode(
      bytes.sublist(p + 46, p + 46 + nameLen),
      allowMalformed: true,
    );
    entries[name] = (
      method: dv.getUint16(p + 10, Endian.little),
      compressedSize: dv.getUint32(p + 20, Endian.little),
      localOffset: dv.getUint32(p + 42, Endian.little),
    );
    p += 46 + nameLen + extraLen + commentLen;
  }
  return entries;
}

String _readEntry(Uint8List bytes, _ZipEntry entry) {
  final dv = ByteData.sublistView(bytes);
  final off = entry.localOffset;
  if (off + 30 > bytes.length ||
      dv.getUint32(off, Endian.little) != 0x04034b50) {
    throw const BulletinFormatException('corrupt zip entry');
  }
  final start =
      off +
      30 +
      dv.getUint16(off + 26, Endian.little) +
      dv.getUint16(off + 28, Endian.little);
  final end = start + entry.compressedSize;
  if (end > bytes.length) {
    throw const BulletinFormatException('corrupt zip entry');
  }
  final data = bytes.sublist(start, end);
  final List<int> out;
  switch (entry.method) {
    case 0:
      out = data;
    case 8:
      try {
        out = ZLibCodec(raw: true).decode(data);
      } on Exception {
        throw const BulletinFormatException('corrupt zip entry');
      }
    default:
      throw const BulletinFormatException('unsupported zip compression');
  }
  if (out.length > _maxEntryBytes) {
    throw const BulletinFormatException('zip entry too large');
  }
  return utf8.decode(out, allowMalformed: true);
}

String _xmlText(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

List<String> _parseSharedStrings(String xml) {
  final out = <String>[];
  final si = RegExp('<si>(.*?)</si>', dotAll: true);
  final t = RegExp('<t[^>]*>(.*?)</t>', dotAll: true);
  for (final m in si.allMatches(xml)) {
    final text = t.allMatches(m.group(1)!).map((x) => x.group(1)!).join();
    out.add(_xmlText(text));
  }
  return out;
}

/// Cell reference (`B3`) to text: shared strings resolved, numbers as is.
Map<String, String> _parseSheet(String xml, List<String> strings) {
  final cells = <String, String>{};
  final cell = RegExp(
    r'<c r="([A-Z]+\d+)"([^>]*?)(?:/>|>(.*?)</c>)',
    dotAll: true,
  );
  final value = RegExp('<v>(.*?)</v>', dotAll: true);
  final shared = RegExp(r'\bt="s"');
  for (final m in cell.allMatches(xml)) {
    final v = value.firstMatch(m.group(3) ?? '')?.group(1);
    if (v == null) continue;
    if (shared.hasMatch(m.group(2)!)) {
      final i = int.tryParse(v);
      cells[m.group(1)!] = i != null && i >= 0 && i < strings.length
          ? strings[i]
          : '';
    } else {
      cells[m.group(1)!] = v;
    }
  }
  return cells;
}
