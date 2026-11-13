import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/logging.dart';

class _RecordingLogger implements Logger {
  final lines = <String>[];

  @override
  void debug(String message) => lines.add('debug $message');
  @override
  void info(String message) => lines.add('info $message');
  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      lines.add('warn $message');
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      lines.add('error $message');
}

void main() {
  test('DeveloperLogger accepts every level without throwing', () {
    const logger = DeveloperLogger();
    logger
      ..debug('d')
      ..info('i')
      ..warn('w', 'e', StackTrace.current)
      ..error('x', 'e', StackTrace.current);
    expect(LogLevel.error.value, greaterThan(LogLevel.warn.value));
  });

  group('ErrorSink', () {
    late FixedClock clock;
    late _RecordingLogger logger;
    setUp(() {
      clock = FixedClock(DateTime.utc(2026));
      logger = _RecordingLogger();
    });

    ErrorSink sink({int capacity = 3}) =>
        ErrorSink(clock: clock, logger: logger, capacity: capacity);

    test('records errors oldest first with time, source and logs them', () {
      final s = sink()..record('a', StackTrace.empty, source: 'flutter');
      clock.advance(const Duration(seconds: 1));
      s.record('b', null);
      expect(s.errors.map((e) => e.error), ['a', 'b']);
      expect(s.errors.first.time, DateTime.utc(2026));
      expect(s.errors.first.source, 'flutter');
      expect(s.errors.first.stackTrace, StackTrace.empty);
      expect(s.errors.last.time, DateTime.utc(2026, 1, 1, 0, 0, 1));
      expect(logger.lines, hasLength(2));
      expect(logger.lines.first, startsWith('error '));
    });

    test('ring buffer evicts the oldest beyond capacity', () {
      final s = sink();
      for (var i = 1; i <= 5; i++) {
        s.record('e$i', null);
      }
      expect(s.errors.map((e) => e.error), ['e3', 'e4', 'e5']);
    });

    test('errors view is unmodifiable and clear empties it', () {
      final s = sink()..record('a', null);
      expect(() => s.errors.clear(), throwsUnsupportedError);
      s.clear();
      expect(s.errors, isEmpty);
    });

    test('capacity must be positive', () {
      expect(() => sink(capacity: 0), throwsA(isA<AssertionError>()));
    });

    test('install routes FlutterError and platform errors into the sink', () {
      final oldFlutter = FlutterError.onError;
      final oldPlatform = PlatformDispatcher.instance.onError;
      addTearDown(() {
        FlutterError.onError = oldFlutter;
        PlatformDispatcher.instance.onError = oldPlatform;
      });
      final s = sink()..install();

      FlutterError.onError!(const FlutterErrorDetails(exception: 'boom'));
      final handled = PlatformDispatcher.instance.onError!(
        'async',
        StackTrace.empty,
      );

      expect(handled, isTrue);
      expect(s.errors.map((e) => '${e.source}:${e.error}'), [
        'flutter:boom',
        'platform:async',
      ]);
    });
  });
}
