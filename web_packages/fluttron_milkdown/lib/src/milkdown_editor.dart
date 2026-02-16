import 'dart:async';

import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

import 'milkdown_controller.dart';
import 'milkdown_events.dart';
import 'milkdown_theme.dart';

int _milkdownEditorInstanceCounter = 0;

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
  late final String _instanceToken = _createInstanceToken();
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
  void didUpdateWidget(covariant MilkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool configChanged =
        oldWidget.initialMarkdown != widget.initialMarkdown ||
        oldWidget.theme != widget.theme ||
        oldWidget.readonly != widget.readonly;
    if (configChanged) {
      _detachController(controller: oldWidget.controller);
      _viewId = null;
    }

    if (oldWidget.controller != widget.controller) {
      _detachController(controller: oldWidget.controller);

      final MilkdownController? nextController = widget.controller;
      final int? viewId = _viewId;
      if (nextController != null &&
          viewId != null &&
          !nextController.isAttached) {
        nextController.attach(viewId);
      }
    }
  }

  @override
  void dispose() {
    _detachController();
    _detachListeners();
    _eventBridge.dispose();
    super.dispose();
  }

  void _attachListeners() {
    _changeSubscription = milkdownEditorChanges(
      instanceToken: _instanceToken,
      eventBridge: _eventBridge,
    ).listen(_handleChange);
    _readySubscription = milkdownEditorReady(
      instanceToken: _instanceToken,
      eventBridge: _eventBridge,
    ).listen(_handleReady);
    _focusSubscription = milkdownEditorFocus(
      instanceToken: _instanceToken,
      eventBridge: _eventBridge,
    ).listen(_handleFocus);
    _blurSubscription = milkdownEditorBlur(
      instanceToken: _instanceToken,
      eventBridge: _eventBridge,
    ).listen(_handleBlur);
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

  void _detachController({MilkdownController? controller}) {
    final MilkdownController? targetController =
        controller ?? widget.controller;
    if (targetController != null && targetController.isAttached) {
      targetController.detach();
    }
  }

  String _createInstanceToken() {
    _milkdownEditorInstanceCounter += 1;
    return 'milkdown-${DateTime.now().microsecondsSinceEpoch}-$_milkdownEditorInstanceCounter';
  }

  void _handleChange(MilkdownChangeEvent event) {
    final int? currentViewId = _viewId;
    if (currentViewId == null || event.viewId != currentViewId) {
      return;
    }
    widget.onChanged?.call(event);
  }

  void _handleReady(int viewId) {
    final int? previousViewId = _viewId;
    if (previousViewId != null && previousViewId != viewId) {
      _detachController();
    }
    _viewId = viewId;

    // Attach controller before invoking onReady callback.
    final MilkdownController? controller = widget.controller;
    if (controller != null && controller.isAttached) {
      controller.detach();
    }
    if (controller != null) {
      controller.attach(viewId);
    }

    widget.onReady?.call();
  }

  void _handleFocus(int viewId) {
    final int? currentViewId = _viewId;
    if (currentViewId == null || viewId != currentViewId) {
      return;
    }
    widget.onFocus?.call();
  }

  void _handleBlur(int viewId) {
    final int? currentViewId = _viewId;
    if (currentViewId == null || viewId != currentViewId) {
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
          'instanceToken': _instanceToken,
        },
      ],
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: widget.errorBuilder,
    );
  }
}
