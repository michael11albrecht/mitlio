import 'dart:io';

import 'package:mitlio_drive/mitlio_drive.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

void main() {
  group('extensionName', () {
    test('adds the prefix to short names', () {
      expect(extensionName('ping'), 'ext.mitlio.ping');
    });

    test('keeps already qualified names', () {
      expect(extensionName('ext.mitlio.ping'), 'ext.mitlio.ping');
    });
  });

  test('webSocketUri converts the VM service http URI', () {
    expect(
      webSocketUri('http://127.0.0.1:1/abc=/'),
      'ws://127.0.0.1:1/abc=/ws',
    );
  });

  group('parseDriveArgs', () {
    test('defaults', () {
      final a = parseDriveArgs(['ping']);
      expect(a.extension, 'ext.mitlio.ping');
      expect(a.params, isEmpty);
      expect(a.uriFile, '.drive/uri');
      expect(a.timeout, const Duration(seconds: 10));
    });

    test('json params are stringified, options parsed', () {
      final a = parseDriveArgs([
        'seed',
        '{"scenario":"trip","n":3,"m":["a"]}',
        '--uri-file=x/uri',
        '--timeout',
        '3',
      ]);
      expect(a.params, {'scenario': 'trip', 'n': '3', 'm': '["a"]'});
      expect(a.uriFile, 'x/uri');
      expect(a.timeout, const Duration(seconds: 3));
    });

    test('rejects bad input', () {
      for (final bad in [
        <String>[],
        ['a', '{}', 'c'],
        ['a', 'nope'],
        ['a', '[1]'],
        ['a', '--timeout=0'],
        ['a', '--timeout=x'],
        ['a', '--bogus'],
      ]) {
        expect(
          () => parseDriveArgs(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  group('runDrive', () {
    late Directory tmp;
    late _FakeVm vm;
    late _Sink out;
    late _Sink err;
    late String uriFile;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('drive_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      uriFile = '${tmp.path}/uri';
      File(uriFile).writeAsStringSync('http://127.0.0.1:1/abc=/\n');
      vm = _FakeVm();
      out = _Sink();
      err = _Sink();
    });

    Future<int> run(List<String> args) => runDrive(
      [...args, '--uri-file=$uriFile'],
      out: out,
      err: err,
      connect: (uri) async {
        vm.connectedTo = uri;
        return vm;
      },
    );

    test('calls the main isolate and prints JSON only on stdout', () async {
      vm.result = {'version': '1', 'buildSha': 'dev'};
      expect(await run(['ping']), 0);
      expect(vm.connectedTo, 'http://127.0.0.1:1/abc=/');
      expect(vm.calls.single.$1, 'ext.mitlio.ping');
      expect(vm.calls.single.$2, 'iso-main');
      expect(vm.calls.single.$3, isEmpty);
      expect(out.text, '{"version":"1","buildSha":"dev"}\n');
      expect(err.text, isEmpty);
      expect(vm.disposed, isTrue);
    });

    test('passes params', () async {
      await run(['seed', '{"scenario":"trip"}']);
      expect(vm.calls.single.$3, {'scenario': 'trip'});
    });

    test('error JSON gives exit 1 with JSON on stdout', () async {
      vm.result = {'error': 'invalid_params', 'message': 'm'};
      expect(await run(['navigate']), 1);
      expect(out.text, contains('invalid_params'));
    });

    test('RPC error (unknown extension) gives exit 1', () async {
      vm.rpcError = RPCError('callServiceExtension', 113, 'Method not found');
      expect(await run(['nope']), 1);
      expect(out.text, contains('rpc_error'));
    });

    test('missing URI file gives exit 2', () async {
      File(uriFile).deleteSync();
      expect(await run(['ping']), 2);
      expect(out.text, isEmpty);
      expect(err.text, contains('connection error'));
    });

    test('connection failure gives exit 2', () async {
      final code = await runDrive(
        ['ping', '--uri-file=$uriFile'],
        out: out,
        err: err,
        connect: (_) async => throw const SocketException('refused'),
      );
      expect(code, 2);
    });

    test('usage error gives exit 64', () async {
      expect(await runDrive([], out: out, err: err), 64);
      expect(err.text, contains('usage'));
    });

    test('no isolates gives exit 2', () async {
      vm.isolates = [];
      expect(await run(['ping']), 2);
    });

    test('falls back to the first isolate when none is named main', () async {
      vm.isolates = [IsolateRef(id: 'i1', name: 'other')];
      await run(['ping']);
      expect(vm.calls.single.$2, 'i1');
    });
  });
}

class _Sink implements IOSink {
  final _b = StringBuffer();
  String get text => _b.toString();

  @override
  void writeln([Object? o = '']) => _b.writeln(o);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeVm extends Fake implements VmService {
  String? connectedTo;
  Map<String, Object?> result = {};
  RPCError? rpcError;
  bool disposed = false;
  List<IsolateRef> isolates = [
    IsolateRef(id: 'iso-other', name: 'x'),
    IsolateRef(id: 'iso-main', name: 'main'),
  ];
  final calls = <(String, String, Map<String, String>)>[];

  @override
  Future<VM> getVM() async => VM(isolates: isolates);

  @override
  Future<Response> callServiceExtension(
    String method, {
    String? isolateId,
    Map<String, dynamic>? args,
  }) async {
    calls.add((method, isolateId!, Map<String, String>.from(args ?? {})));
    if (rpcError != null) throw rpcError!;
    return Response.parse(result)!;
  }

  @override
  Future<void> dispose() async => disposed = true;
}
