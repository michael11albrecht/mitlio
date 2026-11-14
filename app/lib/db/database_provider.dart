import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/db/app_database.dart';

/// The app database. No default: `main` (and tests / DebugDrive) must
/// override it, e.g. with `NativeDatabase.memory()` in tests.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);
