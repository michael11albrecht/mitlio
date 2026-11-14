import 'package:sentry/sentry.dart';

/// PII scrubber for crash reports (P7-T08, plan §8). Everything here is a pure
/// function over event data; it runs in `beforeSend` / `beforeBreadcrumb`, so
/// nothing leaves the device unscrubbed. Privacy-first: whatever is not on an
/// allowlist is dropped, and the rest is pattern-scrubbed.

/// What replaces removed free text.
const redacted = '[redacted]';

final _email = RegExp(r'[\w.+\-]+@[\w\-]+(?:\.[\w\-]+)+');

// Country code, check digits, then blocks of four (optionally space
// separated) and a short tail. No word boundaries on purpose: an IBAN glued
// to other text must still go.
final _iban = RegExp(
  r'[A-Za-z]{2}\d{2}(?: ?[A-Za-z0-9]{4}){2,7}(?: ?[A-Za-z0-9]{1,3})?',
);

final _phone = RegExp(r'\+?\d[\d ()/.\-]{6,}\d');

/// Replaces emails, IBANs and phone numbers in [input].
String scrubString(String input) => input
    .replaceAll(_email, '[email]')
    .replaceAll(_iban, '[iban]')
    .replaceAll(_phone, '[phone]');

// Top-level event fields that can carry personal data and have no use for
// crash analysis.
const _droppedKeys = {
  'user',
  'request',
  'server_name',
  'extra',
  'threads',
  'modules',
};

// Contexts that describe the platform only (no device name, no custom data).
const _allowedContexts = {'os', 'runtime', 'app'};

// Breadcrumb categories the app emits itself: route names and command names.
const _allowedBreadcrumbCategories = {'navigation', 'command'};

// Stack frame fields without variables, source context or absolute paths.
const _allowedFrameKeys = {
  'function',
  'filename',
  'module',
  'package',
  'lineno',
  'colno',
  'in_app',
  'platform',
  'instruction_addr',
};

// Technical identifiers that must not be pattern-scrubbed (hex ids would
// look like IBANs).
const _opaqueKeys = {
  'event_id',
  'timestamp',
  'platform',
  'level',
  'debug_meta',
  'instruction_addr',
  'image_addr',
  'debug_id',
  'build_id',
};

final _routeOrCommandName = RegExp(r'^[A-Za-z0-9_./:\-]{1,64}$');

Object? _scrubValue(Object? value, [String? key]) {
  if (key != null && _opaqueKeys.contains(key)) return value;
  return switch (value) {
    final String s => scrubString(s),
    final Map<dynamic, dynamic> m => {
      for (final e in m.entries)
        e.key.toString(): _scrubValue(e.value, e.key.toString()),
    },
    final List<dynamic> l => [for (final e in l) _scrubValue(e)],
    _ => value,
  };
}

Map<String, dynamic>? _scrubBreadcrumbJson(Map<dynamic, dynamic> json) {
  final category = json['category'];
  if (!_allowedBreadcrumbCategories.contains(category)) return null;
  final message = json['message'];
  return {
    for (final k in const ['timestamp', 'type', 'level'])
      if (json[k] != null) k: json[k],
    'category': category,
    'message': message is String && _routeOrCommandName.hasMatch(message)
        ? message
        : redacted,
  };
}

Map<String, dynamic> _scrubExceptionJson(Map<dynamic, dynamic> json) {
  final out = <String, dynamic>{
    for (final k in const ['type', 'module', 'mechanism', 'thread_id'])
      if (json[k] != null) k: _scrubValue(json[k], k),
    'value': redacted,
  };
  final frames = (json['stacktrace'] as Map?)?['frames'];
  if (frames is List) {
    out['stacktrace'] = {
      'frames': [
        for (final f in frames.whereType<Map<dynamic, dynamic>>())
          {
            for (final e in f.entries)
              if (_allowedFrameKeys.contains(e.key))
                e.key.toString(): _scrubValue(e.value, e.key.toString()),
          },
      ],
    };
  }
  return out;
}

/// Scrubs a Sentry event in JSON form. Removes user, request, extra and
/// device data, free text (exception messages, breadcrumb texts) and every
/// IBAN, email and phone number in what remains.
Map<String, dynamic> scrubEventJson(Map<String, dynamic> json) {
  final out = <String, dynamic>{};
  for (final e in json.entries) {
    final key = e.key;
    final value = e.value;
    if (_droppedKeys.contains(key)) continue;
    switch (key) {
      case 'message':
        out[key] = {'formatted': redacted};
      case 'exception':
        final values = (value as Map?)?['values'];
        if (values is List) {
          out[key] = {
            'values': [
              for (final v in values.whereType<Map<dynamic, dynamic>>())
                _scrubExceptionJson(v),
            ],
          };
        }
      case 'breadcrumbs':
        final kept = [
          for (final b
              in (value is List ? value : const <dynamic>[])
                  .whereType<Map<dynamic, dynamic>>())
            ?_scrubBreadcrumbJson(b),
        ];
        if (kept.isNotEmpty) out[key] = kept;
      case 'contexts':
        out[key] = {
          for (final c in (value as Map? ?? const {}).entries)
            if (_allowedContexts.contains(c.key))
              c.key.toString(): _scrubValue(c.value),
        };
      default:
        out[key] = _scrubValue(value, key);
    }
  }
  return out;
}

/// `SentryOptions.beforeSend`.
SentryEvent? scrubEvent(SentryEvent event, Hint hint) =>
    SentryEvent.fromJson(scrubEventJson(event.toJson()));

/// `SentryOptions.beforeBreadcrumb`: only route and command names pass.
Breadcrumb? scrubBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
  if (breadcrumb == null) return null;
  final json = _scrubBreadcrumbJson(breadcrumb.toJson());
  return json == null ? null : Breadcrumb.fromJson(json);
}
