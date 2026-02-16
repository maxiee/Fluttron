import 'dart:async';

import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

import 'milkdown_events.dart';

class MilkdownEditor extends StatefulWidget {
  const MilkdownEditor({
    super.key,
    this.initialMarkdown = '',
    this.readonly = false,
    this.onChanged,
    this.onReady,
    this.onFocus,
    this.onBlur,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String initialMarkdown;
  final bool readonly;
  final ValueChanged<MilkdownChangeEvent>? onChanged;
  final VoidCallback? onReady;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;
  final WidgetBuilder? loadingBuilder;
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
          'theme': 'frame',
          'readonly': widget.readonly,
        },
      ],
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: widget.errorBuilder,
    );
  }
}
