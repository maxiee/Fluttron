import 'package:fluttron_host/src/services/service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter/services.dart';

/// Host service for system clipboard operations.
///
/// Provides methods for reading and writing text to the system clipboard.
/// Uses Flutter's built-in Clipboard class.
class ClipboardService extends FluttronService {
  @override
  String get namespace => 'clipboard';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'getText':
        return _getText(params);
      case 'setText':
        return _setText(params);
      case 'hasText':
        return _hasText(params);
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'clipboard.$method not implemented',
        );
    }
  }

  /// Reads text from the system clipboard.
  ///
  /// Params: none
  ///
  /// Returns:
  /// - text: Clipboard text content, or null if no text available.
  Future<Map<String, dynamic>> _getText(Map<String, dynamic> params) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return {'text': data?.text};
  }

  /// Writes text to the system clipboard.
  ///
  /// Params:
  /// - text: (required) Text to write to clipboard.
  ///
  /// Returns: empty object on success.
  Future<Map<String, dynamic>> _setText(Map<String, dynamic> params) async {
    final text = _requireString(params, 'text');
    await Clipboard.setData(ClipboardData(text: text));
    return {};
  }

  /// Checks if the clipboard has text content.
  ///
  /// Params: none
  ///
  /// Returns:
  /// - hasText: Whether clipboard has text content.
  Future<Map<String, dynamic>> _hasText(Map<String, dynamic> params) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final hasText = data?.text != null && data!.text!.isNotEmpty;
    return {'hasText': hasText};
  }

  /// Helper to require a string parameter.
  String _requireString(Map<String, dynamic> params, String key) {
    final v = params[key];
    if (v is String) return v;
    throw FluttronError('BAD_PARAMS', 'Missing or invalid "$key"');
  }
}
