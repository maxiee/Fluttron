import 'package:fluttron_host/fluttron_host.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

/// A custom Host service demonstrating the service pattern.
///
/// This service provides greeting and echo functionality.
/// It is registered in [main.dart] and called from the UI layer.
class GreetingService extends FluttronService {
  @override
  String get namespace => 'greeting';

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
          'greeting.$method not implemented',
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
    return {'message': 'Hello, $name! Welcome to Fluttron.'};
  }

  /// Echoes back the input text with a timestamp.
  ///
  /// Params:
  /// - text: (required) Text to echo.
  ///
  /// Returns:
  /// - text: The echoed text.
  /// - timestamp: Server-side timestamp.
  Map<String, dynamic> _echo(Map<String, dynamic> params) {
    final text = params['text'];
    if (text is! String || text.isEmpty) {
      throw FluttronError('BAD_PARAMS', 'Missing or empty "text" parameter');
    }
    return {'text': text, 'timestamp': DateTime.now().toIso8601String()};
  }
}
