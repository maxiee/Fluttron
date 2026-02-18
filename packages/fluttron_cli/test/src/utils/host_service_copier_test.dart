import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/src/utils/host_service_copier.dart';

void main() {
  late Directory tempDir;
  late Directory templateDir;
  late Directory targetDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'host_service_copier_test_',
    );
    templateDir = Directory(p.join(tempDir.path, 'template'));
    targetDir = Directory(p.join(tempDir.path, 'target'));
    await templateDir.create(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HostServiceCopier', () {
    test('renames host package directory', () async {
      final copier = HostServiceCopier();

      // Create host package structure
      final hostDir = Directory(
        p.join(templateDir.path, 'template_service_host'),
      );
      await hostDir.create(recursive: true);

      final pubspecFile = File(p.join(hostDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: template_service_host
description: Template
version: 0.1.0
''');

      await copier.copyAndTransform(
        serviceName: 'my_notification',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      // Check directory was renamed
      final renamedDir = Directory(
        p.join(targetDir.path, 'my_notification_host'),
      );
      expect(await renamedDir.exists(), isTrue);

      final targetPubspec = File(p.join(renamedDir.path, 'pubspec.yaml'));
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_notification_host'));
    });

    test('renames client package directory', () async {
      final copier = HostServiceCopier();

      // Create client package structure
      final clientDir = Directory(
        p.join(templateDir.path, 'template_service_client'),
      );
      await clientDir.create(recursive: true);

      final pubspecFile = File(p.join(clientDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: template_service_client
description: Template
version: 0.1.0
''');

      await copier.copyAndTransform(
        serviceName: 'my_notification',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      // Check directory was renamed
      final renamedDir = Directory(
        p.join(targetDir.path, 'my_notification_client'),
      );
      expect(await renamedDir.exists(), isTrue);

      final targetPubspec = File(p.join(renamedDir.path, 'pubspec.yaml'));
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_notification_client'));
    });

    test('renames library file based on package name', () async {
      final copier = HostServiceCopier();

      final hostLibDir = Directory(
        p.join(templateDir.path, 'template_service_host', 'lib'),
      );
      await hostLibDir.create(recursive: true);

      final libFile = File(
        p.join(hostLibDir.path, 'template_service_host.dart'),
      );
      await libFile.writeAsString('''
library template_service_host;
export 'src/template_service.dart';
''');

      await copier.copyAndTransform(
        serviceName: 'weather_service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      // Check file was renamed
      final renamedFile = File(
        p.join(
          targetDir.path,
          'weather_service_host',
          'lib',
          'weather_service_host.dart',
        ),
      );
      expect(await renamedFile.exists(), isTrue);

      // Check content was transformed
      final content = await renamedFile.readAsString();
      expect(content, contains('library weather_service_host'));
      expect(content, contains("export 'src/weather_service.dart'"));
    });

    test('renames service implementation file', () async {
      final copier = HostServiceCopier();

      final srcDir = Directory(
        p.join(templateDir.path, 'template_service_host', 'lib', 'src'),
      );
      await srcDir.create(recursive: true);

      final serviceFile = File(p.join(srcDir.path, 'template_service.dart'));
      await serviceFile.writeAsString('''
class TemplateService extends FluttronService {
  @override
  String get namespace => 'template_service';
}
''');

      await copier.copyAndTransform(
        serviceName: 'notification_service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      // Check file was renamed
      final renamedFile = File(
        p.join(
          targetDir.path,
          'notification_service_host',
          'lib',
          'src',
          'notification_service.dart',
        ),
      );
      expect(await renamedFile.exists(), isTrue);

      // Check content was transformed
      final content = await renamedFile.readAsString();
      expect(content, contains('class NotificationService'));
      expect(content, contains("namespace => 'notification_service'"));
    });

    test('transforms client class names', () async {
      final copier = HostServiceCopier();

      final srcDir = Directory(
        p.join(templateDir.path, 'template_service_client', 'lib', 'src'),
      );
      await srcDir.create(recursive: true);

      final clientFile = File(
        p.join(srcDir.path, 'template_service_client.dart'),
      );
      await clientFile.writeAsString('''
class TemplateServiceClient {
  Future<String> greet({String? name}) async {
    final result = await _client.invoke('template_service.greet', params);
    return result['message'] as String;
  }
}
''');

      await copier.copyAndTransform(
        serviceName: 'my_cool_service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetFile = File(
        p.join(
          targetDir.path,
          'my_cool_service_client',
          'lib',
          'src',
          'my_cool_service_client.dart',
        ),
      );
      expect(await targetFile.exists(), isTrue);

      final content = await targetFile.readAsString();
      expect(content, contains('class MyCoolServiceClient'));
      expect(content, contains("'my_cool_service.greet'"));
    });

    test('transforms manifest name and namespace', () async {
      final copier = HostServiceCopier();

      final manifestFile = File(
        p.join(templateDir.path, 'fluttron_host_service.json'),
      );
      await manifestFile.writeAsString('''
{
  "version": "1",
  "name": "template_service",
  "namespace": "template_service",
  "description": "A custom Fluttron host service."
}
''');

      await copier.copyAndTransform(
        serviceName: 'weather_api',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetManifest = File(
        p.join(targetDir.path, 'fluttron_host_service.json'),
      );
      expect(await targetManifest.exists(), isTrue);

      final content = await targetManifest.readAsString();
      expect(content, contains('"name": "weather_api"'));
      expect(content, contains('"namespace": "weather_api"'));
    });

    test('handles nested directory structures', () async {
      final copier = HostServiceCopier();

      // Create nested structure
      final testDir = Directory(
        p.join(templateDir.path, 'template_service_host', 'test'),
      );
      await testDir.create(recursive: true);

      final testFile = File(p.join(testDir.path, 'template_service_test.dart'));
      await testFile.writeAsString('''
import 'package:template_service_host/template_service_host.dart';

void main() {
  test('namespace is template_service', () {
    final service = TemplateService();
    expect(service.namespace, equals('template_service'));
  });
}
''');

      await copier.copyAndTransform(
        serviceName: 'data_sync',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetTest = File(
        p.join(targetDir.path, 'data_sync_host', 'test', 'data_sync_test.dart'),
      );
      expect(await targetTest.exists(), isTrue);

      final content = await targetTest.readAsString();
      expect(content, contains('package:data_sync_host'));
      // TemplateService -> DataSync (PascalCase of 'data_sync')
      expect(content, contains('final service = DataSync()'));
      expect(content, contains("equals('data_sync')"));
    });

    test('skips node_modules and .dart_tool directories', () async {
      final copier = HostServiceCopier();

      // Create directories that should be skipped
      final nodeModules = Directory(p.join(templateDir.path, 'node_modules'));
      await nodeModules.create(recursive: true);
      await File(
        p.join(nodeModules.path, 'should_not_copy.js'),
      ).writeAsString('// should not be copied');

      final dartTool = Directory(p.join(templateDir.path, '.dart_tool'));
      await dartTool.create(recursive: true);
      await File(
        p.join(dartTool.path, 'should_not_copy.json'),
      ).writeAsString('{}');

      // Create a file that should be copied
      await File(
        p.join(templateDir.path, 'README.md'),
      ).writeAsString('# template_service');

      await copier.copyAndTransform(
        serviceName: 'test_service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      // Verify skipped directories don't exist
      expect(
        await Directory(p.join(targetDir.path, 'node_modules')).exists(),
        isFalse,
      );
      expect(
        await Directory(p.join(targetDir.path, '.dart_tool')).exists(),
        isFalse,
      );

      // Verify README was copied and transformed
      final readme = File(p.join(targetDir.path, 'README.md'));
      expect(await readme.exists(), isTrue);
      final content = await readme.readAsString();
      expect(content, contains('# test_service'));
    });

    test('skips transient Flutter and lock files', () async {
      final copier = HostServiceCopier();

      await File(
        p.join(templateDir.path, '.flutter-plugins-dependencies'),
      ).writeAsString('{}');
      await File(
        p.join(templateDir.path, 'pubspec.lock'),
      ).writeAsString('lock');
      await File(p.join(templateDir.path, '.DS_Store')).writeAsString('x');
      await File(
        p.join(templateDir.path, 'README.md'),
      ).writeAsString('# template_service');

      await copier.copyAndTransform(
        serviceName: 'safe_service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      expect(
        await File(
          p.join(targetDir.path, '.flutter-plugins-dependencies'),
        ).exists(),
        isFalse,
      );
      expect(
        await File(p.join(targetDir.path, 'pubspec.lock')).exists(),
        isFalse,
      );
      expect(await File(p.join(targetDir.path, '.DS_Store')).exists(), isFalse);

      final readme = File(p.join(targetDir.path, 'README.md'));
      expect(await readme.exists(), isTrue);
      final content = await readme.readAsString();
      expect(content, contains('# safe_service'));
    });
  });

  group('Naming conventions', () {
    test('converts PascalCase to snake_case', () async {
      final copier = HostServiceCopier();

      final hostDir = Directory(
        p.join(templateDir.path, 'template_service_host'),
      );
      await hostDir.create(recursive: true);

      final pubspecFile = File(p.join(hostDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: template_service_host');

      await copier.copyAndTransform(
        serviceName: 'NotificationService',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(
        p.join(targetDir.path, 'notification_service_host', 'pubspec.yaml'),
      );
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: notification_service_host'));
    });

    test('converts camelCase to snake_case', () async {
      final copier = HostServiceCopier();

      final hostDir = Directory(
        p.join(templateDir.path, 'template_service_host'),
      );
      await hostDir.create(recursive: true);

      final pubspecFile = File(p.join(hostDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: template_service_host');

      await copier.copyAndTransform(
        serviceName: 'myNotificationService',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(
        p.join(targetDir.path, 'my_notification_service_host', 'pubspec.yaml'),
      );
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_notification_service_host'));
    });

    test('preserves snake_case input', () async {
      final copier = HostServiceCopier();

      final hostDir = Directory(
        p.join(templateDir.path, 'template_service_host'),
      );
      await hostDir.create(recursive: true);

      final pubspecFile = File(p.join(hostDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: template_service_host');

      await copier.copyAndTransform(
        serviceName: 'my_notification_service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(
        p.join(targetDir.path, 'my_notification_service_host', 'pubspec.yaml'),
      );
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_notification_service_host'));
    });

    test('normalizes kebab-case input to snake_case', () async {
      final copier = HostServiceCopier();

      final hostDir = Directory(
        p.join(templateDir.path, 'template_service_host'),
      );
      await hostDir.create(recursive: true);

      final pubspecFile = File(p.join(hostDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: template_service_host');

      await copier.copyAndTransform(
        serviceName: 'my-notification-service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(
        p.join(targetDir.path, 'my_notification_service_host', 'pubspec.yaml'),
      );
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_notification_service_host'));
    });

    test('prefixes service name when input starts with digits', () async {
      final copier = HostServiceCopier();

      final hostDir = Directory(
        p.join(templateDir.path, 'template_service_host'),
      );
      await hostDir.create(recursive: true);

      final pubspecFile = File(p.join(hostDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: template_service_host');

      await copier.copyAndTransform(
        serviceName: '123-service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(
        p.join(targetDir.path, 'svc_123_service_host', 'pubspec.yaml'),
      );
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: svc_123_service_host'));
    });

    test(
      'derives PascalCase and camelCase from normalized snake_case',
      () async {
        final copier = HostServiceCopier();

        final hostSrcDir = Directory(
          p.join(templateDir.path, 'template_service_host', 'lib', 'src'),
        );
        await hostSrcDir.create(recursive: true);
        await File(
          p.join(hostSrcDir.path, 'template_service.dart'),
        ).writeAsString('''
class TemplateService {}
final templateService = TemplateService();
''');

        final clientSrcDir = Directory(
          p.join(templateDir.path, 'template_service_client', 'lib', 'src'),
        );
        await clientSrcDir.create(recursive: true);
        await File(
          p.join(clientSrcDir.path, 'template_service_client.dart'),
        ).writeAsString('''
class TemplateServiceClient {}
final templateServiceClient = TemplateServiceClient();
''');

        await copier.copyAndTransform(
          serviceName: 'myCoolService',
          sourceDir: templateDir,
          destinationDir: targetDir,
        );

        final hostFile = File(
          p.join(
            targetDir.path,
            'my_cool_service_host',
            'lib',
            'src',
            'my_cool_service.dart',
          ),
        );
        final clientFile = File(
          p.join(
            targetDir.path,
            'my_cool_service_client',
            'lib',
            'src',
            'my_cool_service_client.dart',
          ),
        );

        final hostContent = await hostFile.readAsString();
        final clientContent = await clientFile.readAsString();

        expect(hostContent, contains('class MyCoolService {}'));
        expect(hostContent, contains('final myCoolService = MyCoolService();'));
        expect(clientContent, contains('class MyCoolServiceClient {}'));
        expect(
          clientContent,
          contains('final myCoolServiceClient = MyCoolServiceClient();'),
        );
      },
    );
  });

  group('Dual package transformation', () {
    test('transforms both host and client packages together', () async {
      final copier = HostServiceCopier();

      // Create host package
      final hostDir = Directory(
        p.join(templateDir.path, 'template_service_host', 'lib', 'src'),
      );
      await hostDir.create(recursive: true);

      final hostPubspec = File(
        p.join(hostDir.parent.parent.path, 'pubspec.yaml'),
      );
      await hostPubspec.writeAsString('''
name: template_service_host
description: Host implementation
''');

      final hostService = File(p.join(hostDir.path, 'template_service.dart'));
      await hostService.writeAsString('''
class TemplateService extends FluttronService {
  @override
  String get namespace => 'template_service';
}
''');

      // Create client package
      final clientDir = Directory(
        p.join(templateDir.path, 'template_service_client', 'lib', 'src'),
      );
      await clientDir.create(recursive: true);

      final clientPubspec = File(
        p.join(clientDir.parent.parent.path, 'pubspec.yaml'),
      );
      await clientPubspec.writeAsString('''
name: template_service_client
description: Client stub
''');

      final clientService = File(
        p.join(clientDir.path, 'template_service_client.dart'),
      );
      await clientService.writeAsString('''
class TemplateServiceClient {
  Future<String> greet() async {
    return await _client.invoke('template_service.greet', {});
  }
}
''');

      await copier.copyAndTransform(
        serviceName: 'auth_service',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      // Verify host package
      final hostTarget = File(
        p.join(
          targetDir.path,
          'auth_service_host',
          'lib',
          'src',
          'auth_service.dart',
        ),
      );
      expect(await hostTarget.exists(), isTrue);
      final hostContent = await hostTarget.readAsString();
      expect(hostContent, contains('class AuthService'));
      expect(hostContent, contains("namespace => 'auth_service'"));

      // Verify client package
      final clientTarget = File(
        p.join(
          targetDir.path,
          'auth_service_client',
          'lib',
          'src',
          'auth_service_client.dart',
        ),
      );
      expect(await clientTarget.exists(), isTrue);
      final clientContent = await clientTarget.readAsString();
      expect(clientContent, contains('class AuthServiceClient'));
      expect(clientContent, contains("'auth_service.greet'"));
    });
  });
}
