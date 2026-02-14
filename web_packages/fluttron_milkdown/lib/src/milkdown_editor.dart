import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

class MilkdownEditor extends StatelessWidget {
  const MilkdownEditor({
    super.key,
    this.initialMarkdown = '',
    this.readonly = false,
    this.onChanged,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String initialMarkdown;
  final bool readonly;
  final ValueChanged<String>? onChanged;
  final WidgetBuilder? loadingBuilder;
  final FluttronHtmlViewErrorBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return FluttronHtmlView(
      type: 'milkdown.editor',
      args: <dynamic>[
        <String, dynamic>{
          'initialMarkdown': initialMarkdown,
          'theme': 'frame',
          'readonly': readonly,
        },
      ],
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
