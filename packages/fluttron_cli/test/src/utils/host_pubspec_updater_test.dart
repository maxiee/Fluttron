import 'dart:io';

import 'package:fluttron_cli/src/utils/host_pubspec_updater.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('HostPubspecUpdater', () {
    late Directory tempDir;
    late File hostPubspecFile;
    late HostPubspecUpdater updater;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'host_pubspec_updater_test_',
      );
      hostPubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      updater = HostPubspecUpdater();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'inserts package asset inside assets block before flutter sibling sections',
      () {
        hostPubspecFile.writeAsStringSync(_pubspecWithFontsSection);

        final bool changed = updater.updateSync(
          hostPubspecFile: hostPubspecFile,
          packageNames: const <String>['fluttron_milkdown'],
        );

        expect(changed, isTrue);

        final List<String> lines = hostPubspecFile.readAsLinesSync();
        final int assetsIndex = lines.indexWhere(
          (line) => line.trim() == 'assets:',
        );
        final int fontsIndex = lines.indexWhere(
          (line) => line.trim() == 'fonts:',
        );
        final int newAssetIndex = lines.indexWhere(
          (line) => line.contains('assets/www/ext/packages/fluttron_milkdown/'),
        );

        expect(assetsIndex, greaterThan(-1));
        expect(fontsIndex, greaterThan(-1));
        expect(newAssetIndex, greaterThan(assetsIndex));
        expect(newAssetIndex, lessThan(fontsIndex));
        expect(
          lines[newAssetIndex].trim(),
          '- assets/www/ext/packages/fluttron_milkdown/',
        );
      },
    );

    test('does not duplicate package asset declaration', () {
      hostPubspecFile.writeAsStringSync(_pubspecWithExistingPackageAsset);

      final bool changed = updater.updateSync(
        hostPubspecFile: hostPubspecFile,
        packageNames: const <String>['fluttron_milkdown'],
      );

      expect(changed, isFalse);

      final String content = hostPubspecFile.readAsStringSync();
      final int matchCount = RegExp(
        r'assets/www/ext/packages/fluttron_milkdown/',
      ).allMatches(content).length;
      expect(matchCount, 1);
    });

    test(
      'update() supports same indentation behavior as updateSync()',
      () async {
        hostPubspecFile.writeAsStringSync(_pubspecWithFontsSection);

        final bool changed = await updater.update(
          hostPubspecFile: hostPubspecFile,
          packageNames: const <String>['fluttron_milkdown'],
        );

        expect(changed, isTrue);

        final List<String> lines = hostPubspecFile.readAsLinesSync();
        final int fontsIndex = lines.indexWhere(
          (line) => line.trim() == 'fonts:',
        );
        final int newAssetIndex = lines.indexWhere(
          (line) => line.contains('assets/www/ext/packages/fluttron_milkdown/'),
        );
        expect(newAssetIndex, lessThan(fontsIndex));
      },
    );

    test('throws when assets section is missing', () {
      hostPubspecFile.writeAsStringSync('''
name: host_app
description: test
flutter:
  uses-material-design: true
''');

      expect(
        () => updater.updateSync(
          hostPubspecFile: hostPubspecFile,
          packageNames: const <String>['fluttron_milkdown'],
        ),
        throwsA(isA<HostPubspecUpdaterException>()),
      );
    });
  });
}

const String _pubspecWithFontsSection = '''
name: host_app
description: test
flutter:
  uses-material-design: true
  assets:
    - assets/www/
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
''';

const String _pubspecWithExistingPackageAsset = '''
name: host_app
description: test
flutter:
  uses-material-design: true
  assets:
    - assets/www/
    - assets/www/ext/packages/fluttron_milkdown/
''';
