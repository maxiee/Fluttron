import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../generate/client_service_generator.dart';
import '../generate/host_service_generator.dart';
import '../generate/model_generator.dart';
import '../generate/parsed_contract.dart';
import '../generate/service_contract_parser.dart';

/// Generates Host/Client/Model code from a Fluttron service contract.
///
/// Usage:
/// ```bash
/// fluttron generate services --contract path/to/service_contract.dart
///
/// # With custom output directories:
/// fluttron generate services \
///   --contract path/to/service_contract.dart \
///   --host-output host/lib/src/ \
///   --client-output client/lib/src/ \
///   --shared-output shared/lib/src/
///
/// # Preview without writing:
/// fluttron generate services --contract path/to/service_contract.dart --dry-run
/// ```
class GenerateServicesCommand extends Command<int> {
  @override
  String get name => 'services';

  @override
  String get description =>
      'Generate Host/Client/Model code from a Fluttron service contract.';

  GenerateServicesCommand() {
    argParser
      ..addOption(
        'contract',
        abbr: 'c',
        help: 'Path to the service contract Dart file.',
        valueHelp: 'path',
        mandatory: true,
      )
      ..addOption(
        'host-output',
        help: 'Output directory for host-side generated code.',
        valueHelp: 'path',
      )
      ..addOption(
        'client-output',
        help: 'Output directory for client-side generated code.',
        valueHelp: 'path',
      )
      ..addOption(
        'shared-output',
        help: 'Output directory for shared model generated code.',
        valueHelp: 'path',
      )
      ..addFlag(
        'dry-run',
        help: 'Preview generated files without writing to disk.',
        negatable: false,
      );
  }

  @override
  Future<int> run() async {
    final contractPath = argResults!['contract'] as String;
    final hostOutput = argResults!['host-output'] as String?;
    final clientOutput = argResults!['client-output'] as String?;
    final sharedOutput = argResults!['shared-output'] as String?;
    final dryRun = argResults!['dry-run'] as bool;

    // Validate contract file exists
    final contractFile = File(contractPath);
    if (!contractFile.existsSync()) {
      stderr.writeln('Error: Contract file not found: $contractPath');
      return 1;
    }

    // Parse the contract
    final parser = ServiceContractParser();
    final parsedFile = parser.parseFile(contractFile.absolute.path);

    // Report parse errors
    if (parsedFile.errors.isNotEmpty) {
      stderr.writeln('Parse errors:');
      for (final error in parsedFile.errors) {
        stderr.writeln('  - $error');
      }
      return 1;
    }

    // Check for contracts
    if (parsedFile.contracts.isEmpty) {
      stderr.writeln(
        'Error: No @FluttronServiceContract found in $contractPath',
      );
      return 1;
    }

    // Generate code for each contract
    for (final contract in parsedFile.contracts) {
      await _generateForContract(
        contract: contract,
        models: parsedFile.models,
        contractPath: contractPath,
        hostOutput: hostOutput,
        clientOutput: clientOutput,
        sharedOutput: sharedOutput,
        dryRun: dryRun,
      );
    }

    return 0;
  }

