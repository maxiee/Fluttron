import 'package:fluttron_host/fluttron_host.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

/// Host-side implementation of the TemplateService.
///
/// Register this service in your host app's main.dart:
///
/// ```dart
/// import 'package:template_service_host/template_service_host.dart';
///
/// void main() {
///   final registry = ServiceRegistry()
///     ..register(SystemService())
///     ..register(StorageService())
///     ..register(TemplateService()); // Add your service
///
///   runFluttronHost(registry: registry);
/// }
/// ```
class TemplateService extends FluttronService {
  @override
  String get namespace => 'template_service';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'greet':
        return _greet(params);
      case 'echo':
        return _echo(params);
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'template_service.$method not implemented',
        );
    }
  }

  /// Returns a greeting message.
  ///
  /// Params:
  /// - name: (optional) Name to greet. Defaults to 'World'.
  ///
  /// Returns:
  /// - message: The greeting message.
  Map<String, dynamic> _greet(Map<String, dynamic> params) {
    final name = params['name'] as String? ?? 'World';
    return {'message': 'Hello, $name!'};
  }

  /// Echoes back the input text.
  ///
  /// Params:
  /// - text: (required) Text to echo.
  ///
  /// Returns:
  /// - text: The echoed text.
  Map<String, dynamic> _echo(Map<String, dynamic> params) {
    final text = params['text'];
    if (text is! String || text.isEmpty) {
      throw FluttronError('BAD_PARAMS', 'Missing or empty "text" parameter');
    }
    return {'text': text};
  }
}
