/// Milkdown interop entry point with conditional imports.
///
/// Provides a platform-agnostic API to call JavaScript control functions
/// from Dart. On web platforms, this delegates to actual JS interop.
/// On non-web platforms, all calls throw UnsupportedError.
library;

import 'milkdown_interop_stub.dart'
    if (dart.library.html) 'milkdown_interop_web.dart'
    as milkdown_interop_platform;

/// Result of a Milkdown control operation.
///
/// Mirrors the JavaScript control channel response format:
/// `{ ok: boolean, result?: any, error?: string }`
class MilkdownControlResult {
  const MilkdownControlResult._({required this.ok, this.result, this.error});

  /// Creates a successful result with optional [result] value.
  factory MilkdownControlResult.success([dynamic result]) {
    return MilkdownControlResult._(ok: true, result: result);
  }

  /// Creates a failed result with the given [error] message.
  factory MilkdownControlResult.failure(String error) {
    return MilkdownControlResult._(ok: false, error: error);
  }

  /// Whether the operation succeeded.
  final bool ok;

  /// The result value if the operation succeeded.
  final dynamic result;

  /// The error message if the operation failed.
  final String? error;

  @override
  String toString() {
    if (ok) {
      return 'MilkdownControlResult.success($result)';
    }
    return 'MilkdownControlResult.failure($error)';
  }
}

/// Calls the JavaScript control channel for Milkdown editor.
///
/// [viewId] - The editor view identifier.
/// [action] - The action to perform (e.g., 'getContent', 'setContent').
/// [params] - Optional parameters for the action.
///
/// Returns a [MilkdownControlResult] indicating success or failure.
MilkdownControlResult callMilkdownControl(
  int viewId,
  String action, [
  Map<String, dynamic>? params,
]) {
  return milkdown_interop_platform.callMilkdownControlImpl(
    viewId,
    action,
    params,
  );
}
