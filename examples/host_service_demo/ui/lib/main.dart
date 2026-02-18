import 'package:flutter/material.dart';
import 'package:fluttron_ui/fluttron_ui.dart';

void main() {
  runApp(const HostServiceDemoApp());
}

class HostServiceDemoApp extends StatelessWidget {
  const HostServiceDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Host Service Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DemoPage(),
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
  final _nameController = TextEditingController(text: 'Fluttron');
  final _echoController = TextEditingController(text: 'Hello from UI!');

  String _greetResult = '';
  String _echoResult = '';
  String _platform = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPlatform();
  }

  Future<void> _loadPlatform() async {
    try {
      final systemClient = SystemServiceClient(_client);
      final platform = await systemClient.getPlatform();
      if (mounted) {
        setState(() {
          _platform = platform;
        });
      }
    } catch (e) {
      // Ignore errors in demo
    }
  }

  Future<void> _callGreet() async {
    setState(() => _loading = true);
    try {
      final result = await _client.invoke('greeting.greet', {
        'name': _nameController.text,
      });
      if (mounted) {
        setState(() {
          _greetResult = result['message'] as String;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _greetResult = 'Error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _callEcho() async {
    setState(() => _loading = true);
    try {
      final result = await _client.invoke('greeting.echo', {
        'text': _echoController.text,
      });
      if (mounted) {
        setState(() {
          _echoResult =
              'Echo: ${result['text']}\n'
              'Timestamp: ${result['timestamp']}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _echoResult = 'Error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _echoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Service Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.computer),
                    const SizedBox(width: 12),
                    Text(
                      'Platform: ${_platform.isNotEmpty ? _platform : "Loading..."}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Greet service demo
            Text(
              'Custom Service: greeting.greet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _callGreet,
                  child: const Text('Call greet()'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _greetResult.isNotEmpty
                    ? _greetResult
                    : 'Result will appear here',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 24),

            // Echo service demo
            Text(
              'Custom Service: greeting.echo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _echoController,
                    decoration: const InputDecoration(
                      labelText: 'Text to echo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _callEcho,
                  child: const Text('Call echo()'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _echoResult.isNotEmpty
                    ? _echoResult
                    : 'Result will appear here',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),

            const Spacer(),

            // Architecture note
            Text(
              'This demo shows a custom Host service (GreetingService) '
              'registered in host/lib/main.dart and called from UI '
              'via FluttronClient.invoke().',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
