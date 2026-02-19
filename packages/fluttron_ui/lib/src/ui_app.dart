import 'dart:async';

import 'package:flutter/material.dart';

void runFluttronUi({
  String title = 'Fluttron App',
  required Widget home,
  bool debugBanner = false,
}) {
  // Catch uncaught Flutter framework errors (widget build errors, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint(
      '[Fluttron] [ERROR] Uncaught Flutter error: ${details.exceptionAsString()}\n${details.stack}',
    );
    FlutterError.presentError(details);
  };

  // Catch uncaught async/Dart errors thrown outside the Flutter framework
  runZonedGuarded(
    () => runApp(
      FluttronUiApp(title: title, home: home, debugBanner: debugBanner),
    ),
    (Object error, StackTrace stack) {
      debugPrint('[Fluttron] [ERROR] Uncaught async error: $error\n$stack');
    },
  );
}

class FluttronUiApp extends StatelessWidget {
  const FluttronUiApp({
    super.key,
    this.title = 'Fluttron App',
    required this.home,
    this.debugBanner = false,
  });

  final String title;
  final Widget home;
  final bool debugBanner;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      home: home,
      debugShowCheckedModeBanner: debugBanner,
    );
  }
}
