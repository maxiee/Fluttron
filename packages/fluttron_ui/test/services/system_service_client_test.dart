import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'file_service_client_test.dart' show FakeFluttronClient;

void main() {
  late FakeFluttronClient mockClient;
  late SystemServiceClient systemService;

  setUp(() {
    mockClient = FakeFluttronClient();
    systemService = SystemServiceClient(mockClient);
  });

  group('SystemServiceClient', () {
    test('getPlatform invokes system.getPlatform with empty params', () async {
      mockClient.whenInvoke('system.getPlatform', (params) {
        expect(params, isEmpty);
        return {'platform': 'macos'};
      });

      final platform = await systemService.getPlatform();
      expect(platform, equals('macos'));
    });

    test('getPlatform returns "unknown" when result is null', () async {
      mockClient.whenInvoke('system.getPlatform', (params) {
        return null;
      });

      final platform = await systemService.getPlatform();
      expect(platform, equals('unknown'));
    });

    test('getPlatform handles Map without platform key', () async {
      mockClient.whenInvoke('system.getPlatform', (params) {
        return {'other': 'value'};
      });

      final platform = await systemService.getPlatform();
      expect(platform, equals('unknown'));
    });

    test('getPlatform handles non-Map result', () async {
      mockClient.whenInvoke('system.getPlatform', (params) {
        return 'linux';
      });

      final platform = await systemService.getPlatform();
      expect(platform, equals('linux'));
    });

    test('getPlatform handles windows platform', () async {
      mockClient.whenInvoke('system.getPlatform', (params) {
        return {'platform': 'windows'};
      });

      final platform = await systemService.getPlatform();
      expect(platform, equals('windows'));
    });

    test('getPlatform handles android platform', () async {
      mockClient.whenInvoke('system.getPlatform', (params) {
        return {'platform': 'android'};
      });

      final platform = await systemService.getPlatform();
      expect(platform, equals('android'));
    });

    test('getPlatform handles ios platform', () async {
      mockClient.whenInvoke('system.getPlatform', (params) {
        return {'platform': 'ios'};
      });

      final platform = await systemService.getPlatform();
      expect(platform, equals('ios'));
    });
  });
}
