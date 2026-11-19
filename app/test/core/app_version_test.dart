import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app_version.dart';

void main() {
  test('the app version is unknown until main reads it', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(appVersionProvider), isNull);
  });

  for (final (platform, store) in <(TargetPlatform, String?)>[
    (TargetPlatform.iOS, 'ios'),
    (TargetPlatform.android, 'android'),
    (TargetPlatform.linux, null),
    (TargetPlatform.macOS, null),
    (TargetPlatform.windows, null),
  ]) {
    test('$platform gates against ${store ?? 'nothing'}', () {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(storePlatformProvider), store);
    });
  }
}
