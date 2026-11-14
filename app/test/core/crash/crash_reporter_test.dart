import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';
import 'package:mitlio/core/crash/route_breadcrumbs.dart';
import 'package:mitlio/core/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FakeGateway extends SentryGateway {
  final calls = <String>[];

  @override
  Future<void> init(String dsn) async => calls.add('init:$dsn');

  @override
  Future<void> close() async => calls.add('close');

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace) async =>
      calls.add('capture:$error');

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async =>
      calls.add('crumb:${breadcrumb.category}:${breadcrumb.message}');
}

CrashReporter reporter({
  required FakeGateway gateway,
  String dsn = 'https://k@de.sentry.io/1',
  bool stored = false,
  MemoryCrashReportingStore? store,
}) => CrashReporter(
  dsn: dsn,
  store: store ?? MemoryCrashReportingStore(enabled: stored),
  gateway: gateway,
);

void main() {
  test('empty DSN: Sentry is never initialised, even when opted in', () async {
    final g = FakeGateway();
    final r = reporter(dsn: '', stored: true, gateway: g);
    await r.start();
    await r.setEnabled(enabled: true);
    r
      ..report(StateError('x'), null)
      ..breadcrumb('navigation', 'a');
    expect(g.calls, isEmpty);
    expect(r.isAvailable, isFalse);
    expect(r.isActive, isFalse);
  });

  test('default is off: nothing initialised or sent', () async {
    final g = FakeGateway();
    final r = reporter(gateway: g);
    await r.start();
    r.report(StateError('x'), null);
    expect(r.isEnabled, isFalse);
    expect(g.calls, isEmpty);
  });

  test('stored opt-in initialises on start and forwards errors', () async {
    final g = FakeGateway();
    final r = reporter(stored: true, gateway: g);
    await r.start();
    r
      ..report(StateError('boom'), null)
      ..breadcrumb('navigation', 'groups/:id');
    expect(g.calls, [
      'init:https://k@de.sentry.io/1',
      'capture:Bad state: boom',
      'crumb:navigation:groups/:id',
    ]);
  });

  test('toggle on persists and inits once; off closes and persists', () async {
    final g = FakeGateway();
    final store = MemoryCrashReportingStore();
    final r = reporter(gateway: g, store: store);
    await r.start();
    await r.setEnabled(enabled: true);
    await r.setEnabled(enabled: true);
    expect(store.enabled, isTrue);
    expect(g.calls, ['init:https://k@de.sentry.io/1']);
    await r.setEnabled(enabled: false);
    r.report(StateError('x'), null);
    expect(store.enabled, isFalse);
    expect(g.calls.last, 'close');
    expect(g.calls.where((c) => c.startsWith('capture')), isEmpty);
  });

  test('file store: marker file means on, default off', () async {
    final dir = await Directory.systemTemp.createTemp('crash_store');
    addTearDown(() => dir.delete(recursive: true));
    final store = FileCrashReportingStore(File('${dir.path}/sub/on'));
    expect(await store.load(), isFalse);
    await store.save(enabled: true);
    expect(await store.load(), isTrue);
    await store.save(enabled: false);
    expect(await store.load(), isFalse);
    await store.save(enabled: false);
  });

  test('ErrorSink forwards only while reporting is active', () async {
    final g = FakeGateway();
    final r = reporter(gateway: g);
    final sink = ErrorSink(
      clock: FixedClock(DateTime.utc(2026)),
      logger: const DeveloperLogger(),
      crashReporter: r,
    )..record(StateError('before'), null);
    await r.setEnabled(enabled: true);
    sink.record(StateError('after'), null);
    expect(g.calls.where((c) => c.startsWith('capture')), [
      'capture:Bad state: after',
    ]);
  });

  test('disabled reporter never reports', () {
    final r = CrashReporter.disabled()..report(StateError('x'), null);
    expect(r.isActive, isFalse);
  });

  test('options are locked down and scrubbed', () {
    final o = SentryFlutterOptions();
    configureSentryOptions(o, 'https://k@de.sentry.io/1');
    expect(o.dsn, 'https://k@de.sentry.io/1');
    expect(o.beforeSend, isNotNull);
    expect(o.beforeBreadcrumb, isNotNull);
    expect(o.sendDefaultPii, isFalse);
    expect(o.autoInitializeNativeSdk, isFalse);
    expect(o.attachScreenshot, isFalse);
    expect(o.tracesSampleRate, isNull);
    final names = o.integrations.map((i) => i.runtimeType.toString());
    expect(names, isNot(contains('FlutterErrorIntegration')));
    expect(names, isNot(contains('OnErrorIntegration')));
  });

  test('route observer reports route names only', () async {
    final g = FakeGateway();
    final r = reporter(stored: true, gateway: g);
    await r.start();
    RouteBreadcrumbObserver(r)
      ..didPush(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'groups/:id'),
          builder: (_) => const SizedBox(),
        ),
        null,
      )
      ..didPush(MaterialPageRoute<void>(builder: (_) => const SizedBox()), null)
      ..didReplace(
        newRoute: MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'settings'),
          builder: (_) => const SizedBox(),
        ),
      )
      ..didPop(
        MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/'),
          builder: (_) => const SizedBox(),
        ),
      );
    expect(g.calls.skip(1), [
      'crumb:navigation:groups/:id',
      'crumb:navigation:settings',
      'crumb:navigation:/',
    ]);
  });
}
