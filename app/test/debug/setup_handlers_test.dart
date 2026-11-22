import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/setup.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';

import '../core/ui/setup_flow/setup_flow_fixtures.dart';

void main() {
  late FakeSetupStateRepository repo;

  Map<String, DriveHandler> launch() {
    final container = containerOn(
      repo,
      extra: [
        setupFlowConfigsProvider.overrideWithValue({'demo': demoFlow}),
      ],
    );
    addTearDown(container.dispose);
    return setupDriveHandlers(container);
  }

  setUp(() => repo = FakeSetupStateRepository());

  test('state of a fresh flow', () async {
    final r = await launch()['setup.state']!({'flowId': 'demo'});
    expect(r, {
      'flowId': 'demo',
      'status': 'ready',
      'step': 'name',
      'stepIndex': 0,
      'total': 4,
      'finished': false,
      'answers': <String, Object?>{},
      'skipped': <String>[],
      'canGoBack': false,
      'canSkip': false,
    });
  });

  test('a flow id with a scope drives its own copy of the flow', () async {
    final h = launch();
    var r = await h['setup.next']!({'flowId': 'demo:g1', 'answer': 'Anna'});
    expect(r['flowId'], 'demo:g1');
    expect(r['answers'], {'name': 'Anna'});
    r = await h['setup.state']!({'flowId': 'demo:g2'});
    expect(r['answers'], <String, Object?>{}, reason: 'other scope');
    r = await h['setup.state']!({'flowId': 'demo'});
    expect(r['answers'], <String, Object?>{}, reason: 'unscoped');
    r = await h['setup.state']!({'flowId': 'nope:g1'});
    expect(r['error'], 'not_found');
  });

  test('next, skip and back drive the flow and return the state', () async {
    final h = launch();
    var r = await h['setup.next']!({'flowId': 'demo', 'answer': 'Anna'});
    expect(r['step'], 'paypal');
    expect(r['answers'], {'name': 'Anna'});
    r = await h['setup.next']!({'flowId': 'demo', 'answer': 'true'});
    expect(r['answers'], {'name': 'Anna', 'paypal': true});
    r = await h['setup.skip']!({'flowId': 'demo'});
    expect(r['step'], 'iban');
    expect(r['skipped'], ['handle']);
    r = await h['setup.back']!({'flowId': 'demo'});
    expect(r['step'], 'handle');
    r = await h['setup.skip']!({'flowId': 'demo'});
    r = await h['setup.skip']!({'flowId': 'demo'});
    expect((r['finished'], r['step']), (true, null));
  });

  test('resumes after a restart', () async {
    await launch()['setup.next']!({'flowId': 'demo', 'answer': 'Anna'});
    final r = await launch()['setup.state']!({'flowId': 'demo'});
    expect(r['step'], 'paypal');
  });

  test('a missing flowId is invalid_params', () async {
    expect((await launch()['setup.state']!({}))['error'], 'invalid_params');
  });

  test('an unknown flow is not_found', () async {
    final r = await launch()['setup.next']!({'flowId': 'nope'});
    expect(r['error'], 'not_found');
  });

  test('a required step without answer is invalid_params', () async {
    final h = launch();
    expect(
      (await h['setup.next']!({'flowId': 'demo'}))['error'],
      'invalid_params',
    );
    expect(
      (await h['setup.skip']!({'flowId': 'demo'}))['error'],
      'invalid_params',
    );
  });

  test('back on the first step is a conflict', () async {
    final r = await launch()['setup.back']!({'flowId': 'demo'});
    expect(r['error'], 'conflict');
  });

  test('a failing save is internal and nothing moves', () async {
    final h = launch();
    repo.failSaveWith = const Storage('full');
    final r = await h['setup.next']!({'flowId': 'demo', 'answer': 'Anna'});
    expect(r['error'], 'internal');
    repo.failSaveWith = null;
    expect((await h['setup.state']!({'flowId': 'demo'}))['step'], 'name');
  });

  test('a failing read shows as status failed', () async {
    repo.failLoadWith = const Storage('disk');
    final r = await launch()['setup.state']!({'flowId': 'demo'});
    expect(r['status'], 'failed');
  });
}
