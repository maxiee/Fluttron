import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/build.dart';
import 'commands/create.dart';
import 'commands/generate.dart';
import 'commands/package.dart';
import 'commands/packages.dart';
import 'commands/run.dart';
import 'version.dart';

Future<int> runCli(List<String> args) async {
  if (args.contains('--version') || args.contains('-v')) {
    stdout.writeln(fluttronVersion);
    return 0;
  }

  final runner =
      CommandRunner<int>('fluttron', 'Fluttron command-line interface.')
        ..addCommand(CreateCommand())
        ..addCommand(BuildCommand())
        ..addCommand(RunCommand())
        ..addCommand(PackagesCommand())
        ..addCommand(GenerateCommand())
        ..addCommand(PackageCommand());

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
