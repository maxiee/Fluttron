import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `logging.*` Host service.
///
/// Provides structured logging from the UI side. Log output appears on the
/// host process stdout with timestamp and level.
///
/// Usage:
/// ```dart
/// final client = FluttronClient();
/// final logger = LoggingServiceClient(client);
/// await logger.info('File opened', data: {'path': '/docs/readme.md'});
/// await logger.error('Save failed', data: {'reason': 'disk full'});
/// ```
class LoggingServiceClient {
  /// Creates a [LoggingServiceClient] with the given [FluttronClient].
  LoggingServiceClient(this._client);

  final FluttronClient _client;

  /// Log a debug-level message.
  Future<void> debug(String message, {Map<String, dynamic>? data}) async {
    await _client.invoke('logging.log', {
      'level': 'debug',
      'message': message,
      'data': ?data,
    });
  }

  /// Log an info-level message.
  Future<void> info(String message, {Map<String, dynamic>? data}) async {
    await _client.invoke('logging.log', {
      'level': 'info',
      'message': message,
      'data': ?data,
    });
  }

  /// Log a warn-level message.
  Future<void> warn(String message, {Map<String, dynamic>? data}) async {
    await _client.invoke('logging.log', {
      'level': 'warn',
      'message': message,
      'data': ?data,
    });
  }

  /// Log an error-level message.
  Future<void> error(String message, {Map<String, dynamic>? data}) async {
    await _client.invoke('logging.log', {
      'level': 'error',
      'message': message,
      'data': ?data,
    });
  }

  /// Retrieve recent log entries from the host buffer.
  ///
  /// Optionally filter by [level] and/or limit to the [limit] most recent entries.
  Future<List<Map<String, dynamic>>> getLogs({
    String? level,
    int? limit,
  }) async {
    final result = await _client.invoke('logging.getLogs', {
      'level': ?level,
      'limit': ?limit,
    });
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Clear the host-side log buffer.
  Future<void> clear() async {
    await _client.invoke('logging.clear', {});
  }
}
