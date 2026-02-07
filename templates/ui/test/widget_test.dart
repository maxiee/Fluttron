import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluttron_ui_app/main.dart';

void main() {
  testWidgets('Template demo renders loading and base sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: TemplateDemoPage()));

    expect(find.text('Fluttron UI Template Demo'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.text('External HTML/JS Embed:'), findsOneWidget);
    expect(find.text('Editor Event:'), findsOneWidget);
    expect(find.text('Get Platform'), findsOneWidget);
    expect(find.text('Set KV'), findsOneWidget);
    expect(find.text('Get KV'), findsOneWidget);
    expect(find.textContaining('Platform:'), findsOneWidget);
    expect(find.textContaining('KV("hello"):'), findsOneWidget);
  });
}
