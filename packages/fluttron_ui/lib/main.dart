import 'package:flutter/material.dart';

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
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text(
                'Hello from Fluttron Renderer!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'I am a Flutter Web app running inside...',
                style: TextStyle(color: Colors.grey),
              ),
              // 这里未来会显示 Host 传来的版本号
              Chip(label: Text('Waiting for Host...')),
            ],
          ),
        ),
      ),
    );
  }
}
