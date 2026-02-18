export 'src/ui_app.dart';
export 'src/html_view.dart';
export 'src/event_bridge.dart';
export 'src/web_view_registry.dart';
export 'fluttron/fluttron_client_stub.dart'
    if (dart.library.js_interop) 'fluttron/fluttron_client.dart';

// Built-in service clients (L1)
export 'src/services/file_service_client.dart';
export 'src/services/dialog_service_client.dart';
export 'src/services/clipboard_service_client.dart';
export 'src/services/system_service_client.dart';
export 'src/services/storage_service_client.dart';
export 'src/services/window_service_client.dart';
export 'src/services/logging_service_client.dart';
