import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/src/utils/pubspec_loader.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pubspec_loader_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PubspecLoader.load', () {
    test('parses basic pubspec.yaml with name and version', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: my_package
version: 1.2.3
''');

      final info = PubspecLoader.load(tempDir);

      expect(info.name, equals('my_package'));
      expect(info.version, equals('1.2.3'));
      expect(info.description, isNull);
    });

    test('parses pubspec.yaml with description', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: my_package
version: 1.0.0
description: A sample package
''');

      final info = PubspecLoader.load(tempDir);

      expect(info.name, equals('my_package'));
      expect(info.version, equals('1.0.0'));
      expect(info.description, equals('A sample package'));
    });

    test('parses pubspec.yaml with quoted values', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: "my_package"
version: '2.0.0'
description: "A description"
''');

      final info = PubspecLoader.load(tempDir);

      expect(info.name, equals('my_package'));
      expect(info.version, equals('2.0.0'));
    });

    test('defaults version to 0.0.0 when not specified', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: my_package
''');

      final info = PubspecLoader.load(tempDir);

      expect(info.name, equals('my_package'));
      expect(info.version, equals('0.0.0'));
    });

    test('skips comments', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
# This is a comment
name: my_package
# Another comment
version: 1.0.0
''');

      final info = PubspecLoader.load(tempDir);

      expect(info.name, equals('my_package'));
      expect(info.version, equals('1.0.0'));
    });

    test('ignores nested fields', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: my_package
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
''');

      final info = PubspecLoader.load(tempDir);

      expect(info.name, equals('my_package'));
      expect(info.version, equals('1.0.0'));
    });

    test('throws when pubspec.yaml is missing', () async {
      expect(
        () => PubspecLoader.load(tempDir),
        throwsA(isA<PubspecLoaderException>()),
      );
    });

    test('throws when name is missing', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
version: 1.0.0
''');

      expect(
        () => PubspecLoader.load(tempDir),
        throwsA(isA<PubspecLoaderException>()),
      );
    });
  });

  group('PubspecLoader.tryLoad', () {
    test('returns PubspecInfo when pubspec.yaml exists', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_package
version: 3.0.0
''');

      final info = PubspecLoader.tryLoad(tempDir);

      expect(info, isNotNull);
      expect(info!.name, equals('test_package'));
      expect(info.version, equals('3.0.0'));
    });

    test('returns null when pubspec.yaml is missing', () async {
      final info = PubspecLoader.tryLoad(tempDir);
      expect(info, isNull);
    });

    test('returns null when pubspec.yaml is invalid', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
version: 1.0.0
# name is missing
''');

      final info = PubspecLoader.tryLoad(tempDir);
      expect(info, isNull);
    });
  });

  group('PubspecLoader.parseAsMap', () {
    test('parses simple key-value pairs', () {
      final yaml = '''
name: my_package
version: 1.0.0
''';

      final map = PubspecLoader.parseAsMap(yaml);

      expect(map['name'], equals('my_package'));
      expect(map['version'], equals('1.0.0'));
    });

    test('handles quoted values', () {
      final yaml = '''
name: "my_package"
description: 'A description'
''';

      final map = PubspecLoader.parseAsMap(yaml);

      expect(map['name'], equals('my_package'));
      expect(map['description'], equals('A description'));
    });

    test('ignores comments', () {
      final yaml = '''
# Comment
name: my_package
# Another comment
''';

      final map = PubspecLoader.parseAsMap(yaml);

      expect(map['name'], equals('my_package'));
    });
  });

  group('PubspecInfo', () {
    test('toString includes name and version', () {
      const info = PubspecInfo(name: 'test', version: '1.0.0');
      expect(info.toString(), contains('test'));
      expect(info.toString(), contains('1.0.0'));
    });
  });
}
