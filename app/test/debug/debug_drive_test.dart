import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/debug/debug_drive.dart';

class _FakeData implements DebugDataControl {
  int wipes = 0;
  bool failWipe = false;

  @override
  Future<void> wipe() async {
    if (failWipe) throw StateError('db down');
    wipes++;
  }

  @override
  Future<DriveResult> seed(String scenario) async => {
    'ids': ['$scenario-1'],
  };
}

void main() {
  late ProviderContainer container;
  late _FakeData data;
  late DebugSnapshotRegistry snapshots;
  late ErrorSink sink;
  late GoRouter router;
  late Map<String, DriveHandler> h;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    data = _FakeData();
    snapshots = DebugSnapshotRegistry();
    sink = container.read(errorSinkProvider);
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/a', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    h = buildDriveHandlers(
      errors: sink,
      router: router,
      data: data,
      snapshots: snapshots,
      version: '9.9.9',
      sha: 'abc',
    );
  });

  test('ping returns version and build sha', () async {
    expect(await h['ping']!({}), {'version': '9.9.9', 'buildSha': 'abc'});
  });

  test('reset wipes data', () async {
    expect(await h['reset']!({}), {'ok': true});
    expect(data.wipes, 1);
  });

  test('reset failure is reported, not thrown', () async {
    data.failWipe = true;
    final r = await runDriveHandler(h['reset']!, {});
    expect(r['error'], 'internal');
    expect(r['message'], contains('db down'));
  });

  test('seed passes scenario; missing scenario is invalid_params', () async {
    expect(await h['seed']!({'scenario': 'trip'}), {
      'ids': ['trip-1'],
    });
    expect((await h['seed']!({}))['error'], 'invalid_params');
  });

  test('state returns route and registered screens', () async {
    snapshots.register('list', () => {'n': 1});
    expect(await h['state']!({}), {
      'route': '/',
      'screens': ['list'],
    });
    expect(await h['state']!({'screen': 'list'}), {
      'route': '/',
      'screen': 'list',
      'state': {'n': 1},
    });
    expect((await h['state']!({'screen': 'x'}))['error'], 'invalid_params');
    snapshots.unregister('list');
    expect(snapshots.screens, isEmpty);
  });

  test('navigate goes to route and returns location', () async {
    expect(await h['navigate']!({'route': '/a'}), {'route': '/a'});
    expect((await h['navigate']!({'route': 'a'}))['error'], 'invalid_params');
    expect((await h['navigate']!({}))['error'], 'invalid_params');
  });

  test('errors returns captured errors and clears them', () async {
    sink.record(StateError('boom'), StackTrace.current, source: 'flutter');
    final first = await h['errors']!({});
    final list = first['errors']! as List;
    expect(list, hasLength(1));
    expect((list.single as Map)['error'], contains('boom'));
    expect((list.single as Map)['source'], 'flutter');
    expect(await h['errors']!({}), {'errors': <Object?>[]});
  });

  test('default data control is a no-op', () async {
    final c = container.read(debugDataControlProvider);
    await c.wipe();
    expect(await c.seed('x'), {'ids': <String>[]});
  });
}
