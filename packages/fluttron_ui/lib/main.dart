import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

void main() {
  runFluttronUi(title: 'Fluttron UI', home: const PackageDemoPage());
}

class PackageDemoPage extends StatefulWidget {
  const PackageDemoPage({super.key});

  @override
  State<PackageDemoPage> createState() => _PackageDemoPageState();
}

class _PackageDemoPageState extends State<PackageDemoPage> {
  final FluttronClient _client = FluttronClient();

  String _platform = '-';
  String _kvValue = '-';
  String _log = '';

  void _setLog(String message) {
    setState(() => _log = message);
  }

  Future<void> _onGetPlatform() async {
    try {
      final platform = await _client.getPlatform();
      setState(() => _platform = platform);
      _setLog('getPlatform => $platform');
    } catch (error) {
      _setLog('getPlatform ERROR: $error');
    }
  }

  Future<void> _onKvSet() async {
    try {
      await _client.kvSet('hello', 'world');
      _setLog('kvSet hello=world => ok');
    } catch (error) {
      _setLog('kvSet ERROR: $error');
    }
  }

  Future<void> _onKvGet() async {
    try {
      final value = await _client.kvGet('hello');
      setState(() => _kvValue = value ?? '(null)');
      _setLog('kvGet hello => ${value ?? "(null)"}');
    } catch (error) {
      _setLog('kvGet ERROR: $error');
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
