import 'package:fluttron_host/src/services/window_service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late WindowService service;

  setUp(() {
    service = WindowService();
  });

  group('namespace', () {
    test('returns "window"', () {
      expect(service.namespace, equals('window'));
    });
  });

  group('setTitle', () {
    test('throws BAD_PARAMS when title is missing', () {
      expect(
        () => service.handle('setTitle', {}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when title is an int', () {
      expect(
        () => service.handle('setTitle', {'title': 42}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when title is null', () {
      expect(
        () => service.handle('setTitle', {'title': null}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when title is a bool', () {
      expect(
        () => service.handle('setTitle', {'title': true}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('setSize', () {
    test('throws BAD_PARAMS when width is missing', () {
      expect(
        () => service.handle('setSize', {'height': 600}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when height is missing', () {
      expect(
        () => service.handle('setSize', {'width': 800}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when width is a string', () {
      expect(
        () => service.handle('setSize', {'width': 'wide', 'height': 600}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when height is a bool', () {
      expect(
        () => service.handle('setSize', {'width': 800, 'height': true}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when width is zero', () {
      expect(
        () => service.handle('setSize', {'width': 0, 'height': 600}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when height is zero', () {
      expect(
        () => service.handle('setSize', {'width': 800, 'height': 0}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when width is negative', () {
      expect(
        () => service.handle('setSize', {'width': -100, 'height': 600}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when height is negative', () {
      expect(
        () => service.handle('setSize', {'width': 800, 'height': -1}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('setFullScreen', () {
    test('throws BAD_PARAMS when enabled is missing', () {
      expect(
        () => service.handle('setFullScreen', {}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when enabled is a string', () {
      expect(
        () => service.handle('setFullScreen', {'enabled': 'true'}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when enabled is an int', () {
      expect(
        () => service.handle('setFullScreen', {'enabled': 1}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when enabled is null', () {
      expect(
        () => service.handle('setFullScreen', {'enabled': null}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('setMinSize', () {
    test('throws BAD_PARAMS when width is missing', () {
      expect(
        () => service.handle('setMinSize', {'height': 400}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when height is missing', () {
      expect(
        () => service.handle('setMinSize', {'width': 400}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when width is a string', () {
      expect(
        () => service.handle('setMinSize', {'width': 'small', 'height': 300}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when width is zero', () {
      expect(
        () => service.handle('setMinSize', {'width': 0, 'height': 300}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when height is zero', () {
      expect(
        () => service.handle('setMinSize', {'width': 400, 'height': 0}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when height is negative', () {
      expect(
        () => service.handle('setMinSize', {'width': 400, 'height': -100}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('METHOD_NOT_FOUND', () {
    test('throws for unknown method', () {
      expect(
        () => service.handle('unknownMethod', {}),
        throwsA(
          isA<FluttronError>().having(
            (e) => e.code,
            'code',
            'METHOD_NOT_FOUND',
          ),
        ),
      );
    });

    test('throws for close (not implemented)', () {
      expect(
        () => service.handle('close', {}),
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

  // Note: The following methods delegate directly to window_manager platform
  // channels and cannot be tested in unit tests without a running macOS window.
  // They are verified through manual testing on macOS.
  //
  // Manual Test Checklist for macOS:
  // 1. window.setTitle - Pass a valid String; verify window title bar updates.
  // 2. window.setSize - Pass width:1024, height:768; verify window resizes.
  //    - Confirm double params work (e.g., width:800.5, height:600.5).
  // 3. window.getSize - Verify returned map has 'width' and 'height' int keys.
  // 4. window.minimize - Verify window minimises to Dock.
  // 5. window.maximize - Verify window zooms to full screen; call again to restore.
  // 6. window.setFullScreen - Pass enabled:true; verify full-screen mode.
  //    - Pass enabled:false; verify window returns to normal.
  // 7. window.isFullScreen - Verify returns {result: true} in full-screen mode
  //    and {result: false} otherwise.
  // 8. window.center - Verify window moves to center of screen.
  // 9. window.setMinSize - Pass width:400, height:300; verify window cannot
  //    be resized below those dimensions.
}
