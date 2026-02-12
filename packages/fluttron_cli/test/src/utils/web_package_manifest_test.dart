import 'dart:convert';
import 'dart:io';

import 'package:fluttron_cli/src/utils/web_package_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('web_package_manifest_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('WebPackageManifest model', () {
    test('fromJson parses valid manifest', () {
      final json = {
        'version': '1',
        'viewFactories': [
          {
            'type': 'milkdown.editor',
            'jsFactoryName': 'fluttronCreateMilkdownEditorView',
            'description': 'Milkdown editor',
          },
        ],
        'assets': {
          'js': ['web/ext/main.js'],
          'css': ['web/ext/main.css'],
        },
        'events': [
          {
            'name': 'fluttron.milkdown.editor.change',
            'direction': 'js_to_dart',
            'payloadType': '{ markdown: string }',
          },
        ],
      };

      final manifest = WebPackageManifest.fromJson(json);

      expect(manifest.version, equals('1'));
      expect(manifest.viewFactories, hasLength(1));
      expect(manifest.viewFactories[0].type, equals('milkdown.editor'));
      expect(
        manifest.viewFactories[0].jsFactoryName,
        equals('fluttronCreateMilkdownEditorView'),
      );
      expect(manifest.viewFactories[0].description, equals('Milkdown editor'));
      expect(manifest.assets.js, equals(['web/ext/main.js']));
      expect(manifest.assets.css, equals(['web/ext/main.css']));
      expect(manifest.events, hasLength(1));
      expect(
        manifest.events![0].name,
        equals('fluttron.milkdown.editor.change'),
      );
      expect(manifest.events![0].direction, equals(EventDirection.jsToDart));
    });

    test('toJson serializes manifest', () {
      final manifest = WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(
            type: 'chart.bar',
            jsFactoryName: 'fluttronCreateChartBarView',
          ),
        ],
        assets: Assets(js: ['web/ext/main.js']),
        events: [
          Event(
            name: 'fluttron.chart.bar.click',
            direction: EventDirection.jsToDart,
          ),
        ],
      );

      final json = manifest.toJson();

      expect(json['version'], equals('1'));
      expect(json['viewFactories'], hasLength(1));
      expect(json['viewFactories'][0]['type'], equals('chart.bar'));
      expect(json['assets']['js'], equals(['web/ext/main.js']));
      expect(json['events'], hasLength(1));
    });

    test('copyWith sets packageName and rootPath', () {
      final manifest = WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(
            type: 'test.view',
            jsFactoryName: 'fluttronCreateTestViewView',
          ),
        ],
        assets: Assets(js: ['web/ext/main.js']),
      );

      final copy = manifest.copyWith(
        packageName: 'my_package',
        rootPath: '/path/to/package',
      );

      expect(copy.packageName, equals('my_package'));
      expect(copy.rootPath, equals('/path/to/package'));
      expect(copy.version, equals('1'));
    });

    test('parses manifest without optional fields', () {
      final json = {
        'version': '1',
        'viewFactories': [
          {
            'type': 'minimal.view',
            'jsFactoryName': 'fluttronCreateMinimalViewView',
          },
        ],
        'assets': {
          'js': ['web/ext/main.js'],
        },
      };

      final manifest = WebPackageManifest.fromJson(json);

      expect(manifest.viewFactories[0].description, isNull);
      expect(manifest.assets.css, isNull);
      expect(manifest.events, isNull);
    });
  });

  group('EventDirection', () {
    test('fromString parses valid values', () {
      expect(
        EventDirection.fromString('js_to_dart'),
        equals(EventDirection.jsToDart),
      );
      expect(
        EventDirection.fromString('dart_to_js'),
        equals(EventDirection.dartToJs),
      );
      expect(
        EventDirection.fromString('bidirectional'),
        equals(EventDirection.bidirectional),
      );
    });

    test('fromString throws on invalid value', () {
      expect(() => EventDirection.fromString('invalid'), throwsArgumentError);
    });

    test('toJsonValue returns correct string', () {
      expect(EventDirection.jsToDart.toJsonValue(), equals('js_to_dart'));
      expect(EventDirection.dartToJs.toJsonValue(), equals('dart_to_js'));
      expect(
        EventDirection.bidirectional.toJsonValue(),
        equals('bidirectional'),
      );
    });
  });

  group('WebPackageManifestLoader', () {
    void writeManifest(Map<String, dynamic> json) {
      final file = File(p.join(tempDir.path, 'fluttron_web_package.json'));
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
    }

    group('valid manifests', () {
      test('loads complete manifest', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'milkdown.editor',
              'jsFactoryName': 'fluttronCreateMilkdownEditorView',
              'description': 'Markdown editor',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
            'css': ['web/ext/main.css'],
          },
          'events': [
            {
              'name': 'fluttron.milkdown.editor.change',
              'direction': 'js_to_dart',
              'payloadType': '{ markdown: string }',
            },
          ],
        });

        final manifest = WebPackageManifestLoader.load(tempDir);

        expect(manifest.version, equals('1'));
        expect(manifest.viewFactories, hasLength(1));
        expect(manifest.viewFactories[0].type, equals('milkdown.editor'));
        expect(manifest.assets.css, isNotNull);
        expect(manifest.events, isNotNull);
      });

      test('loads minimal manifest (no css, no events)', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'minimal.view',
              'jsFactoryName': 'fluttronCreateMinimalViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        final manifest = WebPackageManifestLoader.load(tempDir);

        expect(manifest.version, equals('1'));
        expect(manifest.viewFactories, hasLength(1));
        expect(manifest.assets.css, isNull);
        expect(manifest.events, isNull);
      });

      test('loads manifest with multiple viewFactories', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'chart.bar',
              'jsFactoryName': 'fluttronCreateChartBarView',
            },
            {
              'type': 'chart.line',
              'jsFactoryName': 'fluttronCreateChartLineView',
            },
            {
              'type': 'chart.pie',
              'jsFactoryName': 'fluttronCreateChartPieView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        final manifest = WebPackageManifestLoader.load(tempDir);

        expect(manifest.viewFactories, hasLength(3));
        expect(manifest.viewFactories[0].type, equals('chart.bar'));
        expect(manifest.viewFactories[1].type, equals('chart.line'));
        expect(manifest.viewFactories[2].type, equals('chart.pie'));
      });

      test('loads manifest with multiple JS assets', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'complex.view',
              'jsFactoryName': 'fluttronCreateComplexViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js', 'web/ext/vendor.js'],
            'css': ['web/ext/main.css', 'web/ext/theme.css'],
          },
        });

        final manifest = WebPackageManifestLoader.load(tempDir);

        expect(manifest.assets.js, hasLength(2));
        expect(manifest.assets.css, hasLength(2));
      });

      test('tryLoad returns null when manifest missing', () {
        // Don't write any manifest
        final manifest = WebPackageManifestLoader.tryLoad(tempDir);
        expect(manifest, isNull);
      });

      test('tryLoad returns manifest when present', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName': 'fluttronCreateTestViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        final manifest = WebPackageManifestLoader.tryLoad(tempDir);
        expect(manifest, isNotNull);
        expect(manifest!.version, equals('1'));
      });
    });

    group('validation errors', () {
      test('throws on missing manifest file', () {
        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              contains('Missing fluttron_web_package.json'),
            ),
          ),
        );
      });

      test('throws on invalid JSON', () {
        final file = File(p.join(tempDir.path, 'fluttron_web_package.json'));
        file.writeAsStringSync('{ invalid json }');

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              contains('Invalid JSON'),
            ),
          ),
        );
      });

      test('throws on JSON array instead of object', () {
        final file = File(p.join(tempDir.path, 'fluttron_web_package.json'));
        file.writeAsStringSync('[]');

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              contains('must be a JSON object'),
            ),
          ),
        );
      });

      test('throws on invalid version', () {
        writeManifest({
          'version': '2',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName': 'fluttronCreateTestViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              allOf(contains('Invalid "version"'), contains('expected "1"')),
            ),
          ),
        );
      });

      test('throws on empty viewFactories', () {
        writeManifest({
          'version': '1',
          'viewFactories': <Map<String, dynamic>>[],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              contains('Missing or empty "viewFactories"'),
            ),
          ),
        );
      });

      test('throws on invalid viewFactory.type pattern', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'InvalidType', // Should be lowercase with dot
              'jsFactoryName': 'fluttronCreateInvalidTypeView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('Invalid "viewFactories[0].type"'),
                contains('does not match pattern'),
              ),
            ),
          ),
        );
      });

      test('throws on viewFactory.type without dot', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'nopackage', // Missing package.type format
              'jsFactoryName': 'fluttronCreateNopackageView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              contains('Invalid "viewFactories[0].type"'),
            ),
          ),
        );
      });

      test('throws on invalid jsFactoryName pattern', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName': 'invalidFactoryName', // Wrong pattern
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('Invalid "viewFactories[0].jsFactoryName"'),
                contains('fluttronCreate<Name>View'),
              ),
            ),
          ),
        );
      });

      test('throws on jsFactoryName missing View suffix', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName':
                  'fluttronCreateTestWidget', // Missing View suffix
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              contains('Invalid "viewFactories[0].jsFactoryName"'),
            ),
          ),
        );
      });

      test('throws on empty assets.js', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName': 'fluttronCreateTestViewView',
            },
          ],
          'assets': {'js': <String>[]},
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              contains('Missing or empty "assets.js"'),
            ),
          ),
        );
      });

      test('throws on invalid JS path', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName': 'fluttronCreateTestViewView',
            },
          ],
          'assets': {
            'js': ['lib/main.js'],
          }, // Wrong path
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('Invalid "assets.js[0]"'),
                contains('web/ext/filename.js'),
              ),
            ),
          ),
        );
      });

      test('throws on invalid CSS path', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName': 'fluttronCreateTestViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
            'css': ['styles/main.css'], // Wrong path
          },
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('Invalid "assets.css[0]"'),
                contains('web/ext/filename.css'),
              ),
            ),
          ),
        );
      });

      test('throws on invalid event name pattern', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName': 'fluttronCreateTestViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
          'events': [
            {
              'name': 'invalid.event.name', // Missing fluttron prefix
              'direction': 'js_to_dart',
            },
          ],
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('Invalid "events[0].name"'),
                contains('fluttron.package.type.event'),
              ),
            ),
          ),
        );
      });

      test('throws on invalid event direction', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'test.view',
              'jsFactoryName': 'fluttronCreateTestViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
          'events': [
            {
              'name': 'fluttron.test.view.change',
              'direction': 'invalid_direction',
            },
          ],
        });

        expect(
          () => WebPackageManifestLoader.load(tempDir),
          throwsA(
            isA<WebPackageManifestException>().having(
              (e) => e.message,
              'message',
              contains('Invalid manifest schema'),
            ),
          ),
        );
      });
    });

    group('edge cases', () {
      test('accepts valid type with underscores', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'my_package.complex_view',
              'jsFactoryName': 'fluttronCreateMyPackageComplexViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        final manifest = WebPackageManifestLoader.load(tempDir);
        expect(
          manifest.viewFactories[0].type,
          equals('my_package.complex_view'),
        );
      });

      test('accepts valid jsFactoryName with multiple words', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'chart.bar_chart',
              'jsFactoryName': 'fluttronCreateChartBarChartView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        });

        final manifest = WebPackageManifestLoader.load(tempDir);
        expect(
          manifest.viewFactories[0].jsFactoryName,
          equals('fluttronCreateChartBarChartView'),
        );
      });

      test('accepts valid event name with multiple segments', () {
        writeManifest({
          'version': '1',
          'viewFactories': [
            {
              'type': 'editor.view',
              'jsFactoryName': 'fluttronCreateEditorViewView',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
          'events': [
            {
              'name': 'fluttron.editor.view.cursor.position.change',
              'direction': 'js_to_dart',
            },
          ],
        });

        final manifest = WebPackageManifestLoader.load(tempDir);
        expect(
          manifest.events![0].name,
          equals('fluttron.editor.view.cursor.position.change'),
        );
      });
    });
  });
}
