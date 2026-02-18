import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/fluttron_cli.dart';

void main() {
  late Directory tempDir;
  late String contractFixturePath;

  setUpAll(() async {
    // Find the project root by looking for packages directory
    var dir = Directory.current;
    Directory? foundProjectRoot;
    while (dir.path != dir.parent.path) {
      final packages = Directory(p.join(dir.path, 'packages'));
      if (await packages.exists()) {
        foundProjectRoot = dir;
        break;
      }
      dir = dir.parent;
    }

    // If not found from current directory, try relative path
    if (foundProjectRoot == null) {
      final currentDir = Directory.current;
      final projectRoot = currentDir.path.contains('packages/fluttron_cli')
          ? Directory(p.join(currentDir.path, '..', '..', '..'))
          : currentDir;
      foundProjectRoot = projectRoot;
    }

    final projectRootPath = foundProjectRoot.path;

    contractFixturePath = p.join(
      projectRootPath,
      'packages',
      'fluttron_shared',
      'test',
      'fixtures',
      'example_weather_contract.dart',
    );
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('generate_services_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('generate services command', () {
    test('returns error when contract file not found', () async {
      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        '/nonexistent/file.dart',
      ]);

      expect(exitCode, equals(1));
    });

    test('generates files with dry-run does not write to disk', () async {
      // Use temp directory to check that files are NOT created there
      final outputDir = p.join(tempDir.path, 'output');

      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        contractFixturePath,
        '--host-output',
        p.join(outputDir, 'host'),
        '--client-output',
        p.join(outputDir, 'client'),
        '--shared-output',
        p.join(outputDir, 'shared'),
        '--dry-run',
      ]);

      expect(exitCode, equals(0));

      // Verify no files were created in the output directory
      expect(
        await File(
          p.join(outputDir, 'weather_service_generated.dart'),
        ).exists(),
        isFalse,
      );
    });

    test('generates host, client, and model files', () async {
      final hostOutput = p.join(tempDir.path, 'host');
      final clientOutput = p.join(tempDir.path, 'client');
      final sharedOutput = p.join(tempDir.path, 'shared');

      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        contractFixturePath,
        '--host-output',
        hostOutput,
        '--client-output',
        clientOutput,
        '--shared-output',
        sharedOutput,
      ]);

      expect(exitCode, equals(0));

      // Verify host file was created
      final hostFile = File(
        p.join(hostOutput, 'weather_service_generated.dart'),
      );
      expect(await hostFile.exists(), isTrue);
      final hostContent = await hostFile.readAsString();
      expect(hostContent, contains('abstract class WeatherServiceBase'));
      expect(hostContent, contains("String get namespace => 'weather'"));
      expect(hostContent, contains('case \'getCurrentWeather\''));
      expect(hostContent, contains('case \'getForecast\''));
      expect(hostContent, contains('case \'isAvailable\''));

      // Verify client file was created
      final clientFile = File(
        p.join(clientOutput, 'weather_service_client_generated.dart'),
      );
      expect(await clientFile.exists(), isTrue);
      final clientContent = await clientFile.readAsString();
      expect(clientContent, contains('class WeatherServiceClient'));
      expect(clientContent, contains("'weather.getCurrentWeather'"));
      expect(clientContent, contains("'weather.getForecast'"));
      expect(clientContent, contains("'weather.isAvailable'"));

      // Verify model files were created
      final weatherInfoFile = File(
        p.join(sharedOutput, 'weather_info_generated.dart'),
      );
      expect(await weatherInfoFile.exists(), isTrue);
      final weatherInfoContent = await weatherInfoFile.readAsString();
      expect(weatherInfoContent, contains('class WeatherInfo'));
      expect(weatherInfoContent, contains('factory WeatherInfo.fromMap'));
      expect(weatherInfoContent, contains('Map<String, dynamic> toMap()'));

      final weatherForecastFile = File(
        p.join(sharedOutput, 'weather_forecast_generated.dart'),
      );
      expect(await weatherForecastFile.exists(), isTrue);
      final weatherForecastContent = await weatherForecastFile.readAsString();
      expect(weatherForecastContent, contains('class WeatherForecast'));
    });

    test('generated host code has proper structure', () async {
      final hostOutput = p.join(tempDir.path, 'host');
      final clientOutput = p.join(tempDir.path, 'client');
      final sharedOutput = p.join(tempDir.path, 'shared');

      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        contractFixturePath,
        '--host-output',
        hostOutput,
        '--client-output',
        clientOutput,
        '--shared-output',
        sharedOutput,
      ]);

      expect(exitCode, equals(0));

      final hostFile = File(
        p.join(hostOutput, 'weather_service_generated.dart'),
      );
      final content = await hostFile.readAsString();

      // Check header
      expect(content, contains('// GENERATED CODE — DO NOT MODIFY BY HAND'));
      expect(content, contains('// Generated by: fluttron generate services'));

      // Check imports
      expect(
        content,
        contains("import 'package:fluttron_host/fluttron_host.dart'"),
      );
      expect(
        content,
        contains("import 'package:fluttron_shared/fluttron_shared.dart'"),
      );

      // Check routing structure
      expect(content, contains('switch (method)'));
      expect(content, contains('throw FluttronError'));

      // Check abstract methods
      expect(
        content,
        contains('Future<WeatherInfo> getCurrentWeather(String city)'),
      );
      expect(
        content,
        contains(
          'Future<List<WeatherForecast>> getForecast(String city, {int days = 5})',
        ),
      );
      expect(content, contains('Future<bool> isAvailable()'));
    });

    test('generated client code has proper structure', () async {
      final clientOutput = p.join(tempDir.path, 'client');
      final hostOutput = p.join(tempDir.path, 'host');
      final sharedOutput = p.join(tempDir.path, 'shared');

      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        contractFixturePath,
        '--host-output',
        hostOutput,
        '--client-output',
        clientOutput,
        '--shared-output',
        sharedOutput,
      ]);

      expect(exitCode, equals(0));

      final clientFile = File(
        p.join(clientOutput, 'weather_service_client_generated.dart'),
      );
      final content = await clientFile.readAsString();

      // Check header
      expect(content, contains('// GENERATED CODE — DO NOT MODIFY BY HAND'));

      // Check imports
      expect(
        content,
        contains("import 'package:fluttron_ui/fluttron_ui.dart'"),
      );

      // Check class structure
      expect(content, contains('class WeatherServiceClient'));
      expect(content, contains('WeatherServiceClient(this._client)'));
      expect(content, contains('final FluttronClient _client'));

      // Check method calls (verify method names are present)
      expect(content, contains('weather.getCurrentWeather'));
      expect(content, contains('weather.getForecast'));
      expect(content, contains('weather.isAvailable'));
      expect(content, contains('_client.invoke'));
    });

    test('generated model code has serialization', () async {
      final sharedOutput = p.join(tempDir.path, 'shared');
      final hostOutput = p.join(tempDir.path, 'host');
      final clientOutput = p.join(tempDir.path, 'client');

      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        contractFixturePath,
        '--host-output',
        hostOutput,
        '--client-output',
        clientOutput,
        '--shared-output',
        sharedOutput,
      ]);

      expect(exitCode, equals(0));

      final modelFile = File(
        p.join(sharedOutput, 'weather_info_generated.dart'),
      );
      final content = await modelFile.readAsString();

      // Check class structure
      expect(content, contains('class WeatherInfo'));
      expect(content, contains('const WeatherInfo({'));
      expect(content, contains('required this.city'));
      expect(content, contains('required this.temperature'));

      // Check fromMap
      expect(content, contains('factory WeatherInfo.fromMap'));
      expect(content, contains("map['city'] as String"));
      expect(content, contains("(map['temperature'] as num).toDouble()"));
      expect(content, contains('DateTime.parse'));

      // Check toMap
      expect(content, contains('Map<String, dynamic> toMap()'));
      expect(content, contains('timestamp.toIso8601String()'));
    });

    test('creates output directories if they do not exist', () async {
      final hostOutput = p.join(tempDir.path, 'deeply', 'nested', 'host');
      final clientOutput = p.join(tempDir.path, 'deeply', 'nested', 'client');
      final sharedOutput = p.join(tempDir.path, 'deeply', 'nested', 'shared');

      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        contractFixturePath,
        '--host-output',
        hostOutput,
        '--client-output',
        clientOutput,
        '--shared-output',
        sharedOutput,
      ]);

      expect(exitCode, equals(0));

      final hostFile = File(
        p.join(hostOutput, 'weather_service_generated.dart'),
      );
      expect(await hostFile.exists(), isTrue);
    });

    test('handles contract with no models', () async {
      // Create a simple contract without models
      final contractContent = '''
import 'package:fluttron_shared/fluttron_shared.dart';

@FluttronServiceContract(namespace: 'simple')
abstract class SimpleService {
  Future<String> ping();
}
''';
      final simpleContract = File(p.join(tempDir.path, 'simple_contract.dart'));
      await simpleContract.writeAsString(contractContent);

      final outputDir = p.join(tempDir.path, 'output');

      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        simpleContract.path,
        '--host-output',
        outputDir,
        '--client-output',
        outputDir,
      ]);

      expect(exitCode, equals(0));

      // Should still generate host and client files
      expect(
        await File(p.join(outputDir, 'simple_service_generated.dart')).exists(),
        isTrue,
      );
      expect(
        await File(
          p.join(outputDir, 'simple_service_client_generated.dart'),
        ).exists(),
        isTrue,
      );
    });

    test('returns error for invalid contract method signature', () async {
      final invalidContract = File(
        p.join(tempDir.path, 'invalid_contract.dart'),
      );
      final outputDir = p.join(tempDir.path, 'output');
      await invalidContract.writeAsString('''
import 'package:fluttron_shared/fluttron_shared.dart';

@FluttronServiceContract(namespace: 'invalid')
abstract class InvalidService {
  String ping();
}
''');

      final exitCode = await runCli([
        'generate',
        'services',
        '--contract',
        invalidContract.path,
        '--host-output',
        outputDir,
      ]);

      expect(exitCode, equals(1));
      expect(
        await File(
          p.join(outputDir, 'invalid_service_generated.dart'),
        ).exists(),
        isFalse,
      );
    });
  });
}
