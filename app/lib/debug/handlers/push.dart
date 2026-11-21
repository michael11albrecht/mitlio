import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/push_providers.dart';
import 'package:mitlio/features/push/data/repositories/push_routing.dart';

/// `ext.mitlio.push.simulate` `{payload, source?, body?}` (key without the
/// `ext.mitlio.` prefix): feeds a push message through the same
/// `PushRouting.handle` the platform streams use, so routing is tested
/// without FCM. `payload` is the FCM `data` map as JSON (`group_id`, `event`,
/// `expense_id`, `hide_amounts`), `source` is `tap` (default), `foreground` or
/// `background`, `body` the text the OS would have shown. Returns `route` (the
/// current location), `pulled`, `opened` (screens, bottom first) and
/// `announced` (`incoming`, `openFailed` or null). A payload without a usable
/// `group_id` is `invalid_params`.
Map<String, DriveHandler> pushDriveHandlers(ProviderContainer c) => {
  'push.simulate': (p) => _simulate(c, p),
};

Future<DriveResult> _simulate(
  ProviderContainer c,
  Map<String, String> p,
) async {
  final data = _data(p['payload']);
  final source = PushSource.values.asNameMap()[p['source'] ?? 'tap'];
  if (data == null) return invalidParams('payload must be a JSON object');
  if (source == null) return invalidParams('unknown source: ${p['source']}');
  final handled = await c
      .read(pushRoutingProvider)
      .handle(PushMessage(data, body: p['body']), source);
  final announced = switch (handled.announced) {
    PushIncoming() => 'incoming',
    PushOpenFailed() => 'openFailed',
    null => null,
  };
  if (handled.payload == null) {
    return {
      ...invalidParams('payload has no usable group_id'),
      'announced': announced,
    };
  }
  // The top-most screen, also when it was pushed (the route information
  // reports only the stack made by `go`).
  final route = c
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .last
      .matchedLocation;
  return {
    'route': route,
    'pulled': handled.pulled,
    'opened': handled.opened,
    'announced': announced,
  };
}

Map<String, String>? _data(String? json) {
  try {
    final decoded = json == null ? null : jsonDecode(json);
    if (decoded is! Map<String, Object?>) return null;
    return {for (final e in decoded.entries) e.key: '${e.value}'};
  } on FormatException {
    return null;
  }
}
