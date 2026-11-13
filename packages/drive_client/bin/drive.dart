import 'dart:io';

import 'package:mitlio_drive/mitlio_drive.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: drive <extension> [json-params]');
    exitCode = 64;
    return;
  }
  final name = extensionName(args.first);
  stderr.writeln('DebugDrive client not implemented yet (P3-T04): $name');
  exitCode = 69;
}
