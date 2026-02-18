import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'package:fluttron_cli/src/generate/host_service_generator.dart';
import 'package:fluttron_cli/src/generate/parsed_contract.dart';
import 'package:fluttron_cli/src/generate/service_contract_parser.dart';

void main() {
  late ServiceContractParser parser;
  late HostServiceGenerator generator;

  setUp(() {
    parser = ServiceContractParser();
    generator = const HostServiceGenerator(
      generatedBy: 'test',
      sourceFile: 'test_contract.dart',
    );
  });

  group('HostServiceGenerator integration', () {
    test('generates valid Dart code for test_service_contract.dart', () async {
      // Parse the fixture file
      final fixturePath = p.join(
        Directory.current.path,
        'test/src/generate/fixtures/test_service_contract.dart',
      );
      final result = parser.parseFile(fixturePath);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parse errors: ${result.errors}',
      );
      expect(result.contracts, hasLength(1));

      final contract = result.contracts.first;
      expect(contract.className, equals('TestService'));
      expect(contract.namespace, equals('test_service'));
      expect(contract.methods.length, greaterThan(10));

      // Generate code
      final generatedCode = generator.generate(contract);

      // Write to a temp file for syntax validation
      final tempDir = Directory.systemTemp.createTempSync('host_gen_test_');
      try {
        final tempFile = File(
          p.join(tempDir.path, 'test_service_generated.dart'),
        );
        await tempFile.writeAsString(generatedCode);

        // Verify the file was written
        expect(await tempFile.exists(), isTrue);

        // Verify it contains expected structure
        expect(
          generatedCode,
          contains('abstract class TestServiceBase extends FluttronService'),
        );
        expect(
          generatedCode,
          contains("String get namespace => 'test_service';"),
        );
        expect(generatedCode, contains('switch (method)'));

        // Verify all methods have case entries
        for (final method in contract.methods) {
          expect(generatedCode, contains("case '${method.name}':"));
        }

        // Verify helper methods are generated (only those needed based on required params)
        expect(generatedCode, contains('_requireString'));
        expect(generatedCode, contains('_requireInt'));
        expect(generatedCode, contains('_requireDouble'));
        // _requireBool is NOT generated because there are no required bool params
        expect(generatedCode, contains('_requireList'));
        expect(generatedCode, contains('_requireMap'));
        expect(generatedCode, contains('_requireDateTime'));

        // Verify abstract method declarations
        for (final method in contract.methods) {
          expect(
            generatedCode,
            contains('/// Override to implement: ${method.name}.'),
          );
        }

        // Regression checks: nullable signature preservation + typed list extraction + DateTime serialization
        expect(
          generatedCode,
          contains('Future<void> nullableParam(String? optionalName);'),
        );
        expect(
          generatedCode,
          contains(
            "final ids = (_requireList(params, 'ids') as List).map((e) => e as int).toList();",
          ),
        );
        expect(
          generatedCode,
          contains("return {'result': result.toIso8601String()};"),
        );
      } finally {
        // Cleanup
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {
          // Ignore cleanup errors
        }
      }
    });

    test('generates valid code for minimal contract', () {
      final contract = ParsedServiceContract(
        className: 'SimpleService',
        namespace: 'simple',
        methods: [
          ParsedMethod(
            name: 'ping',
            parameters: [],
            returnType: const ParsedType(
              displayName: 'Future<bool>',
              isNullable: false,
              typeArguments: [
                ParsedType(displayName: 'bool', isNullable: false),
              ],
            ),
          ),
        ],
      );

      final code = generator.generate(contract);

      // Basic structure checks
      expect(
        code,
        contains('abstract class SimpleServiceBase extends FluttronService'),
      );
      expect(code, contains("String get namespace => 'simple';"));
      expect(code, contains("case 'ping':"));
      expect(code, contains('Future<bool> ping();'));

      // No parameter helpers should be generated for a method with no params
      expect(code, isNot(contains('_requireString')));
      expect(code, isNot(contains('_requireInt')));
    });

    test('generates proper error handling for missing params', () {
      final contract = ParsedServiceContract(
        className: 'TestService',
        namespace: 'test',
        methods: [
          ParsedMethod(
            name: 'greet',
            parameters: [
              ParsedParameter(
                name: 'name',
                type: const ParsedType(
                  displayName: 'String',
                  isNullable: false,
                ),
                isRequired: true,
                isNamed: false,
              ),
            ],
            returnType: const ParsedType(
              displayName: 'Future<String>',
              isNullable: false,
              typeArguments: [
                ParsedType(displayName: 'String', isNullable: false),
              ],
            ),
          ),
        ],
      );

      final code = generator.generate(contract);

      // Check for FluttronError usage
      expect(code, contains('FluttronError'));
      expect(code, contains("'METHOD_NOT_FOUND'"));
      expect(code, contains("'BAD_PARAMS'"));
    });

    test('handles complex WeatherService-like contract', () {
      final contract = ParsedServiceContract(
        className: 'WeatherService',
        namespace: 'weather',
        methods: [
          ParsedMethod(
            name: 'getCurrentWeather',
            parameters: [
              ParsedParameter(
                name: 'city',
                type: const ParsedType(
                  displayName: 'String',
                  isNullable: false,
                ),
                isRequired: true,
                isNamed: false,
              ),
            ],
            returnType: const ParsedType(
              displayName: 'Future<WeatherInfo>',
              isNullable: false,
              typeArguments: [
                ParsedType(displayName: 'WeatherInfo', isNullable: false),
              ],
            ),
          ),
          ParsedMethod(
            name: 'getForecast',
            parameters: [
              ParsedParameter(
                name: 'city',
                type: const ParsedType(
                  displayName: 'String',
                  isNullable: false,
                ),
                isRequired: true,
                isNamed: false,
              ),
              ParsedParameter(
                name: 'days',
                type: const ParsedType(displayName: 'int', isNullable: false),
                isRequired: false,
                isNamed: true,
                defaultValue: '5',
              ),
            ],
            returnType: const ParsedType(
              displayName: 'Future<List<WeatherForecast>>',
              isNullable: false,
              typeArguments: [
                ParsedType(
                  displayName: 'List<WeatherForecast>',
                  isNullable: false,
                  typeArguments: [
                    ParsedType(
                      displayName: 'WeatherForecast',
                      isNullable: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          ParsedMethod(
            name: 'isAvailable',
            parameters: [],
            returnType: const ParsedType(
              displayName: 'Future<bool>',
              isNullable: false,
              typeArguments: [
                ParsedType(displayName: 'bool', isNullable: false),
              ],
            ),
          ),
        ],
      );

      final code = generator.generate(contract);

      // Check structure
      expect(
        code,
        contains('abstract class WeatherServiceBase extends FluttronService'),
      );
      expect(code, contains("String get namespace => 'weather';"));

      // Check all methods are present
      expect(code, contains("case 'getCurrentWeather':"));
      expect(code, contains("case 'getForecast':"));
      expect(code, contains("case 'isAvailable':"));

      // Check parameter handling
      expect(code, contains("final city = _requireString(params, 'city');"));
      expect(
        code,
        contains(
          "final days = params['days'] == null ? 5 : params['days'] as int;",
        ),
      );

      // Check return handling
      expect(code, contains('return result.toMap();')); // WeatherInfo model
      expect(
        code,
        contains('return result.map((e) => e.toMap()).toList();'),
      ); // List<WeatherForecast>
      expect(code, contains("return {'result': result};")); // bool

      // Check abstract method signatures
      expect(
        code,
        contains('Future<WeatherInfo> getCurrentWeather(String city);'),
      );
      expect(
        code,
        contains(
          'Future<List<WeatherForecast>> getForecast(String city, {int days = 5});',
        ),
      );
      expect(code, contains('Future<bool> isAvailable();'));
    });
  });
}
