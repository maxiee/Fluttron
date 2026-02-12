import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

class TemplatePackageExampleWidget extends StatelessWidget {
  const TemplatePackageExampleWidget({
    super.key,
    this.initialContent = '',
    this.onContentChanged,
  });

  final String initialContent;
  final ValueChanged<Map<String, dynamic>>? onContentChanged;

  @override
  Widget build(BuildContext context) {
    return FluttronHtmlView(
      type: 'template_package.example',
      args: [initialContent],
    );
  }
}

Stream<Map<String, dynamic>> templatePackageExampleChanges() {
  return FluttronEventBridge()
      .on('fluttron.template_package.example.change')
      .map((event) => Map<String, dynamic>.from(event as Map));
}
