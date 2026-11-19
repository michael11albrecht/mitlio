import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's own version, e.g. `0.2.0` (without build number). `main` sets it
/// from `PackageInfo`; null (tests, unreadable) means the version gate has
/// nothing to compare and does not block.
final appVersionProvider = Provider<String?>((ref) => null);

/// The `app_config.platform` of this build: `ios` or `android`. Null on any
/// other platform (the headless Linux harness), which is never gated.
final storePlatformProvider = Provider<String?>(
  (ref) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => null,
  },
);
