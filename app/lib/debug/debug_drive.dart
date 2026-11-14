import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/router.dart';

/// Build identifier injected with `--dart-define=BUILD_SHA=<sha>`.
const buildSha = String.fromEnvironment('BUILD_SHA', defaultValue: 'dev');

/// App version reported by `ext.mitlio.ping`.
const appVersion = '0.1.0';

typedef DriveResult = Map<String, Object?>;
typedef DriveHandler = Future<DriveResult> Function(Map<String, String> params);

/// Wipes and seeds local data for DebugDrive (`reset` / `seed`).
abstract interface class DebugDataControl {
  Future<void> wipe();

  /// Returns the ids of the created entities.
  Future<DriveResult> seed(String scenario);
}

/// Placeholder until the Drift DB lands.
// TODO(P3-T02): implement DebugDataControl on AppDatabase (wipe) and seed via
// repositories from tool/fixtures/*.json, then override debugDataControlProvider.
class NoopDebugDataControl implements DebugDataControl {
  const NoopDebugDataControl();

  @override
  Future<void> wipe() async {}

  @override
  Future<DriveResult> seed(String scenario) async => {'ids': <String>[]};
}

final debugDataControlProvider = Provider<DebugDataControl>(
  (ref) => const NoopDebugDataControl(),
);

/// ViewModels register their `debugSnapshot()` here (empty until slices land).
class DebugSnapshotRegistry {
  final _snapshots = <String, DriveResult Function()>{};

  void register(String screen, DriveResult Function() snapshot) =>
      _snapshots[screen] = snapshot;

  void unregister(String screen) => _snapshots.remove(screen);

  Iterable<String> get screens => _snapshots.keys;

  DriveResult? snapshot(String screen) => _snapshots[screen]?.call();
}

final debugSnapshotRegistryProvider = Provider<DebugSnapshotRegistry>(
  (ref) => DebugSnapshotRegistry(),
);

DriveResult invalidParams(String message) => {
  'error': 'invalid_params',
  'message': message,
};

/// Builds the handler table (keys without the `ext.mitlio.` prefix).
Map<String, DriveHandler> buildDriveHandlers({
  required ErrorSink errors,
  required GoRouter router,
  required DebugDataControl data,
  required DebugSnapshotRegistry snapshots,
  String version = appVersion,
  String sha = buildSha,
}) {
  String location() => router.routeInformationProvider.value.uri.toString();
  return {
    'ping': (_) async => {'version': version, 'buildSha': sha},
    'reset': (_) async {
      await data.wipe();
      return {'ok': true};
    },
    'seed': (p) async {
      final scenario = p['scenario'];
      if (scenario == null || scenario.isEmpty) {
        return invalidParams('missing param: scenario');
      }
      return data.seed(scenario);
    },
    'state': (p) async {
      final screen = p['screen'];
      if (screen == null) {
        return {'route': location(), 'screens': snapshots.screens.toList()};
      }
      final snap = snapshots.snapshot(screen);
      if (snap == null) return invalidParams('unknown screen: $screen');
      return {'route': location(), 'screen': screen, 'state': snap};
    },
    'navigate': (p) async {
      final route = p['route'];
      if (route == null || !route.startsWith('/')) {
        return invalidParams('param route must start with /');
      }
      router.go(route);
      return {'route': location()};
    },
    'errors': (_) async {
      final records = errors.errors;
      errors.clear();
      return {
        'errors': [
          for (final r in records)
            {
              'time': r.time.toIso8601String(),
              'source': r.source,
              'error': r.error.toString(),
              'stackTrace': r.stackTrace?.toString(),
            },
        ],
      };
    },
  };
}

/// Runs [handler]; never throws, reports failures as `{error, message}`.
Future<DriveResult> runDriveHandler(
  DriveHandler handler,
  Map<String, String> params,
) async {
  try {
    return await handler(params);
  } on Object catch (e) {
    return {'error': 'internal', 'message': e.toString()};
  }
}

/// Registers every `ext.mitlio.*` extension. Call only under `kDebugMode`.
void registerDebugDrive(ProviderContainer container) {
  final handlers = buildDriveHandlers(
    errors: container.read(errorSinkProvider),
    router: container.read(routerProvider),
    data: container.read(debugDataControlProvider),
    snapshots: container.read(debugSnapshotRegistryProvider),
  );
  for (final entry in handlers.entries) {
    developer.registerExtension('ext.mitlio.${entry.key}', (_, params) async {
      final result = await runDriveHandler(entry.value, params);
      return developer.ServiceExtensionResponse.result(jsonEncode(result));
    });
  }
}
