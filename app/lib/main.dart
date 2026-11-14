import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final db = AppDatabase(
    NativeDatabase.createInBackground(File('${dir.path}/mitlio.sqlite')),
  );
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(errorSinkProvider).install();
  if (kDebugMode) registerDebugDrive(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const MitlioApp()),
  );
}
