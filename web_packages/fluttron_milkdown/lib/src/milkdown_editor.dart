import 'dart:async';

import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

import 'milkdown_controller.dart';
import 'milkdown_events.dart';
import 'milkdown_theme.dart';

/// A WYSIWYG markdown editor widget powered by Milkdown.
///
/// This widget embeds a Milkdown editor in a WebView and provides
/// event callbacks and optional controller for runtime manipulation.
///
/// Example:
/// ```dart
/// final controller = MilkdownController();
///
/// MilkdownEditor(
///   controller: controller,
///   initialMarkdown: '# Hello World',
///   theme: MilkdownTheme.nord,
///   onChanged: (event) => print('Content changed: ${event.markdown}'),
///   onReady: () => print('Editor ready'),
/// );
/// ```
class MilkdownEditor extends StatefulWidget {
  const MilkdownEditor({
    super.key,
    this.controller,
    this.initialMarkdown = '',
    this.theme = MilkdownTheme.frame,
    this.readonly = false,
    this.onChanged,
    this.onReady,
    this.onFocus,
    this.onBlur,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// Optional controller for runtime editor manipulation.
  ///
  /// When provided, the controller will be automatically attached
  /// when the editor becomes ready and detached when disposed.
  final MilkdownController? controller;

  /// Initial markdown content to display.
  final String initialMarkdown;

  /// The visual theme for the editor.
  ///
  /// Defaults to [MilkdownTheme.frame]. Can be changed at runtime
  /// via [MilkdownController.setTheme].
  final MilkdownTheme theme;

  /// Whether the editor starts in readonly mode.
  final bool readonly;

  /// Called when the editor content changes.
  final ValueChanged<MilkdownChangeEvent>? onChanged;

  /// Called when the editor is ready for interaction.
  ///
  /// When a [controller] is provided, it will be attached before
  /// this callback is invoked.
  final VoidCallback? onReady;

  /// Called when the editor gains focus.
  final VoidCallback? onFocus;

  /// Called when the editor loses focus.
  final VoidCallback? onBlur;

  /// Builder for the loading widget while the editor initializes.
  final WidgetBuilder? loadingBuilder;

  /// Builder for the error widget if the editor fails to initialize.
  final FluttronHtmlViewErrorBuilder? errorBuilder;

  @override
  State<MilkdownEditor> createState() => _MilkdownEditorState();
}

class _MilkdownEditorState extends State<MilkdownEditor> {
  final FluttronEventBridge _eventBridge = FluttronEventBridge();
  int? _viewId;

  StreamSubscription<MilkdownChangeEvent>? _changeSubscription;
  StreamSubscription<int>? _readySubscription;
  StreamSubscription<int>? _focusSubscription;
  StreamSubscription<int>? _blurSubscription;

  @override
  void initState() {
    super.initState();
    _attachListeners();
  }

  @override
  void dispose() {
    _detachController();
    _detachListeners();
    _eventBridge.dispose();
    super.dispose();
  }

  void _attachListeners() {
    _changeSubscription = milkdownEditorChanges().listen(_handleChange);
    _readySubscription = milkdownEditorReady().listen(_handleReady);
    _focusSubscription = milkdownEditorFocus().listen(_handleFocus);
    _blurSubscription = milkdownEditorBlur().listen(_handleBlur);
  }

  void _detachListeners() {
    _changeSubscription?.cancel();
    _readySubscription?.cancel();
    _focusSubscription?.cancel();
    _blurSubscription?.cancel();
    _changeSubscription = null;
    _readySubscription = null;
    _focusSubscription = null;
    _blurSubscription = null;
  }

  void _detachController() {
    final MilkdownController? controller = widget.controller;
    if (controller != null && controller.isAttached) {
      controller.detach();
    }
  }

  void _handleChange(MilkdownChangeEvent event) {
    if (_viewId != null && event.viewId != _viewId) {
      return;
    }
    widget.onChanged?.call(event);
  }

  void _handleReady(int viewId) {
    _viewId ??= viewId;
    if (_viewId != null && viewId != _viewId) {
      return;
    }

    // Attach controller before invoking onReady callback
    final MilkdownController? controller = widget.controller;
    if (controller != null && !controller.isAttached) {
      controller.attach(viewId);
    }

    widget.onReady?.call();
  }

  void _handleFocus(int viewId) {
    if (_viewId != null && viewId != _viewId) {
      return;
    }
    widget.onFocus?.call();
  }

  void _handleBlur(int viewId) {
    if (_viewId != null && viewId != _viewId) {
      return;
    }
    widget.onBlur?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FluttronHtmlView(
      type: 'milkdown.editor',
      args: <dynamic>[
        <String, dynamic>{
          'initialMarkdown': widget.initialMarkdown,
          'theme': widget.theme.value,
          'readonly': widget.readonly,
        },
      ],
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: widget.errorBuilder,
    );
  }
}
