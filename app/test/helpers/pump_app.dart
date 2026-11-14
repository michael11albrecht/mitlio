import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/router.dart';

import 'fake_app.dart';

/// Starts the real [MitlioApp] on the in-memory repositories of [app] and
/// optionally jumps to [location]. The device language is [locale] (German
/// unless a test says otherwise). Returns the container, e.g. to read
/// ViewModels or the router.
Future<ProviderContainer> pumpMitlio(
  WidgetTester tester,
  FakeApp app, {
  String? location,
  Locale locale = const Locale('de'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final container = app.container();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MitlioApp()),
  );
  if (location != null) container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return container;
}
