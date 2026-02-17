# template_service

A custom Fluttron Host service.

## Structure

- `template_service_host/` — Host-side implementation (`FluttronService`)
- `template_service_client/` — UI-side client stub

## Usage

### 1. Register in Host

```dart
import 'package:template_service_host/template_service_host.dart';

void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(TemplateService());

  runFluttronHost(registry: registry);
}
```

### 2. Call from UI

```dart
import 'package:template_service_client/template_service_client.dart';

final client = FluttronClient();
final service = TemplateServiceClient(client);
final greeting = await service.greet(name: 'World');
```

## Development

```bash
# Test host-side
cd template_service_host && flutter test

# Test client-side
cd template_service_client && flutter test
```

## Adding Methods

1. Add method declaration to `fluttron_host_service.json`
2. Implement the method in `template_service_host/lib/src/template_service.dart`
3. Add corresponding method in `template_service_client/lib/src/template_service_client.dart`
4. Add tests to both packages

## Manifest

The `fluttron_host_service.json` file documents the service contract:

- `namespace` — Service namespace for routing
- `methods` — Available methods with parameters and return types
