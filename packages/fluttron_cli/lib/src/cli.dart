import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/build.dart';
import 'commands/create.dart';
import 'commands/run.dart';

Future<int> runCli(List<String> args) async {
  final runner =
      CommandRunner<int>('fluttron', 'Fluttron command-line interface.')
        ..addCommand(CreateCommand())
        ..addCommand(BuildCommand())
        ..addCommand(RunCommand());

  try {
    final result = await runner.run(args);
    return result ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    return 64;
  } catch (error) {
    stderr.writeln('Unexpected error: $error');
    return 1;
  }
}
