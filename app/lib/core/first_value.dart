import 'dart:async';

/// The first event of [stream]. Listens and cancels by hand instead of
/// `stream.first`, so it settles with plain microtasks (no stream-cancel
/// future to wait for), which keeps widget tests on fake time moving.
Future<T> firstValue<T>(Stream<T> stream) {
  final done = Completer<T>();
  final sub = stream.listen(
    (value) {
      if (!done.isCompleted) done.complete(value);
    },
    onError: (Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    },
  );
  return done.future.whenComplete(() => unawaited(sub.cancel()));
}
