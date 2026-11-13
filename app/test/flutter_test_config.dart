import 'package:alchemist/alchemist.dart';

/// Golden policy (ADR 0022): only platform-independent "CI" goldens are
/// committed and verified, on every host. Platform goldens (real text) differ
/// per OS and are disabled. Files live in `test/goldens/` next to the tests.
Future<void> testExecutable(Future<void> Function() testMain) {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: CiGoldensConfig(
        filePathResolver: (fileName, _) => 'goldens/$fileName.png',
      ),
    ),
    run: testMain,
  );
}
