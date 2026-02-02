import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for rootBundle
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttron_host/src/bridge/host_bridge.dart';
import 'package:fluttron_host/src/services/service_registry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final registry = ServiceRegistry();

  runApp(FluttronHostApp(registry: registry));
}

class FluttronHostApp extends StatelessWidget {
  const FluttronHostApp({super.key, required this.registry});

  final ServiceRegistry registry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttron Host',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FluttronBrowser(registry: registry),
    );
  }
}

class FluttronBrowser extends StatefulWidget {
  const FluttronBrowser({super.key, required this.registry});

  final ServiceRegistry registry;

  @override
  State<FluttronBrowser> createState() => _FluttronBrowserState();
}

class _FluttronBrowserState extends State<FluttronBrowser> {
  // Define scheme name
  static const String schemeName = 'fluttron';

  @override
  Widget build(BuildContext context) {
    final hostBridge = HostBridge();

    return Scaffold(
      body: InAppWebView(
        // 1. Change entry point to custom protocol
        initialUrlRequest: URLRequest(
          url: WebUri("$schemeName://local/index.html"),
        ),

        initialSettings: InAppWebViewSettings(
          isInspectable: true,
          // 2. Register custom protocol
          resourceCustomSchemes: [schemeName],
        ),

        onWebViewCreated: (controller) {
          hostBridge.attach(controller);
        },

        // 3. Core: Intercept request, return local Asset
        onLoadResourceWithCustomScheme: (controller, request) async {
          if (request.url.scheme == schemeName) {
            try {
              // Parse path: fluttron://local/index.html -> assets/www/index.html
              // request.url.path will have leading /, e.g. /index.html
              var path = request.url.path;
              if (path.isEmpty || path == "/") path = "/index.html";

              final assetPath = "assets/www$path";

              // Read binary data from Flutter Assets
              final data = await rootBundle.load(assetPath);
              final bytes = data.buffer.asUint8List();

              // Simple MIME type detection (MVP simplified version, production should use mime package)
              String contentType = "text/plain";
              if (assetPath.endsWith(".html")) {
                contentType = "text/html";
              } else if (assetPath.endsWith(".js")) {
                contentType = "application/javascript";
              } else if (assetPath.endsWith(".css")) {
                contentType = "text/css";
              } else if (assetPath.endsWith(".png")) {
                contentType = "image/png";
              } else if (assetPath.endsWith(".json")) {
                contentType = "application/json";
                // Flutter Web needs to load fonts and icons
              } else if (assetPath.endsWith(".ttf")) {
                contentType = "font/ttf";
              } else if (assetPath.endsWith(".woff")) {
                contentType = "font/woff";
              }

              // Return to WebView
              return CustomSchemeResponse(
                data: bytes,
                contentType: contentType,
                contentEncoding: "utf-8",
              );
            } catch (e) {
              debugPrint("Fluttron Load Error: $e");
              // Return null for 404 - the WebView will handle it as a network error
              return null;
            }
          }
          return null;
        },
      ),
    );
  }
}
