import 'package:glados/glados.dart';

extension NoShrinkAny on Any {
  /// Like `intInRange(min, max)` (max exclusive) but never shrinks. glados
  /// shrinks ints by 1, which takes up to 1e6..1e11 steps on a failing
  /// property and makes mutation runs hit their timeout.
  Generator<int> intNoShrink(int min, int max) => simple(
    generate: (random, size) => random.nextIntInRange(min, max),
    shrink: (_) => const [],
  );
}
