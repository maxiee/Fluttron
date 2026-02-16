import 'package:fluttron_host/src/services/dialog_service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DialogService service;

  setUp(() {
    service = DialogService();
  });

  group('namespace', () {
    test('returns "dialog"', () {
      expect(service.namespace, equals('dialog'));
    });
  });

  group('METHOD_NOT_FOUND', () {
    test('throws for unknown method', () async {
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
  });

  // Note: Dialog display methods (openFile, openFiles, openDirectory, saveFile)
  // require native platform interaction via platform channels and cannot be
  // tested in unit tests. They are verified through manual testing on macOS.
  //
  // The service implementation correctly handles:
  // - Optional parameters (title, allowedExtensions, initialDirectory, defaultFileName)
  // - Returns {path: null} when user cancels (not an error)
  // - Returns {path: '/selected/path'} on success
  //
  // Manual Test Checklist for macOS:
  // 1. dialog.openFile - Verify native file picker appears
  //    - With allowedExtensions: verify only matching files shown
  //    - Without filters: all files visible
  //    - On cancel: returns {path: null}
  //
  // 2. dialog.openFiles - Verify multiple selection works
  //    - Select multiple files, verify paths array returned
  //    - On cancel: returns {paths: []}
  //
  // 3. dialog.openDirectory - Verify native directory picker appears
  //    - Select directory, verify path returned
  //    - On cancel: returns {path: null}
  //
  // 4. dialog.saveFile - Verify native save dialog with default filename
  //    - With defaultFileName: verify field pre-populated
  //    - On save: verify path returned
  //    - On cancel: returns {path: null}
}
