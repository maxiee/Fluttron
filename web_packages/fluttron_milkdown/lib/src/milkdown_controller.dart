/// Controller for Milkdown editor runtime operations.
///
/// Provides a Dart API to control an attached Milkdown editor instance
/// after it has been created. The controller must be attached to a
/// viewId before calling any methods.
///
/// Example:
/// ```dart
/// final controller = MilkdownController();
///
/// MilkdownEditor(
///   controller: controller,
///   onReady: () {
///     // Controller is now attached and ready to use
///     final content = await controller.getContent();
///   },
/// );
/// ```
library;

import 'milkdown_interop.dart';

/// Controller for Milkdown editor runtime operations.
///
/// This controller provides methods to manipulate an editor instance
/// after creation. It must be attached to a viewId (typically done
/// by [MilkdownEditor] when the editor becomes ready).
class MilkdownController {
  int? _viewId;

  /// Whether this controller is currently attached to an editor.
  bool get isAttached => _viewId != null;

  /// The view ID this controller is attached to.
  ///
  /// Throws [StateError] if not attached.
  int get viewId {
    final int? id = _viewId;
    if (id == null) {
      throw StateError(
        'MilkdownController is not attached to any editor. '
        'Ensure the editor has emitted "ready" before calling control methods.',
      );
    }
    return id;
  }

  /// Attaches this controller to an editor view.
  ///
  /// This method is typically called by [MilkdownEditor] when the
  /// underlying editor becomes ready.
  ///
  /// [viewId] - The editor view identifier.
  void attach(int viewId) {
    _viewId = viewId;
  }

  /// Detaches this controller from its editor.
  ///
  /// After detaching, all method calls will throw [StateError]
  /// until [attach] is called again.
  void detach() {
    _viewId = null;
  }

  void _ensureAttached() {
    if (_viewId == null) {
      throw StateError(
        'MilkdownController is not attached to any editor. '
        'Ensure the editor has emitted "ready" before calling control methods.',
      );
    }
  }

  MilkdownControlResult _call(String action, [Map<String, dynamic>? params]) {
    _ensureAttached();
    return callMilkdownControl(_viewId!, action, params);
  }

  /// Gets the current markdown content.
  ///
  /// Returns the markdown string, or throws [StateError] if the
  /// operation fails.
  Future<String> getContent() async {
    final result = _call('getContent');
    if (!result.ok) {
      throw StateError('Failed to get content: ${result.error}');
    }
    return result.result as String;
  }

  /// Sets the markdown content.
  ///
  /// [content] - The new markdown content to set.
  ///
  /// Throws [StateError] if the operation fails.
  Future<void> setContent(String content) async {
    final result = _call('setContent', {'content': content});
    if (!result.ok) {
      throw StateError('Failed to set content: ${result.error}');
    }
  }

  /// Focuses the editor.
  ///
  /// Throws [StateError] if the operation fails.
  Future<void> focus() async {
    final result = _call('focus');
    if (!result.ok) {
      throw StateError('Failed to focus editor: ${result.error}');
    }
  }

  /// Inserts text at the current cursor position.
  ///
  /// [text] - The text to insert.
  ///
  /// Throws [StateError] if the operation fails.
  Future<void> insertText(String text) async {
    final result = _call('insertText', {'text': text});
    if (!result.ok) {
      throw StateError('Failed to insert text: ${result.error}');
    }
  }

  /// Sets the readonly mode.
  ///
  /// [readonly] - Whether to enable readonly mode.
  ///
  /// Throws [StateError] if the operation fails.
  Future<void> setReadonly(bool readonly) async {
    final result = _call('setReadonly', {'readonly': readonly});
    if (!result.ok) {
      throw StateError('Failed to set readonly: ${result.error}');
    }
  }

  /// Sets the editor theme.
  ///
  /// [theme] - The theme name (e.g., 'frame', 'frame-dark', 'classic',
  /// 'classic-dark', 'nord', 'nord-dark').
  ///
  /// Throws [StateError] if the operation fails.
  Future<void> setTheme(String theme) async {
    final result = _call('setTheme', {'theme': theme});
    if (!result.ok) {
      throw StateError('Failed to set theme: ${result.error}');
    }
  }
}
