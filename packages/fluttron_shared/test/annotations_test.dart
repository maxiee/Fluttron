import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:test/test.dart';

// Import the example contract to verify it compiles
import 'fixtures/example_weather_contract.dart';

void main() {
  group('FluttronServiceContract', () {
    test('creates with namespace', () {
      const annotation = FluttronServiceContract(namespace: 'weather');
      expect(annotation.namespace, equals('weather'));
    });

    test('is a const constructor', () {
      // Verify it can be used as a const annotation
      const annotation = FluttronServiceContract(namespace: 'test');
      expect(annotation.namespace, equals('test'));
    });

    test('different namespaces are distinct', () {
      const annotation1 = FluttronServiceContract(namespace: 'weather');
      const annotation2 = FluttronServiceContract(namespace: 'file');
      const annotation3 = FluttronServiceContract(namespace: 'weather');

      expect(annotation1.namespace, isNot(equals(annotation2.namespace)));
      expect(annotation1.namespace, equals(annotation3.namespace));
    });
  });

  group('FluttronModel', () {
    test('creates with const constructor', () {
      const annotation = FluttronModel();
      expect(annotation, isA<FluttronModel>());
    });

    test('multiple instances are equivalent', () {
      const annotation1 = FluttronModel();
      const annotation2 = FluttronModel();

      // Both are const, should be the same
      expect(identical(annotation1, annotation2), isTrue);
    });
  });

  group('Annotation exports', () {
    test('FluttronServiceContract is exported from fluttron_shared', () {
      // This verifies the annotation is properly exported
      const annotation = FluttronServiceContract(namespace: 'test');
      expect(annotation, isNotNull);
    });

    test('FluttronModel is exported from fluttron_shared', () {
      // This verifies the annotation is properly exported
      const annotation = FluttronModel();
      expect(annotation, isNotNull);
    });
  });

  group('Example contract compilation', () {
    test('WeatherService compiles with annotation', () {
      // If this test runs, the example contract compiled successfully
      // The contract is imported at the top of this file
      expect(true, isTrue);
    });

    test('WeatherInfo model compiles with annotation', () {
      final info = WeatherInfo(
        city: 'San Francisco',
        temperature: 18.5,
        condition: 'Sunny',
        timestamp: DateTime.parse('2026-02-17T10:00:00Z'),
      );
      expect(info.city, equals('San Francisco'));
      expect(info.temperature, equals(18.5));
      expect(info.condition, equals('Sunny'));
    });

    test('WeatherForecast model compiles with annotation', () {
      final forecast = WeatherForecast(
        date: DateTime.parse('2026-02-18T00:00:00Z'),
        high: 22.0,
        low: 15.0,
        condition: 'Partly Cloudy',
      );
      expect(forecast.high, equals(22.0));
      expect(forecast.low, equals(15.0));
      expect(forecast.condition, equals('Partly Cloudy'));
    });
  });
}
