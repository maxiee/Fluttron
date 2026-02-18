import 'dart:convert';
import 'dart:io';

import 'package:fluttron_cli/src/utils/host_service_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'host_service_manifest_test_',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void writeManifest(Map<String, dynamic> json) {
    final file = File(p.join(tempDir.path, HostServiceManifestLoader.fileName));
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
  }

  Map<String, dynamic> createValidManifest({String name = 'my_service'}) {
    return {
      'version': '1',
      'name': name,
      'namespace': name,
      'description': 'A custom service',
      'methods': [
        {
          'name': 'greet',
          'params': {
            'name': {'type': 'string', 'required': false},
          },
          'returns': {
            'message': {'type': 'string'},
          },
        },
      ],
    };
  }

  group('HostServiceManifestLoader', () {
    test('loads valid manifest', () {
      writeManifest(createValidManifest());

      final manifest = HostServiceManifestLoader.load(tempDir);

      expect(manifest.version, equals('1'));
      expect(manifest.name, equals('my_service'));
      expect(manifest.namespace, equals('my_service'));
      expect(manifest.methods, hasLength(1));
      expect(manifest.methods.first.name, equals('greet'));
      expect(manifest.methods.first.params['name']?.required, isFalse);
    });

    test('tryLoad returns null when manifest is missing', () {
      final manifest = HostServiceManifestLoader.tryLoad(tempDir);
      expect(manifest, isNull);
    });

    test('throws on invalid version', () {
      final manifest = createValidManifest()..['version'] = '2';
      writeManifest(manifest);

      expect(
        () => HostServiceManifestLoader.load(tempDir),
        throwsA(
          isA<HostServiceManifestException>().having(
            (e) => e.message,
            'message',
            contains('Invalid "version"'),
          ),
        ),
      );
    });

    test('throws on invalid snake_case name', () {
      writeManifest(createValidManifest(name: 'MyService'));

      expect(
        () => HostServiceManifestLoader.load(tempDir),
        throwsA(
          isA<HostServiceManifestException>().having(
            (e) => e.message,
            'message',
            contains('must be snake_case'),
          ),
        ),
      );
    });

    test('throws on empty methods', () {
      final manifest = createValidManifest()
        ..['methods'] = <Map<String, dynamic>>[];
      writeManifest(manifest);

      expect(
        () => HostServiceManifestLoader.load(tempDir),
        throwsA(
          isA<HostServiceManifestException>().having(
            (e) => e.message,
            'message',
            contains('Missing or empty "methods"'),
          ),
        ),
      );
    });

    test('throws on duplicate method names', () {
      final manifest = createValidManifest()
        ..['methods'] = [
          {
            'name': 'greet',
            'params': {
              'name': {'type': 'string', 'required': false},
            },
            'returns': {
              'message': {'type': 'string'},
            },
          },
          {
            'name': 'greet',
            'params': {
              'text': {'type': 'string', 'required': true},
            },
            'returns': {
              'text': {'type': 'string'},
            },
          },
        ];
      writeManifest(manifest);

      expect(
        () => HostServiceManifestLoader.load(tempDir),
        throwsA(
          isA<HostServiceManifestException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate method name'),
          ),
        ),
      );
    });

    test('throws when required flag is missing in params', () {
      final manifest = createValidManifest()
        ..['methods'] = [
          {
            'name': 'greet',
            'params': {
              'name': {'type': 'string'},
            },
            'returns': {
              'message': {'type': 'string'},
            },
          },
        ];
      writeManifest(manifest);

      expect(
        () => HostServiceManifestLoader.load(tempDir),
        throwsA(
          isA<HostServiceManifestException>().having(
            (e) => e.message,
            'message',
            contains('.required"'),
          ),
        ),
      );
    });
  });
}
