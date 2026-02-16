import 'package:fluttron_ui/fluttron_ui.dart';

import 'app.dart';
import 'generated/web_package_registrations.dart';

void main() {
  registerFluttronWebPackages();
  runFluttronUi(title: 'Markdown Editor', home: const MarkdownEditorApp());
}
