import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  container.read(errorSinkProvider).install();
  runApp(
    UncontrolledProviderScope(container: container, child: const MitlioApp()),
  );
}
