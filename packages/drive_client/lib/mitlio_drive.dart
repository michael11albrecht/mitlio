/// Client for the `ext.mitlio.*` DebugDrive protocol (docs/drive-protocol.md).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Prefix of every DebugDrive service extension.
const extensionPrefix = 'ext.mitlio.';

/// Exit codes of the `drive` CLI.
const exitOk = 0;
const exitExtensionError = 1;
const exitConnectionError = 2;
const exitUsage = 64;

/// Returns the fully qualified extension name for [method].
String extensionName(String method) =>
    method.startsWith(extensionPrefix) ? method : '$extensionPrefix$method';

/// Parsed command line of `drive <ext> [json-params] [options]`.
class DriveArgs {
  const DriveArgs({
    required this.extension,
    required this.params,
    required this.uriFile,
    required this.timeout,
  });

  final String extension;

  /// Extension arguments; the VM service only transports string values.
  final Map<String, String> params;
  final String uriFile;
  final Duration timeout;
}

final _parser = ArgParser()
  ..addOption(
    'uri-file',
    defaultsTo: '.drive/uri',
    help: 'File with the VM service URI (flutter run --vmservice-out-file).',
  )
  ..addOption('timeout', defaultsTo: '10', help: 'Seconds to wait.');

String get usage =>
    'usage: drive <extension> [json-params] [options]\n${_parser.usage}';

/// Parses [args]; throws [FormatException] on invalid input.
DriveArgs parseDriveArgs(List<String> args) {
  final ArgResults r;
  try {
    r = _parser.parse(args);
  } on ArgParserException catch (e) {
    throw FormatException(e.message);
  }
  if (r.rest.isEmpty || r.rest.length > 2) {
    throw const FormatException('expected <extension> [json-params]');
  }
  final seconds = int.tryParse(r['timeout'] as String);
  if (seconds == null || seconds <= 0) {
    throw const FormatException('--timeout must be a positive integer');
  }
  return DriveArgs(
    extension: extensionName(r.rest.first),
    params: r.rest.length == 2 ? _parseParams(r.rest[1]) : const {},
    uriFile: r['uri-file'] as String,
    timeout: Duration(seconds: seconds),
  );
}

Map<String, String> _parseParams(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (e) {
    throw FormatException('json-params is not valid JSON: ${e.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('json-params must be a JSON object');
  }
  return {
    for (final e in decoded.entries)
      e.key: e.value is String ? e.value! as String : jsonEncode(e.value),
  };
}

/// Calls [extension] on the main isolate and returns the decoded JSON result.
///
/// Throws [RPCError] when the VM rejects the call (e.g. unknown extension).
Future<Map<String, Object?>> callExtension(
  VmService service,
  String extension,
  Map<String, String> params,
) async {
  final vm = await service.getVM();
  final isolates = vm.isolates ?? const <IsolateRef>[];
  if (isolates.isEmpty) throw StateError('no isolates running');
  final main = isolates.firstWhere(
    (i) => i.name == 'main',
    orElse: () => isolates.first,
  );
  final response = await service.callServiceExtension(
    extension,
    isolateId: main.id,
    args: params,
  );
  return response.json ?? const {};
}

/// Maps the extension JSON to an exit code (error JSON -> 1).
int exitCodeFor(Map<String, Object?> result) =>
    result.containsKey('error') ? exitExtensionError : exitOk;

/// Connects to the VM service at [uri] (http or ws form).
typedef VmConnect = Future<VmService> Function(String uri);

/// WebSocket form of the URI that `--vmservice-out-file` wrote (http://host:port/token=/).
String webSocketUri(String uri) =>
    convertToWebSocketUrl(serviceProtocolUrl: Uri.parse(uri)).toString();

/// Default [VmConnect].
Future<VmService> connectToVm(String uri) =>
    vmServiceConnectUri(webSocketUri(uri));

/// CLI entry point. JSON goes to [out] only; diagnostics go to [err].
Future<int> runDrive(
  List<String> args, {
  required IOSink out,
  required IOSink err,
  VmConnect connect = connectToVm,
}) async {
  final DriveArgs parsed;
  try {
    parsed = parseDriveArgs(args);
  } on FormatException catch (e) {
    err.writeln('${e.message}\n$usage');
    return exitUsage;
  }
  VmService? service;
  try {
    final file = File(parsed.uriFile);
    if (!file.existsSync()) {
      throw FileSystemException('URI file not found', parsed.uriFile);
    }
    final uri = file.readAsStringSync().trim();
    service = await connect(uri).timeout(parsed.timeout);
    final result = await callExtension(
      service,
      parsed.extension,
      parsed.params,
    ).timeout(parsed.timeout);
    out.writeln(jsonEncode(result));
    return exitCodeFor(result);
  } on RPCError catch (e) {
    out.writeln(jsonEncode({'error': 'rpc_error', 'message': e.message}));
    return exitExtensionError;
  } on Object catch (e) {
    err.writeln('connection error: $e');
    return exitConnectionError;
  } finally {
    await service?.dispose();
  }
}
