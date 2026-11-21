import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _header =
    'GENERATED from app/lib/l10n/app_*.arb by '
    'packages/tooling/bin/gen_push_strings.dart. Do not edit; run `make push-strings`.';

/// The locale whose strings are also the platform default (the app's template
/// ARB is German).
const pushDefaultLocale = 'de';

/// The loc-keys the `notify` Edge Function sends (`LOC_KEYS` and `bodyFor` in
/// `supabase/functions/_shared/notify.ts`, P6b-T04) with the number of
/// arguments it passes. The OS renders them in the device language from the
/// strings generated here, so every one must exist in every locale.
const pushLocKeys = <String, int>{
  'push_expense_added': 3,
  'push_expense_changed': 3,
  'push_expense_deleted': 2,
  'push_settlement_added': 2,
  'push_member_joined': 2,
  'push_expenses_added': 3,
  'push_group_updates': 2,
  'push_generic': 1,
};

/// One localized body: [text] with `{name}` placeholders, [args] in the order
/// the server passes them (the order of the ARB `placeholders` map).
class PushString {
  const PushString(this.text, this.args);

  final String text;
  final List<String> args;
}

/// The push loc-keys of every ARB locale, and the files generated from them.
///
/// ARB keys `pushLoc<Name>` become the loc-key `push_<name_in_snake_case>`.
class PushStrings {
  const PushStrings(this.byLocale);

  /// Reads `app_<locale>.arb` sources, keyed by locale. Throws
  /// [FormatException] for JSON that is not an object.
  factory PushStrings.parse(Map<String, String> arbByLocale) {
    final byLocale = <String, Map<String, PushString>>{};
    for (final entry in arbByLocale.entries) {
      final json = jsonDecode(entry.value);
      if (json is! Map<String, Object?>) {
        throw FormatException('app_${entry.key}.arb: not a JSON object');
      }
      final strings = <String, PushString>{};
      for (final e in json.entries) {
        final text = e.value;
        if (!e.key.startsWith('pushLoc') || text is! String) continue;
        final meta = json['@${e.key}'];
        final placeholders = meta is Map ? meta['placeholders'] : null;
        strings[_locKey(e.key)] = PushString(text, [
          if (placeholders is Map) ...placeholders.keys.cast<String>(),
        ]);
      }
      byLocale[entry.key] = strings;
    }
    return PushStrings(byLocale);
  }

