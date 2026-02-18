/// Example service contract demonstrating @FluttronServiceContract and @FluttronModel.
///
/// This file serves as a compilation test and documentation example.
/// It will be used by the code generator in v0069+.
library;

import 'package:fluttron_shared/fluttron_shared.dart';

/// A sample weather service contract.
///
/// This demonstrates how to define a service contract:
/// - Use @FluttronServiceContract with a unique namespace
/// - Define abstract methods with typed parameters and return values
/// - Model classes are annotated with @FluttronModel
@FluttronServiceContract(namespace: 'weather')
abstract class WeatherService {
  /// Gets current weather for the given city.
  Future<WeatherInfo> getCurrentWeather(String city);

  /// Gets the forecast for the given city.
  ///
  /// [days] defaults to 5 if not specified.
  Future<List<WeatherForecast>> getForecast(String city, {int days = 5});

  /// Checks if the weather API is available.
  Future<bool> isAvailable();
}

/// Model class representing weather information.
@FluttronModel()
class WeatherInfo {
  final String city;
  final double temperature;
  final String condition;
  final DateTime timestamp;

  const WeatherInfo({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.timestamp,
  });
}

/// Model class representing a weather forecast.
@FluttronModel()
class WeatherForecast {
  final DateTime date;
  final double high;
  final double low;
  final String condition;

  const WeatherForecast({
    required this.date,
    required this.high,
    required this.low,
    required this.condition,
  });
}
