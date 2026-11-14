import 'dart:io';

import 'package:mitlio/core/crash/scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Where the opt-in choice lives. Default (nothing stored) is off.
abstract interface class CrashReportingStore {
  Future<bool> load();
  Future<void> save({required bool enabled});
}

/// Keeps the choice in a marker file: present means on.
class FileCrashReportingStore implements CrashReportingStore {
  const FileCrashReportingStore(this.file);

  final File file;

  @override
  Future<bool> load() async => file.existsSync();

  @override
  Future<void> save({required bool enabled}) async {
    if (enabled) {
      await file.create(recursive: true);
    } else if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// In-memory store (tests, and the default before the app wires the file).
class MemoryCrashReportingStore implements CrashReportingStore {
  MemoryCrashReportingStore({this.enabled = false});

  bool enabled;

  @override
  Future<bool> load() async => enabled;

  @override
  Future<void> save({required bool enabled}) async => this.enabled = enabled;
}

/// The three Sentry calls we use, so tests never touch the SDK or network.
class SentryGateway {
  const SentryGateway();

  Future<void> init(String dsn) => SentryFlutter.init(
    (o) => configureSentryOptions(o, dsn),
  );

  Future<void> close() => Sentry.close();

  Future<void> captureException(Object error, StackTrace? stackTrace) =>
      Sentry.captureException(error, stackTrace: stackTrace);

  Future<void> addBreadcrumb(Breadcrumb breadcrumb) =>
      Sentry.addBreadcrumb(breadcrumb);
}

/// Locked-down Sentry options: scrubbed, Dart-only, no performance data, no
/// automatic breadcrumbs or attachments, errors only via [CrashReporter].
void configureSentryOptions(SentryFlutterOptions o, String dsn) {
  o
    ..dsn = dsn
    ..sendDefaultPii = false
    ..beforeSend = scrubEvent
    ..beforeBreadcrumb = scrubBreadcrumb
    ..autoInitializeNativeSdk = false
    ..enableNativeCrashHandling = false
    ..enableAutoNativeBreadcrumbs = false
    ..enableUserInteractionBreadcrumbs = false
    ..enableUserInteractionTracing = false
    ..enableAutoPerformanceTracing = false
    ..enableFramesTracking = false
    ..attachScreenshot = false
    ..attachViewHierarchy = false
    ..attachThreads = false
    ..captureFailedRequests = false
    ..sendClientReports = false
    ..tracesSampleRate = null;
  // ErrorSink forwards errors; the SDK must not hook the global handlers.
  for (final i in o.integrations) {
    final name = i.runtimeType.toString();
    if (name == 'FlutterErrorIntegration' || name == 'OnErrorIntegration') {
      o.removeIntegration(i);
    }
  }
}

/// Opt-in crash reporting. Sentry is initialised only when a DSN is
/// configured AND the user turned reporting on; with an empty DSN or the
/// toggle off nothing is initialised and no network call is possible.
class CrashReporter {
  CrashReporter({
    required this.dsn,
    required this.store,
    this.gateway = const SentryGateway(),
  });

  /// A reporter that never reports (empty DSN).
  CrashReporter.disabled() : this(dsn: '', store: MemoryCrashReportingStore());

  final String dsn;
  final SentryGateway gateway;
  final CrashReportingStore store;
  bool _enabled = false;
  bool _active = false;

  /// This build has a DSN, so the toggle has an effect.
  bool get isAvailable => dsn.isNotEmpty;

  /// The user's choice.
  bool get isEnabled => _enabled;

  /// Sentry is initialised and errors are forwarded.
  bool get isActive => _active;

  /// Loads the stored choice; initialises Sentry only if DSN and choice allow.
  Future<void> start() async {
    _enabled = await store.load();
    await _sync();
  }

  Future<void> setEnabled({required bool enabled}) async {
    _enabled = enabled;
    await store.save(enabled: enabled);
    await _sync();
  }

  Future<void> _sync() async {
    final shouldRun = isAvailable && _enabled;
    if (shouldRun && !_active) {
      _active = true;
      await gateway.init(dsn);
    } else if (!shouldRun && _active) {
      _active = false;
      await gateway.close();
    }
  }

  /// Called by `ErrorSink`; a no-op unless reporting is active.
  void report(Object error, StackTrace? stackTrace) {
    if (!_active) return;
    gateway.captureException(error, stackTrace).ignore();
  }

  /// A route or command name (never free text). No-op unless active.
  void breadcrumb(String category, String name) {
    if (!_active) return;
    gateway
        .addBreadcrumb(Breadcrumb(category: category, message: name))
        .ignore();
  }
}
