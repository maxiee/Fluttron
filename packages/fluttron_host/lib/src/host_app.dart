import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttron_host/src/bridge/host_bridge.dart';
import 'package:fluttron_host/src/services/clipboard_service.dart';
import 'package:fluttron_host/src/services/dialog_service.dart';
import 'package:fluttron_host/src/services/file_service.dart';
import 'package:fluttron_host/src/services/logging_service.dart';
import 'package:fluttron_host/src/services/service_registry.dart';
import 'package:fluttron_host/src/services/storage_service.dart';
import 'package:fluttron_host/src/services/system_service.dart';
import 'package:fluttron_host/src/services/window_service.dart';
import 'package:window_manager/window_manager.dart';

Future<void> runFluttronHost({ServiceRegistry? registry}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final serviceRegistry = registry ?? createDefaultServiceRegistry();

  runApp(FluttronHostApp(registry: serviceRegistry));
}

ServiceRegistry createDefaultServiceRegistry() {
  return ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(FileService())
    ..register(DialogService())
    ..register(ClipboardService())
    ..register(WindowService())
    ..register(LoggingService());
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
  static const String schemeName = 'fluttron';

  @override
  Widget build(BuildContext context) {
    final hostBridge = HostBridge(registry: widget.registry);

    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("$schemeName://local/index.html"),
        ),

        initialSettings: InAppWebViewSettings(
          isInspectable: true,
          resourceCustomSchemes: [schemeName],
        ),

        onWebViewCreated: (controller) {
          hostBridge.attach(controller);
        },

        onLoadResourceWithCustomScheme: (controller, request) async {
          if (request.url.scheme == schemeName) {
            try {
              var path = request.url.path;
              if (path.isEmpty || path == "/") path = "/index.html";

              final assetPath = "assets/www$path";

              final data = await rootBundle.load(assetPath);
              final bytes = data.buffer.asUint8List();

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
              } else if (assetPath.endsWith(".ttf")) {
                contentType = "font/ttf";
              } else if (assetPath.endsWith(".woff")) {
                contentType = "font/woff";
              }

              return CustomSchemeResponse(
                data: bytes,
                contentType: contentType,
                contentEncoding: "utf-8",
              );
            } catch (e) {
              debugPrint("Fluttron Load Error: $e");
              return null;
            }
          }
          return null;
        },
      ),
    );
  }
}
