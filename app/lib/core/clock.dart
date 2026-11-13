/// Source of the current time. Inject instead of calling `DateTime.now()`.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class Clock {
  DateTime now();
}

/// Wall-clock time.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Test clock: settable and advanceable.
class FixedClock implements Clock {
  FixedClock(this.value);

  /// The time returned by [now]; assign to jump.
  DateTime value;

  @override
  DateTime now() => value;

  void advance(Duration by) => value = value.add(by);
}
