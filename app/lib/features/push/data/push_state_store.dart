import 'dart:convert';
import 'dart:io';

/// What the app remembers about push between starts: whether the user was
/// already asked (the offer is made once), and the token the server knows
/// (so a rotated token is registered again, and sign-out can unregister it).
/// Methods may throw when the storage fails; callers report that.
abstract interface class PushStateStore {
  Future<bool> asked();

  Future<void> setAsked();

  /// The token last registered on the server; null: none.
  Future<String?> registeredToken();

  Future<void> setRegisteredToken(String? token);
}

/// [PushStateStore] in one small JSON file in the app's support directory
/// (like the crash-report choice).
class FilePushStateStore implements PushStateStore {
  const FilePushStateStore(this.file);

  final File file;

  Future<Map<String, Object?>> _read() async {
    if (!file.existsSync()) return {};
    try {
      final json = jsonDecode(await file.readAsString());
      return json is Map<String, Object?> ? json : {};
    } on FormatException {
      // A damaged file only means: ask once more and register again. Nothing
      // the user did is lost, so this is not an error to show.
      return {};
    }
  }

  Future<void> _write(Map<String, Object?> state) =>
      file.writeAsString(jsonEncode(state), flush: true);

  @override
  Future<bool> asked() async => (await _read())['asked'] == true;

  @override
  Future<void> setAsked() async => _write({...await _read(), 'asked': true});

  @override
  Future<String?> registeredToken() async =>
      (await _read())['token'] as String?;

  @override
  Future<void> setRegisteredToken(String? token) async =>
      _write({...await _read(), 'token': token});
}

/// In-memory store: the default, and the one tests use.
class MemoryPushStateStore implements PushStateStore {
  MemoryPushStateStore({this.wasAsked = false, this.token});

  bool wasAsked;
  String? token;

  /// While set, every call throws it (a full or broken disk).
  Exception? failWith;

  void _gate() {
    final e = failWith;
    if (e != null) throw e;
  }

  @override
  Future<bool> asked() async {
    _gate();
    return wasAsked;
  }

  @override
  Future<void> setAsked() async {
    _gate();
    wasAsked = true;
  }

  @override
  Future<String?> registeredToken() async {
    _gate();
    return token;
  }

  @override
  Future<void> setRegisteredToken(String? value) async {
    _gate();
    token = value;
  }
}
