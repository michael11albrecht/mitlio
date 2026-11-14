import 'package:mitlio/core/logging.dart';

/// Records everything logged, including errors and stack traces, so tests can
/// assert that sensitive values never reach a log.
class CapturingLogger implements Logger {
  final lines = <String>[];

  /// Everything captured, as one string.
  String get output => lines.join('\n');

  @override
  void debug(String message) => lines.add('debug $message');

  @override
  void info(String message) => lines.add('info $message');

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      lines.add('warn $message $error $stackTrace');

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      lines.add('error $message $error $stackTrace');
}
