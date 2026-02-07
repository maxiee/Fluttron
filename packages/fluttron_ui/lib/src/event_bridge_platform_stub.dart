import 'dart:async';

Object createFluttronEventBridgeDelegate() {
  return const _UnsupportedFluttronEventBridgeDelegate();
}

Stream<Map<String, dynamic>> fluttronEventBridgeOn({
  required Object delegate,
  required String eventName,
}) {
  throw UnsupportedError(
    'FluttronEventBridge is only supported on Flutter Web.',
  );
}

void disposeFluttronEventBridgeDelegate(Object delegate) {}

class _UnsupportedFluttronEventBridgeDelegate {
  const _UnsupportedFluttronEventBridgeDelegate();
}
