import 'dart:io';

import 'package:mitlio_tooling/mitlio_tooling.dart';

Future<void> main(List<String> args) async {
  exitCode = await runDepsPolicy(args, out: stdout, err: stderr);
}
