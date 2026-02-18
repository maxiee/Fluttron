import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'file_service_client_test.dart' show FakeFluttronClient;

void main() {
  late FakeFluttronClient mockClient;
  late WindowServiceClient windowService;

  setUp(() {
    mockClient = FakeFluttronClient();
    windowService = WindowServiceClient(mockClient);
  });

  group('WindowServiceClient', () {
    group('setTitle', () {
      test('invokes window.setTitle with title', () async {
        var invoked = false;
        mockClient.whenInvoke('window.setTitle', (params) {
          expect(params['title'], equals('My App'));
          invoked = true;
          return {};
        });

        await windowService.setTitle('My App');
        expect(invoked, isTrue);
      });
    });

    group('setSize', () {
      test('invokes window.setSize with width and height', () async {
        var invoked = false;
        mockClient.whenInvoke('window.setSize', (params) {
          expect(params['width'], equals(1280));
          expect(params['height'], equals(720));
          invoked = true;
          return {};
        });

        await windowService.setSize(1280, 720);
        expect(invoked, isTrue);
      });
    });

    group('getSize', () {
      test('invokes window.getSize and returns size map', () async {
        mockClient.whenInvoke('window.getSize', (params) {
          return {'width': 1440, 'height': 900};
        });

        final size = await windowService.getSize();
        expect(size['width'], equals(1440));
        expect(size['height'], equals(900));
      });
    });

    group('minimize', () {
      test('invokes window.minimize with no params', () async {
        var invoked = false;
        mockClient.whenInvoke('window.minimize', (params) {
          expect(params, isEmpty);
          invoked = true;
          return {};
        });

        await windowService.minimize();
        expect(invoked, isTrue);
      });
    });

    group('maximize', () {
      test('invokes window.maximize with no params', () async {
        var invoked = false;
        mockClient.whenInvoke('window.maximize', (params) {
          expect(params, isEmpty);
          invoked = true;
          return {};
        });

        await windowService.maximize();
        expect(invoked, isTrue);
      });
    });

    group('setFullScreen', () {
      test('invokes window.setFullScreen with enabled=true', () async {
        var invoked = false;
        mockClient.whenInvoke('window.setFullScreen', (params) {
          expect(params['enabled'], isTrue);
          invoked = true;
          return {};
        });

        await windowService.setFullScreen(true);
        expect(invoked, isTrue);
      });

      test('invokes window.setFullScreen with enabled=false', () async {
        var invoked = false;
        mockClient.whenInvoke('window.setFullScreen', (params) {
          expect(params['enabled'], isFalse);
          invoked = true;
          return {};
        });

        await windowService.setFullScreen(false);
        expect(invoked, isTrue);
      });
    });

    group('isFullScreen', () {
      test('returns true when window is fullscreen', () async {
        mockClient.whenInvoke('window.isFullScreen', (params) {
          return {'result': true};
        });

        final result = await windowService.isFullScreen();
        expect(result, isTrue);
      });

      test('returns false when window is not fullscreen', () async {
        mockClient.whenInvoke('window.isFullScreen', (params) {
          return {'result': false};
        });

        final result = await windowService.isFullScreen();
        expect(result, isFalse);
      });
    });

    group('center', () {
      test('invokes window.center with no params', () async {
        var invoked = false;
        mockClient.whenInvoke('window.center', (params) {
          expect(params, isEmpty);
          invoked = true;
          return {};
        });

        await windowService.center();
        expect(invoked, isTrue);
      });
    });

    group('setMinSize', () {
      test('invokes window.setMinSize with width and height', () async {
        var invoked = false;
        mockClient.whenInvoke('window.setMinSize', (params) {
          expect(params['width'], equals(800));
          expect(params['height'], equals(600));
          invoked = true;
          return {};
        });

        await windowService.setMinSize(800, 600);
        expect(invoked, isTrue);
      });
    });

    group('error handling', () {
      test('setTitle propagates error from client', () async {
        mockClient.whenInvoke('window.setTitle', (params) {
          throw StateError('Host error: window not ready');
        });

        expect(
          () => windowService.setTitle('fail'),
          throwsA(isA<StateError>()),
        );
      });

      test('getSize propagates error from client', () async {
        mockClient.whenInvoke('window.getSize', (params) {
          throw StateError('Host error');
        });

        expect(() => windowService.getSize(), throwsA(isA<StateError>()));
      });
    });
  });
}
