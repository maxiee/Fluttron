import 'dart:io';

import 'package:fluttron_cli/fluttron_cli.dart';

Future<void> main(List<String> arguments) async {
  final exitCode = await runCli(arguments);
  exit(exitCode);
}
