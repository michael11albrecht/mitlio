import 'dart:convert';

/// Member id sets are stored as a sorted JSON array on the row (plan §2.4:
/// sync is aggregate-level, so no child table).
String encodeIds(Set<String> ids) => jsonEncode(ids.toList()..sort());

/// Inverse of [encodeIds]; null when [json] is not a JSON array of strings.
Set<String>? decodeIds(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List<Object?> || !decoded.every((e) => e is String)) {
      return null;
    }
    return {...decoded.cast<String>()};
  } on FormatException {
    return null;
  }
}

/// UTC midnight of the calendar day of [d] (time and zone ignored).
DateTime calendarDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);
