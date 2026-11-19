import 'dart:async';

import 'package:flutter/widgets.dart';

/// Tells when the app comes back to the foreground. Inject instead of
/// observing the widgets binding directly, so tests can fire it.
abstract interface class LifecycleSource {
  /// Emits every time the app is resumed.
  Stream<void> get onResume;
}

/// Never emits: tests and headless runs without a widgets binding.
class NoLifecycle implements LifecycleSource {
  const NoLifecycle();

  @override
  Stream<void> get onResume => const Stream.empty();
}

/// The real thing: `WidgetsBindingObserver`, attached on the first listener.
class WidgetsLifecycleSource
    with WidgetsBindingObserver
    implements LifecycleSource {
  WidgetsLifecycleSource() {
    _controller = StreamController<void>.broadcast(
      onListen: () => WidgetsBinding.instance.addObserver(this),
      onCancel: () => WidgetsBinding.instance.removeObserver(this),
    );
  }

  late final StreamController<void> _controller;

  @override
  Stream<void> get onResume => _controller.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.add(null);
  }
}
