import 'dart:io';

import 'package:fluttron_host/src/services/file_service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FileService service;
  late Directory tempDir;

  setUp(() async {
    service = FileService();
    tempDir = await Directory.systemTemp.createTemp('file_service_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('namespace', () {
    test('returns "file"', () {
      expect(service.namespace, equals('file'));
    });
  });

  group('readFile', () {
    test('reads file content successfully', () async {
      final file = File('${tempDir.path}/test.md');
      await file.writeAsString('# Hello World');

      final result = await service.handle('readFile', {'path': file.path});
      expect(result, equals({'content': '# Hello World'}));
    });

    test('throws FILE_NOT_FOUND for non-existent file', () async {
      expect(
        () => service.handle('readFile', {'path': '${tempDir.path}/no.md'}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'FILE_NOT_FOUND'),
        ),
      );
    });

    test('throws BAD_PARAMS for missing path', () async {
      expect(
        () => service.handle('readFile', {}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('writeFile', () {
    test('writes content to file', () async {
      final path = '${tempDir.path}/output.md';
      await service.handle('writeFile', {
        'path': path,
        'content': 'Test content',
      });

      final file = File(path);
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('Test content'));
    });

    test('creates parent directories if needed', () async {
      final path = '${tempDir.path}/sub/dir/output.md';
      await service.handle('writeFile', {'path': path, 'content': 'Nested'});

      final file = File(path);
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('Nested'));
    });

    test('overwrites existing file', () async {
      final path = '${tempDir.path}/existing.md';
      await File(path).writeAsString('Old content');

      await service.handle('writeFile', {
        'path': path,
        'content': 'New content',
      });

      expect(await File(path).readAsString(), equals('New content'));
    });

    test('accepts empty content and clears the file', () async {
      final path = '${tempDir.path}/empty.md';
      await File(path).writeAsString('seed');

      await service.handle('writeFile', {'path': path, 'content': ''});

      expect(await File(path).readAsString(), isEmpty);
    });

    test('throws BAD_PARAMS for missing content', () async {
      expect(
        () => service.handle('writeFile', {'path': '${tempDir.path}/test.md'}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('listDirectory', () {
    test('lists directory contents', () async {
      await File('${tempDir.path}/a.md').writeAsString('A');
      await File('${tempDir.path}/b.md').writeAsString('B');
      await Directory('${tempDir.path}/subdir').create();

      final result = await service.handle('listDirectory', {
        'path': tempDir.path,
      });
      final entries = result['entries'] as List;

      expect(entries.length, equals(3));
      // Directories come first
      expect(entries[0]['isDirectory'], isTrue);
      expect(entries[0]['name'], equals('subdir'));
      expect(entries[0]['size'], equals(0));
      // Then files sorted by name
      expect(entries[1]['isFile'], isTrue);
      expect(entries[1]['name'], equals('a.md'));
      expect(entries[2]['isFile'], isTrue);
      expect(entries[2]['name'], equals('b.md'));
    });

    test('returns empty list for empty directory', () async {
      final result = await service.handle('listDirectory', {
        'path': tempDir.path,
      });
      final entries = result['entries'] as List;
      expect(entries, isEmpty);
    });

    test('throws DIRECTORY_NOT_FOUND for non-existent directory', () async {
      expect(
        () =>
            service.handle('listDirectory', {'path': '${tempDir.path}/no-dir'}),
        throwsA(
          isA<FluttronError>().having(
            (e) => e.code,
            'code',
            'DIRECTORY_NOT_FOUND',
          ),
        ),
      );
    });
  });

  group('stat', () {
    test('returns stats for file', () async {
      final file = File('${tempDir.path}/stat-test.md');
      await file.writeAsString('Content');

      final result = await service.handle('stat', {'path': file.path});

      expect(result['exists'], isTrue);
      expect(result['isFile'], isTrue);
      expect(result['isDirectory'], isFalse);
      expect(result['size'], equals(7)); // 'Content'.length
      expect(result['modified'], isNotEmpty);
    });

    test('returns stats for directory', () async {
      final dir = Directory('${tempDir.path}/stat-dir');
      await dir.create();

      final result = await service.handle('stat', {'path': dir.path});

      expect(result['exists'], isTrue);
      expect(result['isFile'], isFalse);
      expect(result['isDirectory'], isTrue);
      expect(result['size'], equals(0));
    });

    test('returns exists=false for non-existent path', () async {
      final result = await service.handle('stat', {
        'path': '${tempDir.path}/no-file.md',
      });

      expect(result['exists'], isFalse);
      expect(result['isFile'], isFalse);
      expect(result['isDirectory'], isFalse);
      expect(result['size'], equals(0));
    });
  });

  group('createFile', () {
    test('creates new file with empty content', () async {
      final path = '${tempDir.path}/new.md';
      await service.handle('createFile', {'path': path});

      final file = File(path);
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), isEmpty);
    });

    test('creates new file with content', () async {
      final path = '${tempDir.path}/new-with-content.md';
      await service.handle('createFile', {
        'path': path,
        'content': 'Initial content',
      });

      final file = File(path);
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('Initial content'));
    });

    test('creates parent directories', () async {
      final path = '${tempDir.path}/deep/dir/new.md';
      await service.handle('createFile', {'path': path, 'content': 'Deep'});

      final file = File(path);
      expect(await file.exists(), isTrue);
    });

    test('throws FILE_EXISTS if file already exists', () async {
      final path = '${tempDir.path}/existing.md';
      await File(path).writeAsString('Existing');

      expect(
        () => service.handle('createFile', {'path': path}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'FILE_EXISTS'),
        ),
      );
    });

    test('throws BAD_PARAMS if content is not a string', () async {
      final path = '${tempDir.path}/new-with-invalid-content.md';
      expect(
        () => service.handle('createFile', {'path': path, 'content': 123}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('delete', () {
    test('deletes file', () async {
      final file = File('${tempDir.path}/to-delete.md');
      await file.writeAsString('Delete me');

      await service.handle('delete', {'path': file.path});

      expect(await file.exists(), isFalse);
    });

    test('deletes empty directory', () async {
      final dir = Directory('${tempDir.path}/empty-dir');
      await dir.create();

      await service.handle('delete', {'path': dir.path});

      expect(await dir.exists(), isFalse);
    });

    test('throws DIRECTORY_NOT_EMPTY for non-empty directory', () async {
      final dir = Directory('${tempDir.path}/non-empty-dir');
      await dir.create();
      await File('${dir.path}/file.md').writeAsString('Content');

      expect(
        () => service.handle('delete', {'path': dir.path}),
        throwsA(
          isA<FluttronError>().having(
            (e) => e.code,
            'code',
            'DIRECTORY_NOT_EMPTY',
          ),
        ),
      );
    });

    test('throws NOT_FOUND for non-existent path', () async {
      expect(
        () => service.handle('delete', {'path': '${tempDir.path}/no-file.md'}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'NOT_FOUND'),
        ),
      );
    });
  });

  group('rename', () {
    test('renames file', () async {
      final oldPath = '${tempDir.path}/old-name.md';
      final newPath = '${tempDir.path}/new-name.md';
      await File(oldPath).writeAsString('Content');

      await service.handle('rename', {'oldPath': oldPath, 'newPath': newPath});

      expect(await File(oldPath).exists(), isFalse);
      expect(await File(newPath).exists(), isTrue);
      expect(await File(newPath).readAsString(), equals('Content'));
    });

    test('renames directory', () async {
      final oldPath = '${tempDir.path}/old-dir';
      final newPath = '${tempDir.path}/new-dir';
      await Directory(oldPath).create();
      await File('$oldPath/file.md').writeAsString('Inside');

      await service.handle('rename', {'oldPath': oldPath, 'newPath': newPath});

      expect(await Directory(oldPath).exists(), isFalse);
      expect(await Directory(newPath).exists(), isTrue);
      expect(await File('$newPath/file.md').readAsString(), equals('Inside'));
    });

    test('throws NOT_FOUND for non-existent source', () async {
      expect(
        () => service.handle('rename', {
          'oldPath': '${tempDir.path}/no-file.md',
          'newPath': '${tempDir.path}/new.md',
        }),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'NOT_FOUND'),
        ),
      );
    });

    test('throws BAD_PARAMS for missing newPath', () async {
      final path = '${tempDir.path}/file.md';
      await File(path).writeAsString('Content');

      expect(
        () => service.handle('rename', {'oldPath': path}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('exists', () {
    test('returns true for existing file', () async {
      final file = File('${tempDir.path}/exists.md');
      await file.writeAsString('Content');

      final result = await service.handle('exists', {'path': file.path});
      expect(result['exists'], isTrue);
    });

    test('returns true for existing directory', () async {
      final result = await service.handle('exists', {'path': tempDir.path});
      expect(result['exists'], isTrue);
    });

    test('returns false for non-existent path', () async {
      final result = await service.handle('exists', {
        'path': '${tempDir.path}/no-file.md',
      });
      expect(result['exists'], isFalse);
    });
  });

  group('METHOD_NOT_FOUND', () {
    test('throws for unknown method', () async {
      expect(
        () => service.handle('unknownMethod', {'path': tempDir.path}),
        throwsA(
          isA<FluttronError>().having(
            (e) => e.code,
            'code',
            'METHOD_NOT_FOUND',
          ),
        ),
      );
    });
  });
}
