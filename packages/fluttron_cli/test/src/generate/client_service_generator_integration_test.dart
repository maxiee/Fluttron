import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'package:fluttron_cli/src/generate/client_service_generator.dart';
import 'package:fluttron_cli/src/generate/parsed_contract.dart';
import 'package:fluttron_cli/src/generate/service_contract_parser.dart';

void main() {
  late ServiceContractParser parser;
  late ClientServiceGenerator generator;

  setUp(() {
    parser = ServiceContractParser();
    generator = const ClientServiceGenerator(
      generatedBy: 'test',
      sourceFile: 'test_contract.dart',
    );
  });

  group('ClientServiceGenerator integration', () {
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
      final tempDir = Directory.systemTemp.createTempSync('client_gen_test_');
      try {
        final tempFile = File(
          p.join(tempDir.path, 'test_service_client_generated.dart'),
        );
        await tempFile.writeAsString(generatedCode);

        // Verify the file was written
        expect(await tempFile.exists(), isTrue);

        // Verify it contains expected structure
        expect(generatedCode, contains('class TestServiceClient {'));
        expect(generatedCode, contains('TestServiceClient(this._client);'));
        expect(generatedCode, contains('final FluttronClient _client;'));

        // Verify all methods are present
        for (final method in contract.methods) {
          expect(
            generatedCode,
            contains('Future<'),
            reason: 'Method ${method.name} should have Future return type',
          );
        }

        // Verify invoke calls for each method
        expect(generatedCode, contains("'test_service.noParams'"));
        expect(generatedCode, contains("'test_service.singleRequired'"));
        expect(generatedCode, contains("'test_service.multipleRequired'"));
        expect(generatedCode, contains("'test_service.withDefaultValue'"));

        // Verify parameter handling for named params with defaults
        expect(generatedCode, contains("{int count = 5}"));

        // Verify return deserialization patterns
        expect(generatedCode, contains("result['result'] as bool"));
        expect(generatedCode, contains("result['result'] as String"));
        expect(generatedCode, contains("result['result'] as int"));
        expect(generatedCode, contains('.fromMap(Map<String, dynamic>.from'));
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
      expect(code, contains('class SimpleServiceClient {'));
      expect(code, contains('SimpleServiceClient(this._client);'));
      expect(code, contains('Future<bool> ping() async {'));
      expect(code, contains("await _client.invoke('simple.ping', {});"));
      expect(code, contains("return result['result'] as bool;"));
    });

    test('generates proper parameter map for complex method', () {
      final contract = ParsedServiceContract(
        className: 'TestService',
        namespace: 'test',
        methods: [
          ParsedMethod(
            name: 'search',
            parameters: [
              ParsedParameter(
                name: 'query',
                type: const ParsedType(
                  displayName: 'String',
                  isNullable: false,
                ),
                isRequired: true,
                isNamed: false,
              ),
              ParsedParameter(
                name: 'limit',
                type: const ParsedType(displayName: 'int', isNullable: false),
                isRequired: false,
                isNamed: true,
                defaultValue: '10',
              ),
              ParsedParameter(
                name: 'filter',
                type: const ParsedType(
                  displayName: 'String?',
                  isNullable: true,
                ),
                isRequired: false,
                isNamed: true,
              ),
            ],
            returnType: const ParsedType(
              displayName: 'Future<List<String>>',
              isNullable: false,
              typeArguments: [
                ParsedType(
                  displayName: 'List<String>',
                  isNullable: false,
                  typeArguments: [
                    ParsedType(displayName: 'String', isNullable: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

      final code = generator.generate(contract);

      // Check method signature
      expect(
        code,
        contains(
          "Future<List<String>> search(String query, {int limit = 10, String? filter}) async {",
        ),
      );

      // Check params map - required positional always included
      expect(code, contains("'query': query,"));
      // Named with default always included
      expect(code, contains("'limit': limit,"));
      // Nullable named only included if not null
      expect(code, contains("if (filter != null) 'filter': filter,"));
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

      // Check class declaration
      expect(code, contains('class WeatherServiceClient {'));
      expect(
        code,
        contains('/// Type-safe client for the weather host service.'),
      );

      // Check constructor
      expect(code, contains('WeatherServiceClient(this._client);'));

      // Check method signatures
      expect(
        code,
        contains('Future<WeatherInfo> getCurrentWeather(String city) async {'),
      );
      expect(
        code,
        contains(
          'Future<List<WeatherForecast>> getForecast(String city, {int days = 5}) async {',
        ),
      );
      expect(code, contains('Future<bool> isAvailable() async {'));

      // Check invoke calls with correct namespace.method
      expect(code, contains("'weather.getCurrentWeather'"));
      expect(code, contains("'weather.getForecast'"));
      expect(code, contains("'weather.isAvailable'"));

      // Check parameter map construction
      expect(code, contains("'city': city,"));
      expect(code, contains("'days': days,"));

      // Check return deserialization
      expect(
        code,
        contains(
          'return WeatherInfo.fromMap(Map<String, dynamic>.from(result as Map));',
        ),
      );
      expect(
        code,
        contains(
          '.map((e) => WeatherForecast.fromMap(Map<String, dynamic>.from(e as Map)))',
        ),
      );
      expect(code, contains("return result['result'] as bool;"));
    });
  });
}
