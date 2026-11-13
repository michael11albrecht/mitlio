import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/providers.dart';

void main() {
  test('defaults are the production implementations', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(clockProvider), isA<SystemClock>());
    expect(c.read(idGeneratorProvider), isA<UuidV7Generator>());
    expect(c.read(loggerProvider), isA<DeveloperLogger>());
    expect(c.read(errorSinkProvider), isA<ErrorSink>());
  });

  test('overrides replace dependencies, including transitive ones', () {
    final clock = FixedClock(DateTime.utc(2026, 5));
    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
    );
    addTearDown(c.dispose);

    expect(c.read(clockProvider), same(clock));
    expect(c.read(idGeneratorProvider).newId(), 'id-1');

    c.read(errorSinkProvider).record('x', null);
    expect(c.read(errorSinkProvider).errors.single.time, clock.now());
  });
}
