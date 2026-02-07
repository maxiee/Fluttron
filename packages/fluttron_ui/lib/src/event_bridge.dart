import 'dart:async';

import 'event_bridge_platform_stub.dart'
    if (dart.library.html) 'event_bridge_platform_web.dart'
    as event_bridge_platform;

/// Bridges browser [CustomEvent.detail] payloads to Dart streams.
class FluttronEventBridge {
  FluttronEventBridge()
    : _delegate = event_bridge_platform.createFluttronEventBridgeDelegate();

  final Object _delegate;
  bool _isDisposed = false;

  /// Subscribes to a browser event name and emits parsed `detail` payloads.
  Stream<Map<String, dynamic>> on(String eventName) {
    if (_isDisposed) {
      throw StateError('FluttronEventBridge is already disposed.');
    }

    final String normalizedEventName = eventName.trim();
    if (normalizedEventName.isEmpty) {
      throw ArgumentError.value(
        eventName,
        'eventName',
        'eventName must not be empty.',
      );
    }

    return event_bridge_platform.fluttronEventBridgeOn(
      delegate: _delegate,
      eventName: normalizedEventName,
    );
  }

  /// Removes all JS listeners and closes all internal stream controllers.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    event_bridge_platform.disposeFluttronEventBridgeDelegate(_delegate);
  }
}
