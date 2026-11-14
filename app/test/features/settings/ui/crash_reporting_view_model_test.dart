import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Switch;
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/settings/ui/crash_reporting_view_model.dart';

import '../../../helpers/fake_app.dart';

class _NoopGateway extends SentryGateway {
  @override
  Future<void> init(String dsn) async {}

  @override
  Future<void> close() async {}
}

CrashReporter _reporter({String dsn = 'https://k@de.sentry.io/1'}) =>
    CrashReporter(
      dsn: dsn,
      store: MemoryCrashReportingStore(),
      gateway: _NoopGateway(),
    );

ProviderContainer _container(CrashReporter r) {
  final c = ProviderContainer(
    overrides: [crashReporterProvider.overrideWithValue(r)],
  );
  addTearDown(c.dispose);
  return c;
}

class _FailingStore extends MemoryCrashReportingStore {
  @override
  Future<void> save({required bool enabled}) async =>
      throw const FileSystemException('disk full');
}

void main() {
  test('store failure keeps the choice off and reporting inactive', () async {
    final r = CrashReporter(
      dsn: 'https://k@de.sentry.io/1',
      store: _FailingStore(),
      gateway: _NoopGateway(),
    );
    final c = _container(r);
    await c
        .read(crashReportingViewModelProvider.notifier)
        .setEnabled(enabled: true);
    expect(c.read(crashReportingViewModelProvider).enabled, isFalse);
    expect(r.isEnabled, isFalse);
    expect(r.isActive, isFalse);
  });

  test('default is off and available with a DSN', () {
    final s = _container(_reporter()).read(crashReportingViewModelProvider);
    expect(s.enabled, isFalse);
    expect(s.available, isTrue);
  });

  test('without a DSN the toggle is unavailable', () {
    final s = _container(
      _reporter(dsn: ''),
    ).read(crashReportingViewModelProvider);
    expect(s.available, isFalse);
  });

  test('setEnabled turns reporting on and off', () async {
    final r = _reporter();
    final c = _container(r);
    final vm = c.read(crashReportingViewModelProvider.notifier);
    await vm.setEnabled(enabled: true);
    expect(c.read(crashReportingViewModelProvider).enabled, isTrue);
    expect(r.isActive, isTrue);
    await vm.setEnabled(enabled: false);
    expect(c.read(crashReportingViewModelProvider).enabled, isFalse);
    expect(r.isActive, isFalse);
  });

  testWidgets('settings screen: switch is off by default and toggles', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final r = _reporter();
    final c = ProviderContainer(
      overrides: [
        ...FakeApp().overrides,
        crashReporterProvider.overrideWithValue(r),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MitlioApp()),
    );
    c.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Absturzberichte senden'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(r.isEnabled, isTrue);
  });
}