  /// `pushLocExpenseAdded` -> `push_expense_added`.
  static String _locKey(String arbKey) {
    final rest = arbKey.substring('pushLoc'.length);
    final snake = rest.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );
    return 'push$snake';
  }

  /// locale -> loc-key -> string.
  final Map<String, Map<String, PushString>> byLocale;

  /// Everything wrong with the strings; empty when every locale defines every
  /// loc-key of [pushLocKeys] with the right arguments, and defines no other.
  List<String> problems() {
    final out = <String>[];
    if (!byLocale.containsKey(pushDefaultLocale)) {
      out.add('no app_$pushDefaultLocale.arb (the default locale)');
    }
    for (final e in byLocale.entries) {
      for (final k in pushLocKeys.entries) {
        final s = e.value[k.key];
        if (s == null) {
          out.add('${e.key}: missing loc-key ${k.key}');
          continue;
        }
        if (s.text.trim().isEmpty) out.add('${e.key}: ${k.key} is empty');
        if (s.args.length != k.value) {
          out.add(
            '${e.key}: ${k.key} has ${s.args.length} arguments, '
            'the server sends ${k.value}',
          );
        }
        for (final a in s.args) {
          if (!s.text.contains('{$a}')) {
            out.add('${e.key}: ${k.key} never uses {$a}');
          }
        }
      }
      for (final key in e.value.keys) {
        if (!pushLocKeys.containsKey(key)) {
          out.add('${e.key}: $key is not a loc-key the server sends');
        }
      }
    }
    return out;
  }

  /// Generated files, keyed by path relative to the repository root.
  Map<String, String> generate() => {
    for (final e in byLocale.entries) ...{
      'app/android/app/src/main/res/${_androidDir(e.key)}/push_strings.xml':
          _android(e.value),
      'app/ios/Runner/${e.key}.lproj/Localizable.strings': _ios(e.value),
    },
  };

  static String _androidDir(String locale) =>
      locale == pushDefaultLocale ? 'values' : 'values-$locale';

  static Iterable<MapEntry<String, PushString>> _sorted(
    Map<String, PushString> strings,
  ) =>
      (strings.entries.where((e) => pushLocKeys.containsKey(e.key)).toList()
        ..sort((a, b) => a.key.compareTo(b.key)));

  /// ICU `''` is an apostrophe.
  static String _plain(String text) => text.replaceAll("''", "'");

  static String _args(
    PushString s,
    String Function(int position) placeholder,
  ) {
    var text = _plain(s.text);
    for (var i = 0; i < s.args.length; i++) {
      text = text.replaceAll('{${s.args[i]}}', placeholder(i + 1));
    }
    return text;
  }

  String _android(Map<String, PushString> strings) {
    final b = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n')
      ..writeln('<!-- $_header -->')
      ..writeln('<resources>');
    for (final e in _sorted(strings)) {
      final value = _args(e.value, (n) => '%$n\$s')
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll("'", r"\'")
          .replaceAll('"', r'\"');
      final escaped = value.startsWith('@') || value.startsWith('?')
          ? '\\$value'
          : value;
      b.writeln('    <string name="${e.key}">$escaped</string>');
    }
    return (b..writeln('</resources>')).toString();
  }

  String _ios(Map<String, PushString> strings) {
    final b = StringBuffer('/* $_header */\n');
    for (final e in _sorted(strings)) {
      final value = _args(
        e.value,
        (n) => '%$n\$@',
      ).replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');
      b.writeln('"${e.key}" = "$value";');
    }
    return b.toString();
  }
}

/// Reads `app/lib/l10n/app_<locale>.arb` under [root].
PushStrings readPushStrings(String root) {
  final dir = Directory(p.join(root, 'app/lib/l10n'));
  final arbs = <String, String>{};
  for (final f in dir.listSync().whereType<File>()) {
    final m = RegExp(r'^app_([a-zA-Z_]+)\.arb$').firstMatch(p.basename(f.path));
    if (m != null) arbs[m[1]!] = f.readAsStringSync();
  }
  return PushStrings.parse(arbs);
}

/// Paths (relative to the repo root) whose content differs from [strings].
List<String> pushStringsDrift(String root, PushStrings strings) => [
  for (final e in strings.generate().entries)
    if (_read(p.join(root, e.key)) != e.value) e.key,
];

String? _read(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
}

/// CLI: `gen_push_strings [--root <repo>] [--check]`. Fails (exit 1) when a
/// loc-key is missing in a locale; with `--check` also when the generated
/// files differ. Returns the exit code.
Future<int> runGenPushStrings(
  List<String> args, {
  required StringSink out,
  required StringSink err,
}) async {
  var root = '.';
  var check = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--check':
        check = true;
      case '--root' when i + 1 < args.length:
        root = args[++i];
      default:
        err.writeln('usage: gen_push_strings [--root <repo>] [--check]');
        return 64;
    }
  }
  final PushStrings strings;
  try {
    strings = readPushStrings(root);
  } on FormatException catch (e) {
    err.writeln(e.message);
    return 1;
  } on FileSystemException catch (e) {
    err.writeln('cannot read the ARB files: ${e.message}');
    return 1;
  }
  final problems = strings.problems();
  if (problems.isNotEmpty) {
    err.writeln('push loc-keys:\n  ${problems.join('\n  ')}');
    return 1;
  }
  if (check) {
    final drift = pushStringsDrift(root, strings);
    if (drift.isEmpty) {
      out.writeln('push strings: up to date');
      return 0;
    }
    err.writeln(
      'push strings drift (run `make push-strings`):\n  ${drift.join('\n  ')}',
    );
    return 1;
  }
  for (final e in strings.generate().entries) {
    final file = File(p.join(root, e.key));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(e.value);
    out.writeln('wrote ${e.key}');
  }
  return 0;
}
