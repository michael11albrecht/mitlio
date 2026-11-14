import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/debug/debug_drive.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  container.read(errorSinkProvider).install();
  if (kDebugMode) registerDebugDrive(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const MitlioApp()),
  );
}
