import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// App routes. Only the placeholder home exists until features land.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(child: Text(AppLocalizations.of(context).appName)),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