  Future<void> _generateForContract({
    required ParsedServiceContract contract,
    required List<ParsedModel> models,
    required String contractPath,
    String? hostOutput,
    String? clientOutput,
    String? sharedOutput,
    required bool dryRun,
  }) async {
    final contractFileName = p.basename(contractPath);
    final className = contract.className;
    final snakeCaseName = _toSnakeCase(className);

    // Generate host code
    final hostGenerator = HostServiceGenerator(sourceFile: contractFileName);
    final hostCode = hostGenerator.generate(contract);
    final hostFileName = '${snakeCaseName}_generated.dart';

    // Generate client code
    final clientGenerator = ClientServiceGenerator(
      sourceFile: contractFileName,
    );
    final clientCode = clientGenerator.generate(contract);
    final clientFileName = '${snakeCaseName}_client_generated.dart';

    // Generate model code
    final modelGenerator = ModelGenerator(sourceFile: contractFileName);
    final modelCodes = <String, String>{};
    for (final model in models) {
      final modelSnakeCase = _toSnakeCase(model.className);
      modelCodes['${modelSnakeCase}_generated.dart'] = modelGenerator.generate(
        model,
      );
    }

    if (dryRun) {
      _printDryRun(
        contract: contract,
        hostCode: hostCode,
        hostFileName: hostFileName,
        hostOutput: hostOutput,
        clientCode: clientCode,
        clientFileName: clientFileName,
        clientOutput: clientOutput,
        modelCodes: modelCodes,
        sharedOutput: sharedOutput,
      );
    } else {
      await _writeFiles(
        hostCode: hostCode,
        hostFileName: hostFileName,
        hostOutput: hostOutput,
        clientCode: clientCode,
        clientFileName: clientFileName,
        clientOutput: clientOutput,
        modelCodes: modelCodes,
        sharedOutput: sharedOutput,
        contract: contract,
      );
    }
  }

  void _printDryRun({
    required ParsedServiceContract contract,
    required String hostCode,
    required String hostFileName,
    required String? hostOutput,
    required String clientCode,
    required String clientFileName,
    required String? clientOutput,
    required Map<String, String> modelCodes,
    required String? sharedOutput,
  }) {
    stdout.writeln('=== DRY RUN - No files will be written ===');
    stdout.writeln('');

    // Host output
    final hostPath = hostOutput != null
        ? p.join(hostOutput, hostFileName)
        : hostFileName;
    stdout.writeln('--- HOST: $hostPath ---');
    stdout.writeln(hostCode);

    // Client output
    final clientPath = clientOutput != null
        ? p.join(clientOutput, clientFileName)
        : clientFileName;
    stdout.writeln('--- CLIENT: $clientPath ---');
    stdout.writeln(clientCode);

    // Model outputs
    for (final entry in modelCodes.entries) {
      final modelPath = sharedOutput != null
          ? p.join(sharedOutput, entry.key)
          : entry.key;
      stdout.writeln('--- MODEL: $modelPath ---');
      stdout.writeln(entry.value);
    }
  }

  Future<void> _writeFiles({
    required String hostCode,
    required String hostFileName,
    required String? hostOutput,
    required String clientCode,
    required String clientFileName,
    required String? clientOutput,
    required Map<String, String> modelCodes,
    required String? sharedOutput,
    required ParsedServiceContract contract,
  }) async {
    var filesWritten = 0;

    // Write host code
    final hostPath = hostOutput != null
        ? p.join(hostOutput, hostFileName)
        : hostFileName;
    await _writeFile(hostPath, hostCode);
    filesWritten++;
    stdout.writeln('Generated: $hostPath');

    // Write client code
    final clientPath = clientOutput != null
        ? p.join(clientOutput, clientFileName)
        : clientFileName;
    await _writeFile(clientPath, clientCode);
    filesWritten++;
    stdout.writeln('Generated: $clientPath');

    // Write model codes
    for (final entry in modelCodes.entries) {
      final modelPath = sharedOutput != null
          ? p.join(sharedOutput, entry.key)
          : entry.key;
      await _writeFile(modelPath, entry.value);
      filesWritten++;
      stdout.writeln('Generated: $modelPath');
    }

    stdout.writeln('');
    stdout.writeln('Generation complete: $filesWritten file(s) written.');
    stdout.writeln('');
    stdout.writeln('Next steps:');
    stdout.writeln(
      '  1. Create a concrete class extending ${contract.className}Base',
    );
    stdout.writeln('  2. Implement the abstract methods');
    stdout.writeln('  3. Register your service with ServiceRegistry');
  }

  Future<void> _writeFile(String path, String content) async {
    final file = File(path);

    // Create directories if they don't exist
    final parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }

    await file.writeAsString(content);
  }

  /// Converts a PascalCase string to snake_case.
  String _toSnakeCase(String input) {
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char.toLowerCase() != char) {
        if (i > 0) {
          buffer.write('_');
        }
        buffer.write(char.toLowerCase());
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
