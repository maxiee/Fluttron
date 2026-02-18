import 'package:flutter/widgets.dart';
import 'package:fluttron_host/src/services/service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:window_manager/window_manager.dart';

/// Service for controlling the application window.
///
/// Namespace: `window`
///
/// Methods:
/// - `setTitle(title: String)` — Set the window title
/// - `setSize(width: int, height: int)` — Set the window size
/// - `getSize()` — Get current window size
/// - `minimize()` — Minimize the window
/// - `maximize()` — Toggle maximize/restore the window
/// - `setFullScreen(enabled: bool)` — Toggle fullscreen
/// - `isFullScreen()` — Check fullscreen state
/// - `center()` — Center the window on screen
/// - `setMinSize(width: int, height: int)` — Set minimum window size
class WindowService extends FluttronService {
  @override
  String get namespace => 'window';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'setTitle':
        final title = params['title'];
        if (title is! String) {
          throw FluttronError('BAD_PARAMS', 'window.setTitle: title must be a String');
        }
        await windowManager.setTitle(title);
        return null;

      case 'setSize':
        final width = params['width'];
        final height = params['height'];
        if (width is! num || height is! num) {
          throw FluttronError('BAD_PARAMS', 'window.setSize: width and height must be numbers');
        }
        if (width <= 0 || height <= 0) {
          throw FluttronError('BAD_PARAMS', 'window.setSize: width and height must be positive');
        }
        await windowManager.setSize(Size(width.toDouble(), height.toDouble()));
        return null;

      case 'getSize':
        final size = await windowManager.getSize();
        return <String, dynamic>{
          'width': size.width.toInt(),
          'height': size.height.toInt(),
        };

      case 'minimize':
        await windowManager.minimize();
        return null;

      case 'maximize':
        final isMaximized = await windowManager.isMaximized();
        if (isMaximized) {
          await windowManager.restore();
        } else {
          await windowManager.maximize();
        }
        return null;

      case 'setFullScreen':
        final enabled = params['enabled'];
        if (enabled is! bool) {
          throw FluttronError('BAD_PARAMS', 'window.setFullScreen: enabled must be a bool');
        }
        await windowManager.setFullScreen(enabled);
        return null;

      case 'isFullScreen':
        final result = await windowManager.isFullScreen();
        return <String, dynamic>{'result': result};

      case 'center':
        await windowManager.center();
        return null;

      case 'setMinSize':
        final width = params['width'];
        final height = params['height'];
        if (width is! num || height is! num) {
          throw FluttronError('BAD_PARAMS', 'window.setMinSize: width and height must be numbers');
        }
        if (width <= 0 || height <= 0) {
          throw FluttronError('BAD_PARAMS', 'window.setMinSize: width and height must be positive');
        }
        await windowManager.setMinimumSize(Size(width.toDouble(), height.toDouble()));
        return null;

      default:
        throw FluttronError('METHOD_NOT_FOUND', 'window.$method not implemented');
    }
  }
}
