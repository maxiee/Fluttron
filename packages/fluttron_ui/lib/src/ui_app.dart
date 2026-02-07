import 'package:flutter/material.dart';

void runFluttronUi({
  String title = 'Fluttron App',
  required Widget home,
  bool debugBanner = false,
}) {
  runApp(FluttronUiApp(title: title, home: home, debugBanner: debugBanner));
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
