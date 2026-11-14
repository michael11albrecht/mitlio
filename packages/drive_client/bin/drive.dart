import 'dart:io';

import 'package:mitlio_drive/mitlio_drive.dart';

Future<void> main(List<String> args) async {
  exitCode = await runDrive(args, out: stdout, err: stderr);
}
