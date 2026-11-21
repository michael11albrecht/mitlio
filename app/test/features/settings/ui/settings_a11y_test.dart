import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/profile/ui/profile_entry_view_model.dart';
import 'package:mitlio/features/settings/ui/licenses_view.dart';
import 'package:mitlio/features/settings/ui/settings_view.dart';

import '../../../helpers/a11y.dart';

/// The profile row without a stored profile: no repository is touched.
class StubProfileEntry extends ProfileEntryViewModel {
  @override
  ProfileSummary build() => ProfileSummary.none;
}

void main() {
  for (final dsn in ['https://k@de.sentry.io/1', '']) {
    forEachMode(
      dsn.isEmpty ? 'settings without DSN' : 'settings with DSN',
      () => ProviderScope(
        overrides: [
          crashReporterProvider.overrideWithValue(
            CrashReporter(dsn: dsn, store: MemoryCrashReportingStore()),
          ),
          profileEntryViewModelProvider.overrideWith(StubProfileEntry.new),
        ],
        child: const SettingsView(),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }

  forEachMode(
    'licenses',
    () => const LicensesView(),
    (tester, _, _) => expectAccessible(tester),
  );
}
