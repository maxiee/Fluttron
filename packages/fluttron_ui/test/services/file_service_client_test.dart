import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [FluttronClient] for testing that allows mocking invoke calls.
class FakeFluttronClient extends FluttronClient {
  final Map<String, dynamic Function(Map<String, dynamic>)> _handlers = {};

  /// Registers a handler for a specific method.
  void whenInvoke(
    String method,
    dynamic Function(Map<String, dynamic>) handler,
  ) {
    _handlers[method] = handler;
  }

  @override
  Future<dynamic> invoke(String method, Map<String, dynamic> params) async {
    final handler = _handlers[method];
    if (handler == null) {
      throw StateError('No mock handler for $method');
    }
    return handler(params);
  }
}

void main() {
  late FakeFluttronClient mockClient;
  late FileServiceClient fileService;

  setUp(() {
    mockClient = FakeFluttronClient();
    fileService = FileServiceClient(mockClient);
  });

  group('FileServiceClient', () {
    test('readFile invokes file.readFile with path', () async {
      mockClient.whenInvoke('file.readFile', (params) {
        expect(params['path'], equals('/test/file.md'));
        return {'content': 'Hello World'};
      });

      final content = await fileService.readFile('/test/file.md');
      expect(content, equals('Hello World'));
    });

    test('writeFile invokes file.writeFile with path and content', () async {
      var invoked = false;
      mockClient.whenInvoke('file.writeFile', (params) {
        expect(params['path'], equals('/test/file.md'));
        expect(params['content'], equals('New content'));
        invoked = true;
        return {};
      });

      await fileService.writeFile('/test/file.md', 'New content');
      expect(invoked, isTrue);
    });

    test('listDirectory returns FileEntry list', () async {
      mockClient.whenInvoke('file.listDirectory', (params) {
        expect(params['path'], equals('/test'));
        return {
          'entries': [
            {
              'name': 'file1.md',
              'path': '/test/file1.md',
              'isFile': true,
              'isDirectory': false,
              'size': 100,
              'modified': '2026-02-17T10:00:00Z',
            },
            {
              'name': 'subdir',
              'path': '/test/subdir',
              'isFile': false,
              'isDirectory': true,
              'size': 0,
              'modified': '2026-02-17T11:00:00Z',
            },
          ],
        };
      });

      final entries = await fileService.listDirectory('/test');
      expect(entries.length, equals(2));
      expect(entries[0].name, equals('file1.md'));
      expect(entries[0].isFile, isTrue);
      expect(entries[1].name, equals('subdir'));
      expect(entries[1].isDirectory, isTrue);
    });

    test('stat returns FileStat', () async {
      mockClient.whenInvoke('file.stat', (params) {
        expect(params['path'], equals('/test/file.md'));
        return {
          'exists': true,
          'isFile': true,
          'isDirectory': false,
          'size': 1024,
          'modified': '2026-02-17T12:00:00Z',
        };
      });

      final stat = await fileService.stat('/test/file.md');
      expect(stat.exists, isTrue);
      expect(stat.isFile, isTrue);
      expect(stat.size, equals(1024));
    });

    test('createFile invokes file.createFile with path and content', () async {
      var invoked = false;
      mockClient.whenInvoke('file.createFile', (params) {
        expect(params['path'], equals('/test/new.md'));
        expect(params['content'], equals('initial'));
        invoked = true;
        return {};
      });

      await fileService.createFile('/test/new.md', content: 'initial');
      expect(invoked, isTrue);
    });

    test('createFile uses empty string as default content', () async {
      var invoked = false;
      mockClient.whenInvoke('file.createFile', (params) {
        expect(params['path'], equals('/test/new.md'));
        expect(params['content'], equals(''));
        invoked = true;
        return {};
      });

      await fileService.createFile('/test/new.md');
      expect(invoked, isTrue);
    });

    test('delete invokes file.delete with path', () async {
      var invoked = false;
      mockClient.whenInvoke('file.delete', (params) {
        expect(params['path'], equals('/test/file.md'));
        invoked = true;
        return {};
      });

      await fileService.delete('/test/file.md');
      expect(invoked, isTrue);
    });

    test('rename invokes file.rename with oldPath and newPath', () async {
      var invoked = false;
      mockClient.whenInvoke('file.rename', (params) {
        expect(params['oldPath'], equals('/test/old.md'));
        expect(params['newPath'], equals('/test/new.md'));
        invoked = true;
        return {};
      });

      await fileService.rename('/test/old.md', '/test/new.md');
      expect(invoked, isTrue);
    });

    test('exists returns bool', () async {
      mockClient.whenInvoke('file.exists', (params) {
        expect(params['path'], equals('/test/file.md'));
        return {'exists': true};
      });

      final result = await fileService.exists('/test/file.md');
      expect(result, isTrue);
    });
  });
}
