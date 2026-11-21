import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.setup.state|next|skip|back` (keys without the `ext.mitlio.`
/// prefix): the commands a guided setup flow's screens use (PU-T05). Param
/// `flowId` names the flow; flows are registered in
/// `setupFlowConfigsProvider`.
Map<String, DriveHandler> setupDriveHandlers(ProviderContainer c) {
  Future<DriveResult> drive(
    Map<String, String> p,
    Future<RepoResult<void>>? Function(SetupFlowViewModel vm) command,
  ) async {
    final flowId = p['flowId'];
    if (flowId == null) return invalidParams('need flowId');
    final config = c.read(setupFlowConfigsProvider)[flowId];
    if (config == null) return driveError(NotFound('setup flow', flowId));
    final vm = c.read(setupFlowViewModelProvider(config).notifier);
    await vm.restoring;
    if (await command(vm) case Err(:final error)) return driveError(error);
    return _snapshot(c.read(setupFlowViewModelProvider(config)));
  }

  return {
    'setup.state': (p) => drive(p, (_) => null),
    'setup.next': (p) =>
        drive(p, (vm) => vm.next(answer: _decode(p['answer']))),
    'setup.skip': (p) => drive(p, (vm) => vm.skip()),
    'setup.back': (p) => drive(p, (vm) => vm.back()),
  };
}

/// Params arrive as strings; the client JSON-encodes non-strings, so `true`
/// and `7` are decoded and anything else stays text.
Object? _decode(String? raw) {
  if (raw == null) return null;
  try {
    return jsonDecode(raw);
  } on FormatException {
    return raw;
  }
}

DriveResult _snapshot(SetupFlowState s) => {
  'flowId': s.config.id,
  'status': s.status.name,
  'step': s.step?.id,
  'stepIndex': s.stepIndex,
  'total': s.total,
  'finished': s.finished,
  'answers': s.answers,
  'skipped': s.skipped,
  'canGoBack': s.canGoBack,
  'canSkip': s.canSkip,
};
