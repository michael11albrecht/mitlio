import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/logging.dart';

/// Root providers. Override in tests / DebugDrive with fakes (ADR-23: plain
/// providers, no codegen).
final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => UuidV7Generator(clock: ref.watch(clockProvider)),
);

final loggerProvider = Provider<Logger>((ref) => const DeveloperLogger());

final errorSinkProvider = Provider<ErrorSink>(
  (ref) => ErrorSink(
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider),
  ),
);
