import 'dart:async';

import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';
import 'generated/web_package_registrations.dart';

const String _templateEditorWebViewType = 'fluttron.template.editor';
const String _createTemplateEditorViewMethod =
    'fluttronCreateTemplateEditorView';
const String _templateEditorChangeEventName = 'fluttron.template.editor.change';
const String _templateInitialText =
    'Hello from external HTML/JS.\n\nEdit this text to verify event bridge sync.';

void main() {
  registerFluttronWebPackages();
  _registerTemplateWebViews();
  // Error boundaries (FlutterError.onError + runZonedGuarded) are set up
  // automatically inside runFluttronUi().
  runFluttronUi(title: 'Fluttron UI Template', home: const TemplateDemoPage());
}

void _registerTemplateWebViews() {
  FluttronWebViewRegistry.register(
    const FluttronWebViewRegistration(
      type: _templateEditorWebViewType,
      jsFactoryName: _createTemplateEditorViewMethod,
    ),
  );
}

class TemplateDemoPage extends StatefulWidget {
  const TemplateDemoPage({super.key});

  @override
  State<TemplateDemoPage> createState() => _TemplateDemoPageState();
}

class _TemplateDemoPageState extends State<TemplateDemoPage> {
  final FluttronClient _client = FluttronClient();
  final FluttronEventBridge _eventBridge = FluttronEventBridge();

  StreamSubscription<Map<String, dynamic>>? _templateChangeSubscription;

  String _platform = '-';
  String _kvValue = '-';
  String _log = '';

  String _editorContent = _templateInitialText;
  int _editorCharacterCount = _templateInitialText.length;
  String _editorUpdatedAt = '-';

  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _detachTemplateEditorChangeListener();
    _eventBridge.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadPlatform();

    try {
      _attachTemplateEditorChangeListener();
    } catch (error) {
      _setLog('Template event listener registration error: $error');
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isBootstrapping = false;
    });
  }

  Future<void> _loadPlatform() async {
    try {
      final String platform = await _client.getPlatform();
      if (!mounted) {
        return;
      }
      setState(() {
        _platform = platform;
      });
    } catch (error) {
      _setLog('getPlatform error: $error');
    }
  }

  void _attachTemplateEditorChangeListener() {
    if (_templateChangeSubscription != null) {
      return;
    }

    _templateChangeSubscription = _eventBridge
        .on(_templateEditorChangeEventName)
        .listen(_handleTemplateEditorChangeEventDetail);
  }

  void _detachTemplateEditorChangeListener() {
    final StreamSubscription<Map<String, dynamic>>? subscription =
        _templateChangeSubscription;
    if (subscription == null) {
      return;
    }
    _templateChangeSubscription = null;
    unawaited(subscription.cancel());
  }

  void _handleTemplateEditorChangeEventDetail(Map<String, dynamic> detail) {
    if (!mounted) {
      return;
    }

    final String content = detail['content']?.toString() ?? '';
    final Object? rawCharacterCount = detail['characterCount'];
    final int characterCount = rawCharacterCount is num
        ? rawCharacterCount.toInt()
        : content.length;
    final String updatedAt = detail['updatedAt']?.toString() ?? '-';

    setState(() {
      _editorContent = content;
      _editorCharacterCount = characterCount;
      _editorUpdatedAt = updatedAt;
      _log = 'template editor change => ${content.length} chars';
    });
  }

  Future<void> _onGetPlatform() async {
    try {
      final String platform = await _client.getPlatform();
      if (!mounted) {
        return;
      }
      setState(() {
        _platform = platform;
      });
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
      final String? value = await _client.kvGet('hello');
      if (!mounted) {
        return;
      }
      setState(() {
        _kvValue = value ?? '(null)';
      });
      _setLog('kvGet hello => ${value ?? "(null)"}');
    } catch (error) {
      _setLog('kvGet error: $error');
    }
  }

  void _setLog(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _log = message;
    });
  }

  String _buildEditorPreview() {
    if (_editorContent.trim().isEmpty) {
      return '(empty content)';
    }

    const int maxPreviewLength = 240;
    if (_editorContent.length <= maxPreviewLength) {
      return _editorContent;
    }
    return '${_editorContent.substring(0, maxPreviewLength)}\n...';
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
              runSpacing: 8,
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
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isBootstrapping
                  ? const Center(child: CircularProgressIndicator())
                  : FluttronHtmlView(
                      type: _templateEditorWebViewType,
                      args: const <dynamic>[_templateInitialText],
                      loadingBuilder: (BuildContext context) {
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (BuildContext context, Object error) {
                        return SelectableText(
                          error.toString(),
                          style: const TextStyle(color: Colors.redAccent),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Editor Event:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Characters: $_editorCharacterCount'),
                  Text('Last updated: $_editorUpdatedAt'),
                  const SizedBox(height: 8),
                  const Text('Preview:'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 64,
                    child: SingleChildScrollView(
                      child: SelectableText(_buildEditorPreview()),
                    ),
                  ),
                ],
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
                child: SingleChildScrollView(child: SelectableText(_log)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
