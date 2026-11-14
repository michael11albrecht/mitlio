// Entrypoint compiled with dart2js; exposes `globalThis.mitlio`.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:mitlio_domain_web/mitlio_domain_web.dart' as facade;

JSAny? _calculateTrip(JSAny? input) {
  final dartified = input.dartify();
  final map = dartified is Map
      ? dartified.map((k, v) => MapEntry(k.toString(), v))
      : <String, Object?>{};
  return facade.calculateTrip(map).jsify();
}

void main() {
  final api = JSObject()
    ..['version'] = facade.version.toJS
    ..['calculateTrip'] = _calculateTrip.toJS;
  globalContext['mitlio'] = api;
}
