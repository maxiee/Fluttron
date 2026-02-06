import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

const String _externalHtmlViewType = 'fluttron.template.external_html_view';
const String _createTemplateHtmlViewMethod = 'fluttronCreateTemplateHtmlView';

bool _externalHtmlViewFactoryRegistered = false;

void _registerExternalHtmlViewFactoryOnce() {
  if (_externalHtmlViewFactoryRegistered) {
    return;
  }

  ui_web.platformViewRegistry.registerViewFactory(_externalHtmlViewType, (
    int viewId,
  ) {
    final JSObject global = globalContext;
    final JSAny? viewElement = global.callMethodVarArgs<JSAny?>(
      _createTemplateHtmlViewMethod.toJS,
      <JSAny?>[viewId.toJS],
    );

    if (viewElement == null) {
      throw StateError('$_createTemplateHtmlViewMethod returned null.');
    }
    return viewElement;
  });

  _externalHtmlViewFactoryRegistered = true;
}

void main() {
  runApp(const TemplateUiApp());
}

class TemplateUiApp extends StatelessWidget {
  const TemplateUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttron UI Template',
      home: const TemplateDemoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TemplateDemoPage extends StatefulWidget {
  const TemplateDemoPage({super.key});

  @override
  State<TemplateDemoPage> createState() => _TemplateDemoPageState();
}

class _TemplateDemoPageState extends State<TemplateDemoPage> {
  final FluttronClient _client = FluttronClient();

  String _platform = '-';
  String _kvValue = '-';
  String _log = '';
  String? _htmlEmbedError;
  bool _isHtmlEmbedReady = false;

  @override
  void initState() {
    super.initState();
    try {
      _registerExternalHtmlViewFactoryOnce();
      _isHtmlEmbedReady = true;
    } catch (error) {
      _htmlEmbedError = error.toString();
      _log = 'HtmlElementView registration error: $error';
    }
  }

  void _setLog(String message) {
    setState(() => _log = message);
  }

  Future<void> _onGetPlatform() async {
    try {
      final platform = await _client.getPlatform();
      setState(() => _platform = platform);
      _setLog('getPlatform => $platform');
    } catch (error) {
      _setLog('getPlatform error: $error');
    }
  }

  Future<void> _onKvSet() async {
    try {
      await _client.kvSet('hello', 'world');
      _setLog('kvSet hello=world => ok');
    } catch (error) {
      _setLog('kvSet error: $error');
    }
  }

  Future<void> _onKvGet() async {
    try {
      final value = await _client.kvGet('hello');
      setState(() => _kvValue = value ?? '(null)');
      _setLog('kvGet hello => ${value ?? "(null)"}');
    } catch (error) {
      _setLog('kvGet error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fluttron UI Template Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform: $_platform', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'KV("hello"): $_kvValue',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _onGetPlatform,
                  child: const Text('Get Platform'),
                ),
                ElevatedButton(
                  onPressed: _onKvSet,
                  child: const Text('Set KV'),
                ),
                ElevatedButton(
                  onPressed: _onKvGet,
                  child: const Text('Get KV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'External HTML/JS Embed:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              height: 240,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isHtmlEmbedReady
                  ? const HtmlElementView(viewType: _externalHtmlViewType)
                  : SelectableText(
                      _htmlEmbedError ?? 'HtmlElementView is not ready.',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
            ),
            const SizedBox(height: 16),
            const Text('Log:'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(child: Text(_log)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
