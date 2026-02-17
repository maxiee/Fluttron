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
  late DialogServiceClient dialogService;

  setUp(() {
    mockClient = FakeFluttronClient();
    dialogService = DialogServiceClient(mockClient);
  });

  group('DialogServiceClient', () {
    group('openFile', () {
      test('invokes dialog.openFile with minimal params', () async {
        mockClient.whenInvoke('dialog.openFile', (params) {
          expect(params, isEmpty);
          return {'path': '/test/file.md'};
        });

        final result = await dialogService.openFile();
        expect(result, equals('/test/file.md'));
      });

      test('passes optional params', () async {
        mockClient.whenInvoke('dialog.openFile', (params) {
          expect(params['title'], equals('Select File'));
          expect(params['allowedExtensions'], equals(['md', 'txt']));
          expect(params['initialDirectory'], equals('/home'));
          return {'path': '/test/file.md'};
        });

        final result = await dialogService.openFile(
          title: 'Select File',
          allowedExtensions: ['md', 'txt'],
          initialDirectory: '/home',
        );
        expect(result, equals('/test/file.md'));
      });

      test('returns null when cancelled', () async {
        mockClient.whenInvoke('dialog.openFile', (params) {
          return {'path': null};
        });

        final result = await dialogService.openFile();
        expect(result, isNull);
      });
    });

    group('openFiles', () {
      test('invokes dialog.openFiles and returns list', () async {
        mockClient.whenInvoke('dialog.openFiles', (params) {
          return {
            'paths': ['/test/file1.md', '/test/file2.md'],
          };
        });

        final result = await dialogService.openFiles();
        expect(result, equals(['/test/file1.md', '/test/file2.md']));
      });

      test('returns empty list when cancelled', () async {
        mockClient.whenInvoke('dialog.openFiles', (params) {
          return {'paths': <String>[]};
        });

        final result = await dialogService.openFiles();
        expect(result, isEmpty);
      });
    });

    group('openDirectory', () {
      test('invokes dialog.openDirectory', () async {
        mockClient.whenInvoke('dialog.openDirectory', (params) {
          expect(params['title'], equals('Select Folder'));
          return {'path': '/test/folder'};
        });

        final result = await dialogService.openDirectory(
          title: 'Select Folder',
        );
        expect(result, equals('/test/folder'));
      });

      test('returns null when cancelled', () async {
        mockClient.whenInvoke('dialog.openDirectory', (params) {
          return {'path': null};
        });

        final result = await dialogService.openDirectory();
        expect(result, isNull);
      });
    });

    group('saveFile', () {
      test('invokes dialog.saveFile with params', () async {
        mockClient.whenInvoke('dialog.saveFile', (params) {
          expect(params['title'], equals('Save As'));
          expect(params['defaultFileName'], equals('untitled.md'));
          expect(params['allowedExtensions'], equals(['md']));
          return {'path': '/test/untitled.md'};
        });

        final result = await dialogService.saveFile(
          title: 'Save As',
          defaultFileName: 'untitled.md',
          allowedExtensions: ['md'],
        );
        expect(result, equals('/test/untitled.md'));
      });

      test('returns null when cancelled', () async {
        mockClient.whenInvoke('dialog.saveFile', (params) {
          return {'path': null};
        });

        final result = await dialogService.saveFile();
        expect(result, isNull);
      });
    });
  });
}
