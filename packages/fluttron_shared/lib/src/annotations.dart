/// Marks an abstract class as a Fluttron host service contract.
///
/// The code generator will produce:
/// 1. A `FluttronService` subclass with `switch/case` routing in the host package.
/// 2. A `ServiceClient` class with typed method wrappers in the client package.
///
/// Example:
/// ```dart
/// @FluttronServiceContract(namespace: 'weather')
/// abstract class WeatherService {
///   Future<WeatherInfo> getCurrentWeather(String city);
///   Future<List<WeatherForecast>> getForecast(String city, {int days = 5});
///   Future<bool> isAvailable();
/// }
/// ```
class FluttronServiceContract {
  /// The namespace used for `namespace.method` routing.
  ///
  /// Must be unique within the application's service registry.
  ///
  /// Example: `'weather'` routes methods like `weather.getCurrentWeather`.
  final String namespace;

  /// Creates a [FluttronServiceContract] annotation with the given [namespace].
  const FluttronServiceContract({required this.namespace});
}

/// Marks a class as a Fluttron model for serialization code generation.
///
/// The generator produces `fromMap()` factory and `toMap()` method
/// to handle JSON serialization over the Host/UI bridge.
///
/// Example:
/// ```dart
/// @FluttronModel()
/// class WeatherInfo {
///   final String city;
///   final double temperature;
///   final String condition;
///   final DateTime timestamp;
/// }
/// ```
class FluttronModel {
  /// Creates a [FluttronModel] annotation.
  const FluttronModel();
}
