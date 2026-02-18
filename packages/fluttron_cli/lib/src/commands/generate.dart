import 'package:args/command_runner.dart';

import 'generate_services_command.dart';

/// Root command for code generation operations.
///
/// This command serves as a parent for generation subcommands.
/// Currently supports:
/// - `services`: Generate Host/Client/Model code from service contracts
class GenerateCommand extends Command<int> {
  @override
  String get name => 'generate';

  @override
  String get description => 'Generate code from Fluttron service contracts.';

  GenerateCommand() {
    addSubcommand(GenerateServicesCommand());
  }

  @override
  Future<int> run() async {
    // This shouldn't be called directly since we have subcommands
    printUsage();
    return 0;
  }
}
