import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_editor_host/main.dart' as app;

void main() {
  test('host entrypoint is available', () {
    expect(app.main, isA<Function>());
  });
}
