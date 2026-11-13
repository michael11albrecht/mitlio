import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/router.dart';

/// Root widget. Must sit under a `ProviderScope`. Theme arrives in P3-T05.
class MitlioApp extends ConsumerWidget {
  const MitlioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'mitlio',
      routerConfig: ref.watch(routerProvider),
    );
  }
}
