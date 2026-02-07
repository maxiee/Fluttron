import 'package:fluttron_ui/src/ui_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FluttronUiApp renders provided home and title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const FluttronUiApp(title: 'My App', home: _TestHome()),
    );

    expect(find.text('Test Home'), findsOneWidget);
    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.title, 'My App');
  });

  testWidgets('FluttronUiApp maps debugBanner=false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const FluttronUiApp(
        title: 'Debug Off',
        home: SizedBox.shrink(),
        debugBanner: false,
      ),
    );

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.debugShowCheckedModeBanner, isFalse);
  });

  testWidgets('FluttronUiApp maps debugBanner=true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const FluttronUiApp(
        title: 'Debug On',
        home: SizedBox.shrink(),
        debugBanner: true,
      ),
    );

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.debugShowCheckedModeBanner, isTrue);
  });

  testWidgets('runFluttronUi boots app with provided home', (
    WidgetTester tester,
  ) async {
    runFluttronUi(
      title: 'Boot App',
      home: const Scaffold(body: Text('Boot Home')),
    );

    await tester.pump();

    expect(find.text('Boot Home'), findsOneWidget);
    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.title, 'Boot App');
  });
}

class _TestHome extends StatelessWidget {
  const _TestHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Test Home'));
  }
}
