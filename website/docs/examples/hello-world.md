# Hello World Example

This is a complete Hello World example demonstrating the basic Fluttron setup and communication between Host and Renderer.

## Prerequisites

- Flutter SDK (3.19.0+)
- Fluttron repository cloned

## Step 1: Build Renderer (Flutter Web)

```bash
cd packages/fluttron_ui
./build.sh
```

This compiles the Flutter Web app and copies artifacts to `../fluttron_host/assets/www`.

## Step 2: Run Host

```bash
cd ../fluttron_host
./run.sh
```

This launches the Fluttron Host application, which loads the WebView with the Flutter Web app.

## What You'll See

The demo application demonstrates:

1. **Platform Information**: Display current OS (macOS, Linux, Windows)
2. **Storage Operations**: Set and get key-value pairs
3. **Real-time Communication**: Bidirectional IPC between Host and Renderer

## Code Structure

### Renderer (Flutter Web)

```dart
// packages/fluttron_ui/lib/main.dart
import 'package:flutter/material.dart';
import 'fluttron/fluttron_client.dart';

void main() async {
  await FluttronClient.initialize();
  runApp(FluttronApp());
}

class FluttronApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttron Hello World',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  String _platform = 'Loading...';
  String _storedValue = 'Click "Load" to retrieve value';

  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlatform();
  }

  Future<void> _loadPlatform() async {
    try {
      final platform = await FluttronClient.getPlatform();
      setState(() => _platform = platform);
    } catch (e) {
      setState(() => _platform = 'Error: $e');
    }
  }

  Future<void> _storeValue() async {
    try {
      await FluttronClient.kvSet(
        _keyController.text,
        _valueController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Value stored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error storing value: $e')),
      );
    }
  }

  Future<void> _loadValue() async {
    try {
      final value = await FluttronClient.kvGet(_keyController.text);
      setState(() => _storedValue = value ?? 'Key not found');
    } catch (e) {
      setState(() => _storedValue = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fluttron Hello World'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Platform Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.computer, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Platform: $_platform',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Storage Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key-Value Storage',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _keyController,
                      decoration: InputDecoration(
                        labelText: 'Key',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.key),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _valueController,
                      decoration: InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _storeValue,
                            icon: Icon(Icons.save),
                            label: Text('Store'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loadValue,
                            icon: Icon(Icons.download),
                            label: Text('Load'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stored Value: $_storedValue',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}
```

### Host (Flutter Desktop)

```dart
// packages/fluttron_host/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'service_registry.dart';
import 'services/system_service.dart';
import 'services/storage_service.dart';
import 'host_bridge.dart';

void main() {
  final serviceRegistry = ServiceRegistry();

  serviceRegistry.register(SystemService());
  serviceRegistry.register(StorageService());

  runApp(FluttronHost(serviceRegistry: serviceRegistry));
}

class FluttronHost extends StatelessWidget {
  final ServiceRegistry serviceRegistry;

  const FluttronHost({Key? key, required this.serviceRegistry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttron Host',
      theme: ThemeData.dark(),
      home: WebViewPage(serviceRegistry: serviceRegistry),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebViewPage extends StatefulWidget {
  final ServiceRegistry serviceRegistry;

  const WebViewPage({Key? key, required this.serviceRegistry})
      : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _webViewController;
  final HostBridge _hostBridge = HostBridge();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: Uri.parse('file:///assets/www/index.html'),
        ),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            transparentBackground: true,
          ),
        ),
        onLoadStop: (controller, url) {
          _hostBridge.setup(controller, widget.serviceRegistry);
        },
      ),
    );
  }
}
```

## Key Points

1. **Separation of Concerns**: Host manages services, Renderer manages UI
2. **IPC Communication**: All communication goes through JavaScript Handler
3. **Type Safety**: Shared protocol definitions ensure type safety
4. **Error Handling**: Both layers handle errors gracefully

## Next Steps

- [Architecture Overview](../architecture/overview.md) - Learn about Fluttron architecture
- [API Reference](../api/services.md) - Learn to create custom services
