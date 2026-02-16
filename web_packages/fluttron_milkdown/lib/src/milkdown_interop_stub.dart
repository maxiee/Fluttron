/// Non-web platform stub for Milkdown interop.
///
/// All control operations throw [UnsupportedError] on non-web platforms.
library;

import 'milkdown_interop.dart';

/// Throws [UnsupportedError] - Milkdown control is only available on web.
MilkdownControlResult callMilkdownControlImpl(
  int viewId,
  String action, [
  Map<String, dynamic>? params,
]) {
  throw UnsupportedError(
    'Milkdown control operations are only supported on web platforms. '
    'Attempted to call action "$action" on viewId $viewId.',
  );
}
