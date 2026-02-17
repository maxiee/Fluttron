import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the TemplateService host service.
///
/// Usage in your UI code:
///
/// ```dart
/// final client = FluttronClient();
/// final templateService = TemplateServiceClient(client);
/// final greeting = await templateService.greet(name: 'Alice');
/// ```
class TemplateServiceClient {
  /// Creates a [TemplateServiceClient] with the given [FluttronClient].
  TemplateServiceClient(this._client);

  final FluttronClient _client;

  /// Returns a greeting message.
  ///
  /// [name] — optional name to greet. If omitted, defaults to 'World'.
  Future<String> greet({String? name}) async {
    final params = <String, dynamic>{};
    if (name != null) params['name'] = name;
    final result = await _client.invoke('template_service.greet', params);
    return result['message'] as String;
  }

  /// Echoes back the input [text].
  Future<String> echo(String text) async {
    final result = await _client.invoke('template_service.echo', {
      'text': text,
    });
    return result['text'] as String;
  }
}
