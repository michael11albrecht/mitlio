import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:path_provider/path_provider.dart';

// TODO(P8-T01): read from AppConfig once the config files land. Empty in the
// repo: the owner sets it via CI secret + dart-define; empty means no Sentry.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final db = AppDatabase(
    NativeDatabase.createInBackground(File('${dir.path}/mitlio.sqlite')),
  );
  final crashReporter = CrashReporter(
    dsn: _sentryDsn,
    store: FileCrashReportingStore(File('${dir.path}/crash_reporting_on')),
  );
  await crashReporter.start();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      crashReporterProvider.overrideWithValue(crashReporter),
    ],
  );
  container.read(errorSinkProvider).install();
  if (kDebugMode) registerDebugDrive(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const MitlioApp()),
  );
}
