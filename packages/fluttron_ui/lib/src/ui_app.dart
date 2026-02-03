import 'package:flutter/material.dart';
import 'package:fluttron_ui/fluttron/fluttron_client.dart';

void runFluttronUi() {
  runApp(const FluttronUiApp());
}

class FluttronUiApp extends StatelessWidget {
  const FluttronUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttron UI',
      home: const DemoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _client = FluttronClient();

  String _platform = '-';
  String _kvValue = '-';
  String _log = '';

  void _setLog(String s) {
    setState(() => _log = s);
  }

  Future<void> _onGetPlatform() async {
    try {
      final p = await _client.getPlatform();
      setState(() => _platform = p);
      _setLog('getPlatform => $p');
    } catch (e) {
      _setLog('getPlatform ERROR: $e');
    }
  }

  Future<void> _onKvSet() async {
    try {
      await _client.kvSet('hello', 'world');
      _setLog('kvSet hello=world => ok');
    } catch (e) {
      _setLog('kvSet ERROR: $e');
    }
  }

  Future<void> _onKvGet() async {
    try {
      final v = await _client.kvGet('hello');
      setState(() => _kvValue = v ?? '(null)');
      _setLog('kvGet hello => ${v ?? "(null)"}');
    } catch (e) {
      _setLog('kvGet ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fluttron UI Demo')),
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
