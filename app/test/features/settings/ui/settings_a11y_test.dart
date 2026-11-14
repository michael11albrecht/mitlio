import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/settings/ui/settings_view.dart';

import '../../../helpers/a11y.dart';

void main() {
  for (final dsn in ['https://k@de.sentry.io/1', '']) {
    forEachMode(
      dsn.isEmpty ? 'settings without DSN' : 'settings with DSN',
      () => ProviderScope(
        overrides: [
          crashReporterProvider.overrideWithValue(
            CrashReporter(dsn: dsn, store: MemoryCrashReportingStore()),
          ),
        ],
        child: const SettingsView(),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
