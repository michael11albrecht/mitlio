import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';

enum LogLevel {
  debug(500),
  info(800),
  warn(900),
  error(1000);

  const LogLevel(this.value);

  /// `dart:developer` log level (matches `package:logging` values).
  final int value;
}

abstract interface class Logger {
  void debug(String message);
  void info(String message);
  void warn(String message, [Object? error, StackTrace? stackTrace]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// Logs through `dart:developer` (visible in DevTools and `flutter run`).
class DeveloperLogger implements Logger {
  const DeveloperLogger({this.name = 'mitlio'});

  final String name;

  void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => developer.log(
    message,
    name: name,
    level: level.value,
    error: error,
    stackTrace: stackTrace,
  );

  @override
  void debug(String message) => _log(LogLevel.debug, message);

  @override
  void info(String message) => _log(LogLevel.info, message);

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.warn, message, error, stackTrace);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);
}

/// One captured uncaught error.
class ErrorRecord {
  const ErrorRecord({
    required this.time,
    required this.error,
    this.stackTrace,
    this.source,
  });

  final DateTime time;
  final Object error;
  final StackTrace? stackTrace;

  /// Where it came from, e.g. `flutter` or `platform`.
  final String? source;
}

/// In-memory ring buffer of uncaught errors (oldest evicted first). Exposed
/// through DebugDrive `ext.mitlio.errors` (P3-T04).
class ErrorSink {
  ErrorSink({
    required this.clock,
    required this.logger,
    this.capacity = 50,
    this.crashReporter,
  }) : assert(capacity > 0, 'capacity must be positive');

  final Clock clock;
  final Logger logger;

  /// Opt-in crash reporting; forwards only while the user has it switched on.
  final CrashReporter? crashReporter;
  final int capacity;
  final Queue<ErrorRecord> _records = Queue();

  /// Oldest first.
  List<ErrorRecord> get errors => List.unmodifiable(_records);

  void record(Object error, StackTrace? stackTrace, {String? source}) {
    _records.add(
      ErrorRecord(
        time: clock.now(),
        error: error,
        stackTrace: stackTrace,
        source: source,
      ),
    );
    while (_records.length > capacity) {
      _records.removeFirst();
    }
    logger.error('Uncaught error (${source ?? 'unknown'})', error, stackTrace);
    crashReporter?.report(error, stackTrace);
  }

  void clear() => _records.clear();

  /// Routes `FlutterError.onError` and `PlatformDispatcher.onError` here.
  void install() {
    FlutterError.onError = (details) =>
        record(details.exception, details.stack, source: 'flutter');
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, source: 'platform');
      return true;
    };
  }
}
