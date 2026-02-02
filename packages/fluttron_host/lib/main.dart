import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FluttronHostApp());
}

class FluttronHostApp extends StatelessWidget {
  const FluttronHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttron Host',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FluttronBrowser(),
    );
  }
}

class FluttronBrowser extends StatefulWidget {
  const FluttronBrowser({super.key});

  @override
  State<FluttronBrowser> createState() => _FluttronBrowserState();
}

class _FluttronBrowserState extends State<FluttronBrowser> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("https://flutter.dev")),
        initialSettings: InAppWebViewSettings(
          isInspectable: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStop: (controller, url) {
          debugPrint("Fluttron: Page loaded: $url");
        },
      ),
    );
  }
}
