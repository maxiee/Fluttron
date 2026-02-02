import 'package:flutter/material.dart';

import 'src/bridge/renderer_bridge.dart';

void main() {
  runApp(const FluttronApp());
}

class FluttronApp extends StatelessWidget {
  const FluttronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttron Renderer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final _bridge = RendererBridge();

  String _status = 'Waiting for Host...';
  bool _loading = false;

  Future<void> _getPlatform() async {
    setState(() {
      _loading = true;
      _status = 'Calling Host...';
    });

    try {
      final result = await _bridge.invoke('system.getPlatform', {});
      setState(() {
        _status = 'OK: $result';
      });
    } catch (e) {
      setState(() {
        _status = 'ERROR: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              'Hello from Fluttron Renderer!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'I am a Flutter Web app running inside...',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _getPlatform,
              child: Text(_loading ? 'Loading...' : 'system.getPlatform'),
            ),
            const SizedBox(height: 16),
            Chip(label: Text(_status)),
          ],
        ),
      ),
    );
  }
}
